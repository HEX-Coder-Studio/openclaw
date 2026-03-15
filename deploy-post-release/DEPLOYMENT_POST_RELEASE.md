# OpenClaw 发布后部署与验收手册

本手册与批处理脚本统一放在 `deploy-post-release` 目录下，作为发布后操作的唯一入口。

## 1. 目录内容

- `00_post_release_menu.bat`：发布后总入口菜单（推荐）
- `01_publish_only.bat`：只发布
- `02_restart_only.bat`：只重启
- `03_publish_restart_verify.bat`：发布 + 重启 + 验证（推荐）
- `verify_post_release.ps1`：自动验收脚本

## 2. 推荐流程

```powershell
Set-Location "D:\OpenClaw\Develop\openclaw\deploy-post-release"
.\00_post_release_menu.bat
```

菜单中优先选择：`3`（Publish + Restart + Verify）。

无交互命令：

```powershell
Set-Location "D:\OpenClaw\Develop\openclaw\deploy-post-release"
.\03_publish_restart_verify.bat
```

也可直接使用总入口的参数模式：

```powershell
Set-Location "D:\OpenClaw\Develop\openclaw\deploy-post-release"
.\00_post_release_menu.bat release-verify
.\00_post_release_menu.bat verify
```

参数映射：

- `publish` 或 `1`
- `restart` 或 `2`
- `release-verify` 或 `3`
- `verify` 或 `4`
- `logs` 或 `5`
- `docs`

## 3. 验证项说明

`verify_post_release.ps1` 会检查：

- 网关健康状态（默认 `http://127.0.0.1:18789`）
- `config.runtime.json` 的插件配置与 `plugins.allow`
- Feishu 通道策略：
  - `enabled=true`
  - `connectionMode=websocket`
  - `dmPolicy=open`
  - `requireMention=false`
  - `allowFrom` 包含 `*`
- 关键 skills 是否存在
- `gateway.log` 是否出现关键错误模式（axios 缺失、插件加载失败等）

## 4. 常见问题

### 4.1 飞书能发测试消息但不回复

优先检查 Feishu 策略与 pairing 状态，再重跑：

```powershell
.\03_publish_restart_verify.bat
```

### 4.2 发布后插件报 axios 缺失

说明运行时依赖未恢复完整，直接执行推荐闭环流程即可。

### 4.3 批处理中断或卡住

先终止当前挂起窗口，再从 `00_post_release_menu.bat` 重新执行。

## 5. 与主菜单关系

- 项目根目录 `deploy_menu.bat` 提供全量部署能力。
- `deploy-post-release` 目录专注发布后动作，便于运维与归档。
- 建议发布后固定使用本目录脚本，减少遗漏。

## 6. 稳定性增强说明

本目录脚本已补充 fail-fast 前置检查：

- 缺失关键脚本时立即报错并退出，不再静默继续。
- `01/02` 会检查 `deploy_menu.bat` 是否存在，并校验项目目录可进入。
- `03` 会校验 `01/02/verify` 三个依赖脚本存在后再执行。
