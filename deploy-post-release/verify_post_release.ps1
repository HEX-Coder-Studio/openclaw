param(
  [string]$ProjectDir = "D:\OpenClaw\Develop\openclaw",
  [string]$DeployDir = "D:\OpenClaw\deploy",
  [int]$Port = 18789
)

$ErrorActionPreference = "Stop"

function Pass([string]$msg) { Write-Host "[PASS] $msg" -ForegroundColor Green }
function Fail([string]$msg) { Write-Host "[FAIL] $msg" -ForegroundColor Red }
function Info([string]$msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }

$failed = @()

function Assert-True([bool]$condition, [string]$successMsg, [string]$failMsg) {
  if ($condition) {
    Pass $successMsg
  } else {
    Fail $failMsg
    $script:failed += $failMsg
  }
}

$runtimeConfig = Join-Path $DeployDir "config.runtime.json"
$gatewayLog = Join-Path $DeployDir "gateway.log"
$runtimePackageDir = Join-Path $DeployDir "openclaw-runtime-next\package"
$skillsDir = Join-Path $DeployDir "openclaw-runtime-next\package\skills"

Info "Loading runtime config..."
Assert-True (Test-Path $runtimeConfig) "Runtime config exists" "Runtime config missing: $runtimeConfig"
if (-not (Test-Path $runtimeConfig)) { exit 1 }

$cfg = Get-Content $runtimeConfig -Raw | ConvertFrom-Json

Info "Checking HTTP health endpoint..."
try {
  $status = (Invoke-WebRequest -Uri ("http://127.0.0.1:{0}" -f $Port) -UseBasicParsing -TimeoutSec 10).StatusCode
  Assert-True ($status -eq 200) "HTTP health check returned 200" "HTTP health check failed (status=$status)"
} catch {
  Fail "HTTP health check failed: $($_.Exception.Message)"
  $failed += "HTTP health check failed"
}

Info "Checking sustained HTTP health (60s)..."
$sustainOk = $true
for ($i = 1; $i -le 12; $i++) {
  try {
    $s = (Invoke-WebRequest -Uri ("http://127.0.0.1:{0}" -f $Port) -UseBasicParsing -TimeoutSec 8).StatusCode
    if ($s -ne 200) {
      $sustainOk = $false
      break
    }
  } catch {
    $sustainOk = $false
    break
  }
  Start-Sleep -Seconds 5
}
Assert-True $sustainOk "Sustained HTTP health passed (60s)" "Sustained HTTP health failed within 60s"

Info "Checking gateway process liveness..."
$gatewayProc = Get-CimInstance Win32_Process -Filter "Name='node.exe'" | Where-Object { $_.CommandLine -match 'openclaw\.mjs\s+gateway\s+run' }
Assert-True ($null -ne $gatewayProc) "Gateway node process exists" "Gateway node process not found"

Info "Checking required plugin entries..."
$requiredEntries = @("feishu", "qwen-portal-auth", "abb-robot-control")
foreach ($id in $requiredEntries) {
  $exists = $cfg.plugins -and $cfg.plugins.entries -and ($cfg.plugins.entries.PSObject.Properties.Name -contains $id)
  $enabled = $false
  if ($exists) {
    $enabled = [bool]$cfg.plugins.entries.$id.enabled
  }
  Assert-True ($exists -and $enabled) "Plugin entry '$id' enabled" "Plugin entry '$id' missing or disabled"
}

Info "Checking trusted plugin allow-list..."
$requiredAllow = @("feishu", "qwen-portal-auth", "abb-robot-control", "robot-kinematic")
$allowList = @()
if ($cfg.plugins -and $cfg.plugins.allow) {
  $allowList = @($cfg.plugins.allow)
}
foreach ($id in $requiredAllow) {
  Assert-True ($allowList -contains $id) "plugins.allow contains '$id'" "plugins.allow missing '$id'"
}

Info "Checking Feishu channel runtime policy..."
$feishu = $cfg.channels.feishu
Assert-True ($null -ne $feishu) "Feishu channel config exists" "Feishu channel config missing"
if ($null -ne $feishu) {
  Assert-True ([bool]$feishu.enabled) "Feishu enabled=true" "Feishu enabled is false"
  Assert-True ($feishu.connectionMode -eq "websocket") "Feishu connectionMode=websocket" "Feishu connectionMode is not websocket"
  Assert-True ($feishu.dmPolicy -eq "open") "Feishu dmPolicy=open" "Feishu dmPolicy is not open"
  Assert-True ($feishu.requireMention -eq $false) "Feishu requireMention=false" "Feishu requireMention is not false"
  $allowFrom = @($feishu.allowFrom)
  Assert-True ($allowFrom -contains "*") "Feishu allowFrom contains '*'" "Feishu allowFrom missing '*'"
}

Info "Checking Feishu runtime assets/dependencies..."
$feishuPluginDir = Join-Path $runtimePackageDir "extensions\feishu"
Assert-True (Test-Path $feishuPluginDir) "Feishu plugin directory exists" "Feishu plugin directory missing: $feishuPluginDir"

$axiosRoot = Join-Path $runtimePackageDir "node_modules\axios"
$axiosFeishuLocal = Join-Path $runtimePackageDir "extensions\feishu\node_modules\axios"
Assert-True ((Test-Path $axiosRoot) -or (Test-Path $axiosFeishuLocal)) "Runtime dependency present: axios" ("Runtime dependency missing: axios ({0} or {1})" -f $axiosRoot, $axiosFeishuLocal)

$runtimeDeps = @(
  @{ Name = "yaml/index.js"; Path = (Join-Path $runtimePackageDir "node_modules\yaml\index.js") },
  @{ Name = "@line/bot-sdk/index.js"; Path = (Join-Path $runtimePackageDir "node_modules\@line\bot-sdk\index.js") },
  @{ Name = "@larksuiteoapi/node-sdk"; Path = (Join-Path $runtimePackageDir "node_modules\@larksuiteoapi\node-sdk") }
)
foreach ($dep in $runtimeDeps) {
  Assert-True (Test-Path $dep.Path) ("Runtime dependency present: {0}" -f $dep.Name) ("Runtime dependency missing: {0} ({1})" -f $dep.Name, $dep.Path)
}

Info "Checking required skills..."
$requiredSkills = @(
  "openclaw-aisa-web-search-tavily",
  "find-skills",
  "summarize",
  "xiucheng-self-improving-agent"
)
foreach ($slug in $requiredSkills) {
  $path = Join-Path $skillsDir $slug
  Assert-True (Test-Path $path) "Skill '$slug' exists" "Skill '$slug' missing: $path"
}

Info "Scanning recent gateway log for known fatal/plugin errors..."
if (Test-Path $gatewayLog) {
  $tail = Get-Content $gatewayLog -Tail 300
  $patterns = @(
    "Cannot find module 'axios'",
    "Cannot find package",
    "missing dist/entry.",
    "too many arguments for 'gateway'",
    "too many arguments for 'run'",
    "feishu failed to load",
    "failed to load plugin",
    "plugins.allow is empty"
  )
  foreach ($p in $patterns) {
    $hit = $tail | Select-String -SimpleMatch $p
    Assert-True (-not $hit) "No '$p' in recent log" "Found '$p' in recent log"
  }
} else {
  Fail "Gateway log missing: $gatewayLog"
  $failed += "Gateway log missing"
}

if ($failed.Count -gt 0) {
  Write-Host ""
  Fail ("Post-release verification failed ({0} issue(s))." -f $failed.Count)
  $failed | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
  exit 1
}

Write-Host ""
Pass "Post-release verification passed."
exit 0
