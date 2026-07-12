# IoTDA AK/SK Proxy

这个代理用于演示项目读取真实华为云 IoTDA 设备影子数据。

元服务不要直接保存 AK/SK。AK/SK 只放在本机环境变量里，由代理签名请求 IoTDA。

## 启动

PowerShell：

```powershell
$env:HUAWEI_AK='你的AK'
$env:HUAWEI_SK='你的SK'
node server\iotda-proxy\server.js
```

默认访问：

```text
http://127.0.0.1:8787/api/iotda/shadow
```

如果是真机访问，把 `entry/src/main/ets/common/IotdaConfig.ets` 中的 `proxyEndpoint` 改成电脑局域网 IP：

```ts
proxyEndpoint: 'http://电脑局域网IP:8787/api/iotda/shadow'
```

## 已内置的 IoTDA 信息

- 区域：`cn-north-4`
- Endpoint：`iotda.cn-north-4.myhuaweicloud.com`
- Project ID：`0e7c5e04a662439c813433f94d7ad4e7`
- Instance ID：`97ea8a7a-5cdb-4b0d-a4ae-3285825e26e8`
- APPID：`f7671bc74b254ad2bdfe9417fe9919a9`
- Product ID：`6a3a6e8e7f2e6c302f7e2b06`
- Device ID：`6a3a6e8e7f2e6c302f7e2b06_GongDone`
- Service ID：`smartdevice`
- 温度字段：`Temp`
- 湿度字段：`Humi`

## 校验

启动后在浏览器或 PowerShell 中访问：

```powershell
Invoke-RestMethod http://127.0.0.1:8787/api/iotda/shadow
```

成功时会返回：

```json
{
  "source": "iotda",
  "serviceId": "smartdevice",
  "temperature": "...",
  "humidity": "..."
}
```
