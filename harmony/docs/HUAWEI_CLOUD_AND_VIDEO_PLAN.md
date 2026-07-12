# 智慧工地华为云与视频流接入说明

## 当前工程接入方式

当前元服务已经预留了“华为云数据通道”：

- 首页点击“同步”会触发模拟云端数据刷新。
- 材料区温湿度、监控状态、告警数量会联动更新。
- 监控卡片已经预留 HLS 视频流播放器。
- 桌面服务卡片保留工地概览数据结构。

真实接入时，把 `Index.ets` 中的 `refreshFromHuaweiCloudMock()` 替换为真实云端数据请求即可。

当前已填入你的 IoTDA 基础信息：

| 项目 | 值 |
| --- | --- |
| 区域 | `cn-north-4` |
| IoTDA 应用侧 Endpoint | `https://b349431dee.st1.iotda-app.cn-north-4.myhuaweicloud.com:443` |
| IoTDA 实例名称 | `freeStandardInstance` |
| IoTDA 实例 ID | `97ea8a7a-5cdb-4b0d-a4ae-3285825e26e8` |
| 项目 ID | `0e7c5e04a662439c813433f94d7ad4e7` |
| 资源空间 | `大二下实训` / `f7671bc74b254ad2bdfe9417fe9919a9` |
| 产品名称 | `SmartDevice` |
| 产品 ID | `6a3a6e8e7f2e6c302f7e2b06` |
| 设备标识码 | `GongDone` |
| 设备 ID | `6a3a6e8e7f2e6c302f7e2b06_GongDone` |
| 服务 ID | `smartdevice` |
| 温度字段 | `Temp` |
| 湿度字段 | `Humi` |

工程配置位置：

```text
entry/src/main/ets/common/IotdaConfig.ets
```

临时演示直连 IoTDA 时，把 API Explorer 生成的短期 Token 填到：

```ts
demoIamToken: '<X-Subject-Token>'
```

注意：这个字段只用于课堂演示，Token 过期或演示结束后应清空。

## 推荐华为云传输机制

推荐结构：

1. 温湿度传感器、考勤设备、监控平台把数据上报到华为云。
2. 华为云 IoTDA 或后端服务统一接收设备数据。
3. 后端通过 API Gateway 或 FunctionGraph 暴露 HTTPS 接口。
4. 鸿蒙元服务通过 HTTPS 拉取聚合后的工地数据。
5. 桌面服务卡片按固定周期刷新关键指标。

不建议把 AK/SK、IoTDA 密钥直接写进端侧代码。真实项目里应该由后端代签名、鉴权和聚合数据。

## IoTDA 应用侧接口规划

IoTDA 应用侧 REST API 当前使用老师示例中的应用侧接入地址：

- `endpoint`：`https://b349431dee.st1.iotda-app.cn-north-4.myhuaweicloud.com:443`
- `project_id`：华为云项目 ID，不是产品 ID
- `X-Auth-Token`：IAM Token
- 应用侧地址不再额外携带 `Instance-Id` 请求头

根据产品 ID 查询设备列表：

```http
GET /v5/iot/0e7c5e04a662439c813433f94d7ad4e7/devices?product_id=6a3a6e8e7f2e6c302f7e2b06
Host: b349431dee.st1.iotda-app.cn-north-4.myhuaweicloud.com
X-Auth-Token: <IAM_TOKEN>
```

查询某台设备影子：

```http
GET /v5/iot/0e7c5e04a662439c813433f94d7ad4e7/devices/6a3a6e8e7f2e6c302f7e2b06_GongDone/shadow
Host: b349431dee.st1.iotda-app.cn-north-4.myhuaweicloud.com
X-Auth-Token: <IAM_TOKEN>
```

## 课堂演示获取短期 Token

1. 打开华为云 API Explorer 的 IAM 接口“获取用户Token”。
2. 使用你的华为云账号完成调试请求。
3. 在响应头里复制 `X-Subject-Token`。
4. 填入 `entry/src/main/ets/common/IotdaConfig.ets` 的 `demoIamToken`。
5. 重新运行/打包元服务，管理员首页点击“同步”。

设备影子适合读取最近一次属性值，例如材料区温度、湿度、设备在线状态。你的智慧工地页面可以把影子属性映射到：

- 材料区温度
- 材料区湿度
- 在线/离线状态
- 告警状态
- 最近更新时间

## 需要你提供的信息

华为云数据部分还需要：

- 你的数据是在“设备影子”里，还是通过“消息跟踪/数据转发”到了其他服务。
- 是否已经有后端接口。如果没有，建议不要在端侧直连 IoTDA Token，最好做一个轻量后端代理。

## 端侧直连与后端代理的取舍

端侧直连 IoTDA：

- 优点：课程演示快。
- 缺点：需要把 IAM Token 或临时 Token 放到端侧，不适合真实生产。

后端代理：

- 优点：安全，端侧只拿业务数据，不暴露云密钥。
- 缺点：需要多写一个服务。

建议最终方案：

```text
HarmonyOS 元服务 -> 你的后端接口 -> 华为云 IoTDA
```

课程/答辩演示可以先：

```text
HarmonyOS 元服务 -> IoTDA 应用侧 API
```

但 Token 只作为临时测试使用，不写入公开代码。

视频流部分：

- 摄像头原始地址，通常是 RTSP，例如 `rtsp://user:password@ip:554/stream1`。
- 是否允许本机或服务器长期运行 FFmpeg 转流。
- 目标播放方式：HLS、HTTP-FLV、WebRTC。当前元服务优先按 HLS 规划。
- HLS 服务地址，例如 `http://服务器IP:8080/hls/material.m3u8`。

## FFmpeg 转 HLS 示例

把 RTSP 摄像头转成 HLS：

```powershell
ffmpeg -rtsp_transport tcp -i "rtsp://user:password@camera-ip:554/stream1" `
  -c:v copy -c:a aac -f hls `
  -hls_time 2 -hls_list_size 5 -hls_flags delete_segments `
  "C:\smart-site-video\hls\material.m3u8"
```

然后用一个静态 HTTP 服务暴露目录：

```powershell
python -m http.server 8080 --directory "C:\smart-site-video"
```

元服务中的视频地址配置为：

```text
http://电脑或服务器IP:8080/hls/material.m3u8
```

注意：真机不能访问电脑自己的 `127.0.0.1`，需要换成电脑局域网 IP 或云服务器公网/内网地址。

## 后续替换点

当前代码中的模拟数据函数：

```text
entry/src/main/ets/pages/Index.ets -> refreshFromHuaweiCloudMock()
```

真实接入后建议改为：

```text
refreshFromHuaweiCloud()
```

并从云端接口返回：

- overview：在场人数、监控在线数、告警数量。
- environments：材料区温度、湿度、负责人、状态。
- monitors：摄像头名称、区域、在线状态、告警、HLS 地址。
- attendance：打卡任务状态、签到记录、工时统计。
