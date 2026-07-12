# SmartSite

智慧工地 HarmonyOS 端与配套服务代码。项目包含 HarmonyOS/ArkTS 移动端、桌面卡片、IoTDA 数据接入、Supabase 考勤、KingbaseES 材料历史数据、Dify AI 助手、ThingJS 数字孪生和视频流展示等模块。

## 代码说明

- `entry/src/main/ets/pages/Index.ets`: HarmonyOS 主页面，包含管理员看板、材料区、视频监控、考勤、工时、工人端和 AI 助手。
- `entry/src/main/ets/common`: IoTDA、Supabase、KingbaseES API、Dify 等配置入口。推送版本已移除真实 token/API key，请在本地按需填写。
- `entry/src/main/ets/entryformability` 与 `entry/src/main/ets/widget`: 桌面卡片能力。
- `server/iotda-proxy`: IoTDA 代理服务示例。
- `docs`: 项目方案、数据库 SQL、技术报告素材。

## 安全说明

仓库中的 IoTDA `demoIamToken` 和 Dify `apiKey` 已替换为空字符串，避免公开泄露凭据。运行前请在本地配置真实服务地址和密钥，或改用环境变量/后端代理管理密钥。
