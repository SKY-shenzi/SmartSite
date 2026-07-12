#ifndef _MAIN_H
#define _MAIN_H



// MQTT服务器配置（保持原有）
#define SERVER_IP_ADDR          "your-server.iotda-device.cn-north-4.myhuaweicloud.com"
#define SERVER_IP_PORT           1883


// MQTT主题配置（保持原有）
#define MQTT_CMDTOPIC_SUB       "$oc/devices/your-device-id/sys/commands/#"
#define MQTT_DATATOPIC_PUB      "$oc/devices/your-device-id/sys/properties/report"
#define MQTT_CLIENT_RESPONSE    "$oc/devices/your-device-id/sys/commands/response/request_id=%s"

#define IOT
// 认证信息（保持原有）
#ifdef IOT
#define CLIENT_ID               "your-device-id_0_0_2025010112"
#define DEVICEID                "your-device-id"
#define CLIENTPASSWORD          "your-device-secret"
#endif


#define CONFIG_WIFI_SSID        "YourWiFiSSID"
#define CONFIG_WIFI_PWD         "YourWiFiPassword"

#endif
