# 智慧工地 SmartSite 项目文档说明

## 1. 项目简介

本项目为“智慧工地：现场安全与材料环境管理系统”的 HarmonyOS 端与配套服务实现。系统面向施工现场安全监管、材料存储环境监测、考勤管理、视频监控、数字孪生展示和 AI 辅助问答等场景，使用 HarmonyOS/ArkTS/ArkUI 构建移动端主入口，并接入华为云 IoTDA、Supabase、KingbaseES、Dify、ThingJS 和视频流服务。

开源仓库完整地址：

https://github.com/SKY-shenzi/SmartSite

HarmonyOS 端代码目录：

```text
SmartSite/harmony
```

## 2. 功能说明

1. HarmonyOS 移动端主界面
   - 使用 DevEco Studio、ArkTS、ArkUI 开发。
   - 支持管理员和工人两类角色入口。
   - 包含登录页、管理员首页、材料环境页、视频监控页、考勤页、工时页、工人打卡页和 AI 助手页。

2. 材料区实时监测
   - 接入华为云 IoTDA 设备影子接口。
   - 支持水泥区、木材区温度、湿度、光照、烟雾、距离、风扇、蜂鸣器等状态展示。
   - 支持风扇等执行器的远程命令下发。

3. 考勤与工时管理
   - 接入 Supabase REST API。
   - 管理员可发布、关闭和重置考勤任务。
   - 工人端可签到、签退，并实时显示工时。

4. 材料历史数据与趋势图
   - 接入 KingbaseES 中间层服务。
   - 查询材料区历史传感器记录。
   - 使用 Canvas 绘制温湿度趋势图。

5. 视频监控与安全帽检测展示
   - 接入 MediaMTX/HLS 视频流。
   - 在 HarmonyOS 端通过 Web 组件展示云端视频监控页面。
   - 支持与 AI 安全帽检测结果联动展示。

6. 数字孪生展示
   - 通过 Web 组件嵌入 ThingJS 数字孪生页面。
   - 展示材料区、资产状态、传感器摘要和告警信息。

7. AI 智慧工地助手
   - 接入 Dify Chat API。
   - 支持工地安全、材料环境、考勤和运维问题问答。

8. HarmonyOS 桌面卡片
   - 使用 FormExtensionAbility 和 WidgetCard 实现桌面卡片。
   - 展示温湿度、在线监控、工人数、告警数和刷新时间。

## 3. 安装部署指南

### 3.1 开发环境

- DevEco Studio
- HarmonyOS SDK
- Node.js（用于 IoTDA 代理服务）
- Git

### 3.2 获取代码

```bash
git clone https://github.com/SKY-shenzi/SmartSite.git
cd SmartSite/harmony
```

### 3.3 导入 HarmonyOS 工程

1. 打开 DevEco Studio。
2. 选择 `Open Project`。
3. 打开仓库中的 `harmony` 目录。
4. 等待依赖同步和 Hvigor 配置加载。
5. 连接 HarmonyOS 真机或模拟器。
6. 选择 `entry` 模块运行。

### 3.4 配置服务参数

推送到开源仓库的版本已经移除真实密钥。运行前需要在本地配置以下文件：

```text
harmony/entry/src/main/ets/common/IotdaConfig.ets
harmony/entry/src/main/ets/common/DifyConfig.ets
harmony/entry/src/main/ets/common/SupabaseConfig.ets
harmony/entry/src/main/ets/common/MaterialDatabaseConfig.ets
```

需要配置的主要内容包括：

- 华为云 IoTDA endpoint、projectId、deviceId、serviceId、IAM token 或代理地址。
- Supabase projectUrl 和 publishableKey。
- KingbaseES 中间层 API 地址。
- Dify Chat API 地址和 API key。

### 3.5 IoTDA 代理服务

如果不希望在 App 端直接放置 IAM token，可使用仓库中的代理服务：

```bash
cd harmony/server/iotda-proxy
npm install
node server.js
```

然后在 `IotdaConfig.ets` 中配置代理服务地址。

## 4. 使用说明

1. 启动 HarmonyOS App 后进入登录页。
2. 选择 `管理` 或 `工人` 角色。
3. 管理员端可查看工地看板、材料区实时数据、视频监控、考勤管理、工时统计和 AI 助手。
4. 工人端可查看今日任务并完成签到、签退。
5. 点击材料区卡片可查看历史趋势图和数字孪生页面。
6. 点击 AI 浮动按钮可进入智慧工地助手，输入自然语言问题进行查询。
7. 将桌面卡片添加到系统桌面后，可快速查看工地摘要数据。

## 5. 开发成员及分工

| 成员 | 学号 | 主要分工 |
| --- | --- | --- |
| 沈子奡 | 20245822 | HarmonyOS 端工程整合、移动端页面、云端接口联调、项目文档整理 |
| 季圣喆 | 20245943 | 嵌入式感知端、材料区设备数据采集与上报 |
| 刘维健 | 20246114 | 华为云 IoTDA 接入、设备影子与命令下发联调 |
| 马伯源 | 20246024 | AI 安全帽检测、视频推流与安全监控模块 |
| 殷子淇 | 20246026 | 数据库、数字孪生、资料整理与测试辅助 |

## 6. 目录结构说明

```text
harmony/
  AppScope/                         应用级配置与资源
  entry/                            HarmonyOS entry 模块
    src/main/ets/pages/Index.ets    主页面与业务逻辑
    src/main/ets/common/            云服务与接口配置
    src/main/ets/entryability/      UIAbility 入口
    src/main/ets/entryformability/  桌面卡片 FormExtensionAbility
    src/main/ets/widget/            桌面卡片页面
    src/main/resources/             页面、媒体、卡片配置资源
  server/iotda-proxy/               IoTDA 代理服务
  docs/                             项目方案、SQL、截图和报告素材
  tools/                            报告生成和检查脚本
```

## 7. 提交与代码仓库说明

- 开源仓库地址：https://github.com/SKY-shenzi/SmartSite
- HarmonyOS 端所在目录：`harmony/`
- 主要提交：
  - `46a2bdd Add HarmonyOS smart site app`
  - `d7a0fd5 Move HarmonyOS app into harmony folder`

## 8. 注意事项

1. 开源仓库中的 IAM token 和 Dify API key 已脱敏，不能直接用于生产环境。
2. `oh_modules`、`build`、`.hvigor`、`.idea`、HAP 包等构建产物未提交到仓库。
3. 如果需要重新打包源码，应以仓库中的 `harmony` 目录为准。
4. 最终提交的源码压缩包内容应与开源仓库 `harmony` 目录保持一致，避免版本差异。
