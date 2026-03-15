# Post-Release Deploy Kit

This folder contains reusable scripts and documentation for post-release deployment.

## Goal

Use these scripts after code updates to ensure:
- Service starts successfully
- Feishu channel is connected and can receive/reply
- Required plugins are loaded
- Required skills are present
- Known startup/plugin errors are not present in logs

## Files

- `00_post_release_menu.bat`: Unified post-release menu (recommended entry)
- `01_publish_only.bat`: Publish deploy runtime only
- `02_restart_only.bat`: Restart service only
- `03_publish_restart_verify.bat`: Publish + restart + verification (recommended)
- `verify_post_release.ps1`: Automated runtime checks
- `DEPLOYMENT_POST_RELEASE.md`: Post-release operations handbook (Chinese)

## Recommended workflow

1. Double-click `00_post_release_menu.bat`
2. Choose option `3` (Publish + Restart + Verify)
3. Confirm terminal shows `[OK] Publish + Restart + Verification passed.`
4. In Feishu, send a test message to the bot and confirm reply

Alternative one-shot workflow:

1. Double-click `03_publish_restart_verify.bat`
2. Confirm terminal shows `[OK] Publish + Restart + Verification passed.`
3. In Feishu, send a test message to the bot and confirm reply

## Manual fallback workflow

1. Run `01_publish_only.bat`
2. Run `02_restart_only.bat`
3. Run verification:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\verify_post_release.ps1
   ```

## Non-interactive mode (for automation)

`00_post_release_menu.bat` also supports command-line arguments:

- `publish` or `1`
- `restart` or `2`
- `release-verify` or `3`
- `verify` or `4`
- `logs` or `5`
- `docs`

Examples:

```powershell
Set-Location "D:\OpenClaw\Develop\openclaw\deploy-post-release"
.\00_post_release_menu.bat release-verify
.\00_post_release_menu.bat verify
```

## What verification checks

- HTTP health check on `http://127.0.0.1:18789`
- `config.runtime.json` required plugin entries and allow-list
- Feishu policy:
  - `enabled=true`
  - `connectionMode=websocket`
  - `dmPolicy=open`
  - `requireMention=false`
  - `allowFrom` contains `*`
- Required skills:
  - `openclaw-aisa-web-search-tavily`
  - `find-skills`
  - `summarize`
  - `xiucheng-self-improving-agent`
- Recent `gateway.log` does not contain:
  - `Cannot find module 'axios'`
  - `feishu failed to load`
  - `failed to load plugin`
  - `plugins.allow is empty`

## Notes

- Default project path: `D:\OpenClaw\Develop\openclaw`
- Default deploy path: `D:\OpenClaw\deploy`
- If your paths differ, edit `verify_post_release.ps1` parameters or pass custom arguments.
- For daily operations, use this folder as the single source of truth.
- Scripts now include preflight checks for missing sibling scripts and key entry files to fail fast with clear messages.
