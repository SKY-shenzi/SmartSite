## SmartSite 智慧工地项目
 
   本仓库包含完整的开源代码与文档，涵盖四大模块：
 - HarmonyOS 移动端 — 现场数据采集与实时监控
 - 嵌入式感知端 — 环境传感器数据采集
 - AI 安全帽检测 — 基于深度学习的施工人员安全帽佩戴识别
 - 项目文档 — 设计说明、部署指南与最终提交材料

   仓库地址：https://github.com/SKY-shenzi/SmartSite
   
## 成果物位置

- `harmony/`: HarmonyOS/ArkTS/ArkUI 移动端工程，来自 DevEco Studio 项目 `MyApplication2` 的整理版。
- `embedded/`: 嵌入式端代码，包含材料区传感器采集、OLED 显示、Wi-Fi、MQTT、风扇/蜂鸣器等控制逻辑。
- `AI端/`: AI 安全帽检测相关代码、模型和训练结果。
- `submission/PROJECT_DOCUMENTATION.md`: 最终提交所需的完整项目文档说明，包含项目简介、功能说明、安装部署指南、使用说明、开发成员及分工、仓库地址。

## HarmonyOS 端说明

HarmonyOS 端位于 `harmony/`，主要功能包括：

- 管理员/工人双角色入口。
- 材料区实时监测与华为云 IoTDA 设备影子接入。
- 水泥区、木材区温湿度、光照、烟雾、风扇、蜂鸣器等状态展示。
- IoTDA 命令下发。
- Supabase 考勤任务、签到、签退和记录查询。
- KingbaseES 历史数据查询与 Canvas 趋势图。
- ThingJS 数字孪生 Web 页面嵌入。
- Dify AI 智慧工地助手。
- HarmonyOS 桌面卡片。

运行前请打开 `harmony/` 目录并在 DevEco Studio 中导入工程。

## 安全说明

公开仓库中的 IoTDA IAM token 和 Dify API key 已脱敏。运行前需要在本地配置真实服务参数，或通过后端代理/环境变量管理密钥。

## 提交记录说明

仓库已保留团队成员提交记录，用于体现协作开发过程。主要提交包括：

- HarmonyOS 端工程整理与推送。
- 嵌入式木材区、水泥区代码提交。
- AI 视频推拉流与 YOLO 检测代码提交。
- 最终项目文档提交。

## 最终提交建议

平台最终提交时建议同时上传：

1. 源码压缩包。
2. 完整项目文档说明。
3. 已加入鸿蒙端内容的项目报告。
4. 本 GitHub 仓库地址：https://github.com/SKY-shenzi/SmartSite
