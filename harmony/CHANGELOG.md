# 更改说明

## 2026-07-12

- 新增智慧工地 HarmonyOS 端完整工程代码，基于 DevEco Studio、ArkTS 与 ArkUI 实现。
- 实现管理员/工人双角色入口、像素风登录页、底部导航、管理员看板、工人打卡和 AI 浮动入口。
- 接入华为云 IoTDA 设备影子，支持水泥区与木材区温湿度、光照、烟雾、风扇、蜂鸣器等状态展示。
- 增加 IoTDA 命令下发能力，可在 App 端控制材料区风扇等执行器。
- 接入 Supabase REST API，支持考勤任务发布、关闭、签到、签退和记录查询。
- 接入 KingbaseES 中间层，支持材料区历史传感器数据查询，并使用 Canvas 绘制温湿度趋势图。
- 通过 Web 组件集成 ThingJS 数字孪生页面和 HLS 视频流页面。
- 集成 Dify Chat API，提供智慧工地 AI 助手问答页面。
- 增加 HarmonyOS 桌面卡片 FormExtensionAbility 与 WidgetCard，展示工地温湿度、监控、工人和告警摘要。
- 附带 IoTDA 代理服务、数据库 SQL、项目方案和报告截图素材。
- 出于安全考虑，推送版本已移除 IoTDA IAM token 和 Dify API key，需部署时本地补充。
