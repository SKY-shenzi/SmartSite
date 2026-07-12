#ifndef _MAIN_H
#define _MAIN_H

// MQTT server config
#define SERVER_IP_ADDR          "YOUR_IOTDA_MQTT_HOST"
#define SERVER_IP_PORT          1883

// MQTT topic config
#define MQTT_CMDTOPIC_SUB       "$oc/devices/YOUR_DEVICE_ID/sys/commands/#"
#define MQTT_DATATOPIC_PUB      "$oc/devices/YOUR_DEVICE_ID/sys/properties/report"
#define MQTT_CLIENT_RESPONSE    "$oc/devices/YOUR_DEVICE_ID/sys/commands/response/request_id=%s"

#define IOT

// Device auth config
#ifdef IOT
#define CLIENT_ID               "YOUR_CLIENT_ID"
#define DEVICEID                "YOUR_DEVICE_ID"
#define CLIENTPASSWORD          "YOUR_DEVICE_PASSWORD"
#endif

// WiFi config
#define CONFIG_WIFI_SSID        "YOUR_WIFI_SSID"
#define CONFIG_WIFI_PWD         "YOUR_WIFI_PASSWORD"

#endif
