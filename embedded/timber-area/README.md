# 智慧工地 - 木材区嵌入式端监控系统

## 项目简介

> 📌 本模块属于 [SmartSite 智慧工地管理系统](https://github.com/SKY-shenzi/SmartSite) 的**木材区嵌入式终端**子系统。

本项目是**智慧工地管理系统**中**木材区**的嵌入式终端设备程序，基于**海思 WS63（Hi3861V100）**物联网芯片平台开发。设备通过各类传感器实时采集木材堆放区域的环境数据，利用 WiFi+MOTT 协议连接**华为云 IoT 平台**，实现远程环境监控、设备控制与语音交互功能。

### 应用场景

- 木材堆放区温湿度监测，防止木材受潮变形
- 光照强度检测，避免木材长期暴晒开裂
- CO2/TVOC/甲醛浓度监测，保障作业人员健康
- 烟雾浓度检测，实现火灾预警
- 超声波距离检测，监控木材堆叠安全距离
- 语音控制与远程云平台双向控制

## 功能说明

### 传感器数据采集

| 传感器 | 型号 | 接口类型 | 采集数据 | 用途 |
|--------|------|----------|----------|------|
| 温湿度传感器 | DHT11 | GPIO (单总线) | 温度(℃)、湿度(%RH) | 木材区环境温湿度监控 |
| 光照传感器 | LDR 光敏电阻 | ADC (通道5) | 光照强度(0-100%) | 光照监控 |
| 超声波测距 | HC-SR04 | GPIO (Trig+Echo) | 距离(mm) | 木材堆叠安全距离 |
| 烟雾传感器 | MQ-2 | ADC (通道0) | 烟雾浓度(0-100%) | 火灾预警 |
| 空气质量传感器 | JW01/TVOC-301 | UART1 (9600bps) | TVOC、甲醛、eCO2 | 空气质量监测 |
| 语音识别模块 | SU-03T | UART2 (115200bps) | 语音指令 | 语音控制交互 |

### 执行器控制

| 设备 | 驱动方式 | 控制引脚 |
|------|----------|----------|
| LED 警示灯 x2 | GPIO 高低电平 | GPIO_02, GPIO_03 |
| 散热风扇 | TB6612 PWM 电机驱动 | AIN1/GPIO_10, AIN2/GPIO_11, PWMA/GPIO_01 |
| 有源蜂鸣器 | GPIO 高低电平 | GPIO_00 |

### 数据显示

- **OLED 显示屏** (SSD1306, I2C 接口, 128x64)：实时显示温度、湿度、光照、距离、烟雾浓度

### 通信与云平台

- **WiFi 连接**：2.4GHz WiFi STA 模式，支持自动扫描与关联
- **MQTT 协议**：连接华为云 IoTDA（IoT Device Access），实现设备属性上报与云端命令下发
- **数据上报 JSON 格式**：包含 Temperature、Humidity、Luminance、Distance、LampState、FanState、Smoke、CO2、BuzzerState
- **云端命令支持**：远程控制灯光、风扇、蜂鸣器、控制模式切换、灯光亮度调节

### 语音控制

- 支持语音指令：打开/关闭灯、打开/关闭风扇、打开/关闭蜂鸣器
- 支持语音查询：当前温度、湿度、距离、CO2 浓度、烟雾浓度
- UART 串口通信，自定义 14 字节协议帧

### 软件架构

```
┌────────────────────────────────────────────────────┐
│                   app_main (主任务)                  │
│  ├── gpio_init()          GPIO 初始化               │
│  ├── environment_sensor_init()  传感器初始化         │
│  └── wifi_connect()       WiFi 连接                │
├────────────────────────────────────────────────────┤
│  环境采集任务 (environment_task)                     │
│  ├── DHT11 温湿度采集 (1次/100ms)                   │
│  ├── LDR 光照采集         │                         │
│  ├── HC-SR04 距离采集     │                         │
│  ├── MQ2 烟雾采集         │                         │
│  ├── CO2/TVOC 采集        │                         │
│  └── OLED 显示更新        │                         │
├────────────────────────────────────────────────────┤
│  MQTT 通信任务 (mqtt_init_task)                      │
│  ├── 连接华为云 IoTDA                               │
│  ├── 订阅云端命令主题                               │
│  ├── 定时上报传感器数据 (JSON)                       │
│  └── 处理云端下发命令                               │
├────────────────────────────────────────────────────┤
│  语音控制任务 (uart_voice_task)                      │
│  ├── UART2 轮询接收语音模块数据                      │
│  ├── 语音指令解析                                   │
│  └── 设备控制执行                                   │
└────────────────────────────────────────────────────┘
```

## 目录结构

```
21_huaweiiot/
├── app_main.c              # 主程序入口，任务创建与调度
├── app_main.h              # 全局配置文件（WiFi/MQTT/认证信息）
├── CMakeLists.txt          # CMake 构建配置
├── Kconfig                 # 内核配置选项（ADC通道配置）
├── adc/
│   ├── ldr.c               # 光照传感器 ADC 驱动
│   └── ldr.h               # 光照传感器头文件
├── beep/
│   ├── beep.c              # 有源蜂鸣器 GPIO 驱动
│   └── beep.h              # 蜂鸣器头文件
├── co2/
│   ├── co2.c               # JW01 CO2/TVOC/甲醛传感器驱动 (硬件UART+软件UART双模式)
│   └── co2.h               # CO2 传感器头文件
├── dht11/
│   ├── dht11.c             # DHT11 温湿度传感器驱动 (单总线协议)
│   └── dht11.h             # DHT11 头文件
├── hcsr04/
│   ├── hcsr04.c            # HC-SR04 超声波测距驱动
│   └── hcsr04.h            # HC-SR04 头文件
├── led/
│   ├── led.c               # LED 警示灯 GPIO 驱动
│   └── led.h               # LED 头文件
├── motor/
│   ├── motor.c             # TB6612 电机驱动 (风扇PWM控制)
│   └── motor.h             # 电机驱动头文件
├── mq2/
│   ├── mq2.c               # MQ-2 烟雾传感器 ADC 驱动
│   └── mq2.h               # MQ-2 头文件
├── mqtt/
│   ├── mqtt.c              # MQTT 客户端 (连接华为云IoTDA)
│   └── mqtt.h              # MQTT 头文件
├── oled/
│   ├── oled.c              # SSD1306 OLED I2C 初始化
│   ├── oled.h              # OLED 头文件
│   ├── bsp_oled.c          # OLED 底层驱动 (画点/线/字符)
│   ├── bsp_oled.h          # OLED 底层驱动头文件
│   ├── oled_fonts.c        # 字库数据
│   └── oled_fonts.h        # 字库头文件
├── pwm/
│   ├── pwm_lamp.c          # PWM 驱动 (风扇电机调速)
│   └── pwm_lamp.h          # PWM 头文件
├── voice/
│   ├── voice.c             # 语音识别模块 UART 驱动与控制逻辑
│   └── voice.h             # 语音模块头文件
└── wifi/
    ├── wifi_connect.c      # WiFi STA 模式连接驱动
    └── wifi_connect.h      # WiFi 头文件
```

## 硬件平台

- **主控芯片**：海思 Hi3861V100 (WS63)
- **开发环境**：OpenHarmony / BearPi-HM Nano
- **SDK**：HiSilicon WS63 SDK

### 引脚分配

| 外设 | 引脚 | 功能 |
|------|------|------|
| 蜂鸣器 | GPIO_00 | 有源蜂鸣器控制 |
| 风扇 PWM | GPIO_01 | TB6612 PWMA 调速 |
| LED1 | GPIO_02 | 警示灯1 |
| LED2 | GPIO_03 | 警示灯2 |
| DHT11 | GPIO_04 | 温湿度数据 |
| LDR (ADC5) | GPIO_05 | 光照传感器 ADC |
| HC-SR04 Trig | GPIO_06 | 超声波触发 |
| HC-SR04 Echo | GPIO_09 | 超声波回声 |
| 语音 UART TX | GPIO_08 | SU-03T 发送 |
| 语音 UART RX | GPIO_07 | SU-03T 接收 |
| 风扇 AIN1 | GPIO_10 | TB6612 方向1 |
| 风扇 AIN2 | GPIO_11 | TB6612 方向2 |
| MQ-2 (ADC0) | GPIO_12 | 烟雾传感器 ADC |
| OLED SDA | GPIO_16 | I2C1 数据 |
| OLED SCL | GPIO_15 | I2C1 时钟 |
| CO2 UART RX | GPIO_16 | JW01 传感器 UART1 |

## 安装部署指南

### 前提条件

1. **硬件准备**：
   - BearPi-HM Nano 开发板（Hi3861V100）或同等 WS63 开发板
   - DHT11 温湿度传感器模块
   - HC-SR04 超声波测距模块
   - MQ-2 烟雾传感器模块
   - JW01/TVOC-301 空气质量传感器
   - LDR 光敏电阻模块
   - SSD1306 OLED 显示屏 (128x64, I2C)
   - TB6612 电机驱动模块 + 直流风扇
   - SU-03T 语音识别模块
   - 有源蜂鸣器模块
   - LED 灯珠 x2

2. **软件环境**：
   - Windows/Linux 开发主机
   - HiSilicon WS63 SDK
   - Python 3.8+ (用于编译脚本)
   - CMake 3.16+
   - ARM 交叉编译工具链 (arm-none-eabi-gcc)

### 编译步骤

```bash
# 1. 克隆仓库
git clone <仓库地址>
cd 21_huaweiiot

# 2. 将本项目放置在 SDK 目录中
# cp -r 21_huaweiiot/ <SDK_PATH>/src/application/samples/wanglian/

# 3. 修改配置文件
# 编辑 app_main.h，填入你的 WiFi 和华为云 IoT 认证信息

# 4. 编译
cd <SDK_PATH>
python build.py 21_huaweiiot

# 5. 烧录
# 使用 HiBurn 工具或串口烧录工具将编译生成的固件烧录到开发板
```

### 配置说明

在 `app_main.h` 中修改以下配置：

```c
// WiFi 热点配置
#define CONFIG_WIFI_SSID        "YourWiFiSSID"
#define CONFIG_WIFI_PWD         "YourWiFiPassword"

// 华为云 IoTDA MQTT 服务器地址
#define SERVER_IP_ADDR          "your-iotda-server.iotda-device.cn-north-4.myhuaweicloud.com"
#define SERVER_IP_PORT          1883

// 设备认证信息
#define CLIENT_ID               "your-device-id_0_0_2025010112"
#define DEVICEID                "your-device-id"
#define CLIENTPASSWORD          "your-device-secret"

// MQTT 主题
#define MQTT_CMDTOPIC_SUB       "$oc/devices/your-device-id/sys/commands/#"
#define MQTT_DATATOPIC_PUB      "$oc/devices/your-device-id/sys/properties/report"
```

## 使用说明

### 设备启动

1. 上电后，设备自动初始化 GPIO、传感器、OLED 显示屏
2. 自动连接配置的 WiFi 热点
3. 自动连接华为云 IoTDA MQTT 服务器
4. OLED 屏幕开始实时显示传感器数据

### 本地语音控制

通过语音识别模块（SU-03T）发出以下语音指令：

| 语音指令 | 功能 | 对应命令码 |
|----------|------|-----------|
| "打开灯" | 点亮 LED1 警示灯 | 0x01 |
| "关闭灯" | 熄灭 LED1 警示灯 | 0x02 |
| "打开风扇" | 开启散热风扇 | 0x03 |
| "关闭风扇" | 关闭散热风扇 | 0x04 |
| "打开蜂鸣器" | 蜂鸣器报警 | 0x10 |
| "关闭蜂鸣器" | 蜂鸣器静音 | 0x11 |
| "查询温度" | 语音播报当前温度 | 0x0A |
| "查询湿度" | 语音播报当前湿度 | 0x0B |
| "查询距离" | 语音播报当前距离 | 0x0C |
| "查询CO2" | 语音播报CO2浓度 | 0x0D |
| "查询烟雾" | 语音播报烟雾浓度 | 0x0E |

### 云端远程控制

通过华为云 IoTDA 平台下发以下属性命令：

| 命令 | 功能 | 参数 |
|------|------|------|
| Light | 开关灯 | ON / OFF |
| Fan | 开关风扇 | ON / OFF |
| BeepWarning | 开关蜂鸣器 | ON / OFF |
| CtlMode | 控制模式 | AUTO / HUMAN / VOICE |
| LightDegree | 灯光亮度 | 0-100 |
| Smoke | 烟雾报警 | ON / OFF |

### 数据查看

- **本地**：通过 OLED 屏幕实时查看温湿度、光照、距离、烟雾浓度
- **云端**：登录华为云 IoTDA 控制台查看设备属性历史数据
- **串口**：通过串口调试工具查看详细的 `printf` 调试日志

## 开发成员及分工

| 姓名 | 分工 | 负责模块 |
|------|------|----------|
| 程国辉 | 嵌入式主程 | 系统架构、MQTT通信、WiFi连接、语音控制、CO2传感器 |
| 刘艳 | 嵌入式开发 | 传感器驱动(DHT11/ADC/HC-SR04)、执行器驱动(LED/电机/蜂鸣器/PWM)、OLED显示 |

## 开源仓库地址

- **GitHub**：[SmartSite/embedded/timber-area](https://github.com/SKY-shenzi/SmartSite/tree/master/embedded/timber-area)

## 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| V1.0 | 2025年11月 | 初始版本，完成基础传感器采集、MQTT通信、WiFi连接 |
| V2.0 | 2026年7月 | 新增CO2传感器(TVOC/甲醛/eCO2)、蜂鸣器驱动、语音控制模块、OLED显示优化 |

## 许可证

本项目部分代码基于海思 SDK 和北京华清远见教育科技示例代码修改，原始代码遵循 Apache License 2.0。其余自定义代码仅供学习使用。

## 致谢

- 海思半导体 (HiSilicon Technologies) - WS63 SDK 与 WiFi 驱动
- 北京华清远见教育科技 - MQTT 客户端示例代码
- 华为云 IoTDA - 物联网设备接入平台
- 全国示范性软件学院联盟 - 太乙开源生态服务平台
