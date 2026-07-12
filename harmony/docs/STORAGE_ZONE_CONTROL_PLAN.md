# 智慧工地双温控区设计方案

## 1. 区域选择

本阶段选择两个存储条件差异明显的区域：

- 水泥存储区：重点防潮，湿度是主要风险，温度是辅助风险。
- 木材存储区：重点防高温、过干、烟雾火险，温湿度和烟雾共同判断。

App 端只展示已接入真实数据的水泥区。木材区在第二块板接入前只显示“待接入”，不展示假数据。

## 2. 华为云 IoTDA 产品模型建议

建议一个产品 SmartDevice 下保留两个服务，分别代表两个温控区。

### 2.1 水泥区服务

service_id: `cement_zone`

属性 reported：

```json
{
  "Temp": "28.1",
  "Humi": "54.0",
  "FanSt": "OFF",
  "AlarmSt": "OFF",
  "Mode": "AUTO"
}
```

期望配置 desired：

```json
{
  "tempFanOn": "32",
  "tempFanOff": "30",
  "humiAlarmOn": "60",
  "humiAlarmOff": "55"
}
```

命令：

- `SetMode`: AUTO / MANUAL
- `SetFan`: ON / OFF
- `ClearAlarm`: 清除报警
- `SetThreshold`: 修改阈值

### 2.2 木材区服务

service_id: `wood_zone`

属性 reported：

```json
{
  "Temp": "30.0",
  "Humi": "42.0",
  "Smoke": "0",
  "FanSt": "OFF",
  "SpraySt": "OFF",
  "AlarmSt": "OFF",
  "Mode": "AUTO"
}
```

期望配置 desired：

```json
{
  "tempAlarmOn": "35",
  "tempAlarmOff": "32",
  "humiLowOn": "35",
  "humiLowOff": "40",
  "smokeAlarm": "1"
}
```

命令：

- `SetMode`: AUTO / MANUAL
- `SetFan`: ON / OFF
- `SetSpray`: ON / OFF
- `ClearAlarm`: 清除报警
- `SetThreshold`: 修改阈值

## 3. 板端控制逻辑

### 3.1 水泥区板端

设备目标：防潮，避免水泥受潮结块。

建议硬件：

- 温湿度传感器：DHT22 / SHT30
- 风扇继电器：用于通风
- 蜂鸣器或警示灯：湿度报警

控制逻辑：

```text
如果 Humi >= 60%：
  AlarmSt = ON
  蜂鸣器/警示灯开启

如果 Humi <= 55%：
  AlarmSt = OFF

如果 Temp >= 32°C：
  FanSt = ON
  风扇开启

如果 Temp <= 30°C：
  FanSt = OFF
```

说明：使用回差值，避免风扇和报警器在阈值附近反复开关。

### 3.2 木材区板端

设备目标：防高温、过干和火险。

建议硬件：

- 温湿度传感器：DHT22 / SHT30
- 烟雾传感器：MQ-2 或同类模块
- 风扇继电器：高温通风
- 喷雾/加湿继电器：过干时预警或加湿
- 蜂鸣器/警示灯：烟雾或高温报警

控制逻辑：

```text
如果 Smoke >= 1：
  AlarmSt = ON
  FanSt = ON
  立即报警

如果 Temp >= 35°C：
  FanSt = ON
  AlarmSt = ON

如果 Temp <= 32°C 且 Smoke == 0：
  高温报警解除

如果 Humi <= 35%：
  SpraySt = ON
  过干预警

如果 Humi >= 40%：
  SpraySt = OFF
```

## 4. App 端适配

当前 App 已按以下方式适配：

- 水泥区：绑定现有 IoTDA 设备影子真实数据 `Temp`、`Humi`、`LampST`。
- 水泥区风扇策略：App 根据阈值显示“开启/关闭”，板端最终执行。
- 水泥区防潮警报：App 根据湿度显示“报警/正常”。
- 木材区：展示独立方案，但在第二块板未接入前显示“待接入/待配置”，不展示假数据。
- 打卡、工时、其它区域：显示“待开发”，不展示假数据。

下一步需要板端和云端补齐后，再把木材区绑定到 `wood_zone` 服务。

## 5. 上报频率建议

- 板端：每 5 秒上报一次，或者状态变化时立即上报一次。
- App：每 5 秒查询设备影子一次。
- 不建议 1 秒内多次刷新，避免浪费云端请求和设备资源。
