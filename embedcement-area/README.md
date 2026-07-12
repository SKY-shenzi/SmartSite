#  水泥区环境监测与联动控制系统

## 项目简介

本项目基于 WS63 LiteOS 工程实现水泥区环境监测与联动控制。系统通过 DHT11 采集温湿度，通过 OLED 显示现场数据，通过 WiFi 连接网络并使用 MQTT 接入华为云 IoTDA；当温度或湿度超过阈值时，自动控制风扇和蜂鸣器，也支持云端下发命令进行手动控制和阈值调整。

## 功能说明

- 温湿度采集：周期读取 DHT11 温湿度数据。
- 本地显示：OLED 显示温度、湿度、风扇状态、报警状态和控制模式。
- 自动控制：温度达到 `tempFanOn` 时开启风扇，降到 `tempFanOff` 时关闭风扇；湿度达到 `humiAlarmOn` 时开启蜂鸣器，降到 `humiAlarmOff` 时关闭蜂鸣器。
- 云端通信：通过 MQTT 上报 `cement_zone` 服务属性，并订阅云端命令。
- 远程控制：支持 `SetMode`、`SetFan`、`ClearAlarm`、`SetThreshold` 命令。

## 目录结构

```text
26_cement_area/
├── app_main.c              # 应用入口、采集任务和自动控制逻辑
├── app_main.h              # WiFi、MQTT、IoTDA 参数配置
├── CMakeLists.txt          # 构建文件
├── Kconfig                 # menuconfig 参数
├── beep/                   # 蜂鸣器驱动
├── dht11/                  # 温湿度传感器驱动
├── fan/                    # 风扇和 PWM 驱动
├── mqtt/                   # MQTT 连接、发布、订阅和命令解析
├── oled/                   # OLED 显示驱动
└── wifi/                   # WiFi STA 连接
```

## 安装与部署

1. 将 `26_cement_area` 放到 SDK 的 `src/application/samples/wanglian/` 目录下。
2. 确认 `src/application/samples/wanglian/CMakeLists.txt` 中包含：

```cmake
if(DEFINED CONFIG_ENABLE_CEMENT_AREA)
add_subdirectory_if_exist(26_cement_area)
endif()
```

3. 确认 `src/application/samples/wanglian/Kconfig` 中包含 `ENABLE_CEMENT_AREA` 选项，并引用：

```text
osource "application/samples/wanglian/26_cement_area/Kconfig"
```

4. 在 `app_main.h` 中填写实际参数：

```c
#define SERVER_IP_ADDR          "YOUR_IOTDA_MQTT_HOST"
#define CLIENT_ID               "YOUR_CLIENT_ID"
#define DEVICEID                "YOUR_DEVICE_ID"
#define CLIENTPASSWORD          "YOUR_DEVICE_PASSWORD"
#define CONFIG_WIFI_SSID        "YOUR_WIFI_SSID"
#define CONFIG_WIFI_PWD         "YOUR_WIFI_PASSWORD"
```

5. 在 menuconfig 中启用：

```text
CONFIG_SAMPLE_ENABLE=y
CONFIG_WANGLIAN_SAMPLE=y
CONFIG_ENABLE_CEMENT_AREA=y
```

6. 使用 HiSpark Studio 或 SDK 构建脚本编译 `ws63_liteos_app`，编译成功后烧录生成的固件。

## 使用说明

烧录后设备会自动连接配置的 WiFi，并连接 IoTDA MQTT 服务。串口会输出温湿度、风扇状态、报警状态和联网日志，OLED 会同步显示现场状态。云端产品模型建议配置服务 ID 为 `cement_zone`，属性包括 `Temp`、`Humi`、`FanSt`、`AlarmSt`、`Mode`、`tempFanOn`、`tempFanOff`、`humiAlarmOn`、`humiAlarmOff`。

## 云端命令

| 命令 | 参数 | 功能 |
| --- | --- | --- |
| `SetMode` | `AUTO` / `MANUAL` | 切换自动或手动模式 |
| `SetFan` | `ON` / `OFF` | 控制风扇开关 |
| `ClearAlarm` | 无 | 关闭蜂鸣器报警 |
| `SetThreshold` | `tempFanOn`、`tempFanOff`、`humiAlarmOn`、`humiAlarmOff` | 修改自动控制阈值 |

## 开发成员及分工

| 成员 | 分工 |
| --- | --- |
| 组员 1 | DHT11 数据采集、OLED 显示 |
| 组员 2 | 风扇、蜂鸣器与阈值控制 |
| 组员 3 | WiFi/MQTT 接入、云端命令处理 |
| 组员 4 | 工程集成、文档整理、测试 |

## 开源仓库地址

请在提交前补充小组实际仓库地址：

```text
https://gitee.com/your-team/your-repository
```

## 验证记录

- `26_cement_area` 已接入 `wanglian` 样例工程的 CMake 和 Kconfig。
- 原工程 `build.log` 显示 `Build target:ws63_liteos_app success` 和 `packet success`。
- 公开提交前已将 WiFi 密码和 IoTDA 设备密钥改为占位值，避免泄露个人配置。

