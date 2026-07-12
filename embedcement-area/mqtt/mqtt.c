/*
 * Copyright (c) 2024 Beijing HuaQingYuanJian Education Technology Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "soc_osal.h"
#include "app_init.h"
#include "cmsis_os2.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "MQTTClientPersistence.h"
#include "MQTTClient.h"
#include "errcode.h"
#include "../wifi/wifi_connect.h"
#include "../app_main.h"
#include "../dht11/dht11.h"
#include "../fan/fan.h"
#include "../beep/beep.h"

#ifndef unused
#define unused(var)     (void)(var)
#endif

osThreadId_t mqtt_init_task_id; // mqtt订阅数据任务

#define KEEP_ALIVE_INTERVAL 120
#define DELAY_TIME_MS 100


char g_send_buffer[260] = {0}; // 发布数据缓冲区
char g_response_id[100] = {0}; // 保存命令id缓冲区

MQTTClient_message pubmsg = MQTTClient_message_initializer;
MQTTClient_deliveryToken token;

// 全局定义静态缓冲区（避免函数内反复分配）
static char topicBuf[256] = {0};
static char dataBuf[1024] = {0};
#define		JSON_Tree_Format	"{ \n "					\
                                "\"services\": [{ \n"		\
                                "\"service_id\": \"cement_zone\", \n"	\
                                "\"properties\": { \n"	\
                                    "\"Temp\":  \"%4.2f\", \n"	\
                                    "\"Humi\":  \"%4.2f\", \n"	\
                                    "\"FanSt\":  \"%s\", \n"	\
                                    "\"AlarmSt\":  \"%s\", \n"	\
                                    "\"Mode\":  \"%s\", \n"	\
                                    "\"tempFanOn\":  \"%d\", \n"	\
                                    "\"tempFanOff\":  \"%d\", \n"	\
                                    "\"humiAlarmOn\":  \"%d\", \n"	\
                                    "\"humiAlarmOff\":  \"%d\" \n"	\
                                    "}, \n"	\
                                "\"event_time\": \"\" \n"	\
                                "} \n"	\
                                "] \n"	\
                                "}\n"
                                

char A_JSON_Tree[1024] = {0};	// 存放JSON树

char g_response_buf[] =
    "{\"result_code\": 0,\"response_name\": \"cement_zone\",\"paras\": {\"result\": \"success\"}}"; // 响应json
uint8_t g_cmdFlag;
MQTTClient client;
volatile MQTTClient_deliveryToken deliveredToken;
extern int MQTTClient_init(void);

extern DHT11_Data_TypeDef DHT11_Data;  //存放温度数据
extern char FanSt[4];
extern char AlarmSt[4];
extern char Mode[8];

extern int tempFanOn;
extern int tempFanOff;
extern int humiAlarmOn;
extern int humiAlarmOff;

static void set_text(char *dst, size_t dst_size, const char *value)
{
    memset(dst, 0, dst_size);
    snprintf(dst, dst_size, "%s", value);
}

static int parse_int_param(const char *payload, const char *key, int *value)
{
    const char *pos = strstr(payload, key);
    if (pos == NULL) {
        return 0;
    }

    pos = strchr(pos, ':');
    if (pos == NULL) {
        return 0;
    }
    pos++;

    while (*pos == ' ' || *pos == '\"' || *pos == '\t') {
        pos++;
    }

    int sign = 1;
    if (*pos == '-') {
        sign = -1;
        pos++;
    }

    if (*pos < '0' || *pos > '9') {
        return 0;
    }

    int result = 0;
    while (*pos >= '0' && *pos <= '9') {
        result = result * 10 + (*pos - '0');
        pos++;
    }

    *value = result * sign;
    return 1;
}

// 创建JSON树
//===================================================================================================
static void  Setup_JSON_Tree_JX(void)
{

	printf(" into setup json\n");
	// 赋值JSON树【赋值JSON_Tree_Format字符串中的格式字符】
	memset(A_JSON_Tree,0,sizeof(A_JSON_Tree));
	snprintf(A_JSON_Tree, sizeof(A_JSON_Tree), JSON_Tree_Format,
        DHT11_Data.temperature,
        DHT11_Data.humidity,
        FanSt,
        AlarmSt,
        Mode,
        tempFanOn,
        tempFanOff,
        humiAlarmOn,
        humiAlarmOff);

	printf("\r\n-------------------- create JSON tree -------------------\r\n");

	printf("%s",A_JSON_Tree);	// 串口打印JSON树

	printf("\r\n--------------------create JSON tree  -------------------\r\n");

}


/* 回调函数，处理连接丢失 */
void connlost(void *context, char *cause)
{
    unused(context);
    printf("Connection lost: %s\n", cause);
}
int mqtt_subscribe(const char *topic)
{
    printf("subscribe start\r\n");
    MQTTClient_subscribe(client, topic, 1);
    return 0;
}

int mqtt_publish(const char *topic, char *msg)
{

    int ret = 0;
    pubmsg.payload = msg;
    pubmsg.payloadlen = (int)strlen(msg);
    pubmsg.qos = 1;
    pubmsg.retained = 0;
    //printf("[payload]:  %s, [topic]: %s\r\n", msg, topic);
    ret = MQTTClient_publishMessage(client, topic, &pubmsg, &token);

    if (ret != MQTTCLIENT_SUCCESS) {
        printf("mqtt publish failed\r\n");
        return ret;
    }

    return ret;
}

/* 回调函数，处理消息到达 */
void delivered(void *context, MQTTClient_deliveryToken dt)
{
    unused(context);
   // printf("Message with token value %d delivery confirmed\n", dt);

    deliveredToken = dt;
}
// 解析字符串并保存到数组中
void parse_after_equal(const char *input, char *output, size_t output_size)
{
    if (output == NULL || output_size == 0) {
        return;
    }

    output[0] = '\0';
    const char *equalsign = strchr(input, '=');
    if (equalsign != NULL) {
        // 计算等于号后面的字符串长度
        snprintf(output, output_size, "%s", equalsign + 1);
    }
}
/* 回调函数，处理接收到的消息 */
int messageArrived(void *context, char *topic_name, int topic_len, MQTTClient_message *message)
{
    unused(context);
    if (topic_name == NULL || message == NULL || message->payload == NULL) {
        return 0;
    }

    size_t topic_copy_len;
    size_t data_copy_len;
   
    char *tmpT = NULL;
    // 新增长度校验，避免内存越界
    if (topic_len <= 0) {
        topic_copy_len = strlen(topic_name);
    } else {
        topic_copy_len = (size_t)topic_len;
    }
    data_copy_len = (message->payloadlen > 0) ? (size_t)message->payloadlen : 0;

    if (topic_copy_len >= sizeof(topicBuf)) {
        printf("Topic length exceeds buffer size!\n");
        topic_copy_len = sizeof(topicBuf) - 1; // 截断保护
    }
    if (data_copy_len >= sizeof(dataBuf)) {
        printf("Data length exceeds buffer size!\n");
        data_copy_len = sizeof(dataBuf) - 1; // 截断保护
    }

    memset(topicBuf, 0, sizeof(topicBuf));
    memset(dataBuf, 0, sizeof(dataBuf));
    // 安全复制主题和消息
    memcpy(topicBuf, topic_name, topic_copy_len);
    topicBuf[topic_copy_len] = '\0';
    memcpy(dataBuf, (char *)message->payload, data_copy_len);
    dataBuf[data_copy_len] = '\0';

    // 打印接收日志
    printf("[MQTT] Receive topic: %s, data: %s \r\n", topicBuf, dataBuf);
    printf("[MQTT] Topic len: %u, Data len: %u\r\n", (unsigned int)topic_copy_len, (unsigned int)data_copy_len);

    tmpT = strstr(dataBuf, "SetMode");
    if(tmpT != NULL)
    {
        if(strstr(dataBuf, "AUTO") != NULL) {
            set_text(Mode, sizeof(Mode), "AUTO");
            printf("[MQTT] Command: SetMode AUTO\r\n");
        } else if(strstr(dataBuf, "MANUAL") != NULL) {
            set_text(Mode, sizeof(Mode), "MANUAL");
            printf("[MQTT] Command: SetMode MANUAL\r\n");
        }
    }

    tmpT = strstr(dataBuf, "SetFan");
    if(tmpT != NULL)
    {
        if(strstr(dataBuf, "ON") != NULL) {
            set_text(FanSt, sizeof(FanSt), "ON");
            fan_on();
            printf("[MQTT] Command: SetFan ON\r\n");
        } else if(strstr(dataBuf, "OFF") != NULL) {
            set_text(FanSt, sizeof(FanSt), "OFF");
            fan_off();
            printf("[MQTT] Command: SetFan OFF\r\n");
        }
    }

    tmpT = strstr(dataBuf, "ClearAlarm");
    if(tmpT != NULL)
    {
        set_text(AlarmSt, sizeof(AlarmSt), "OFF");
        beep_off();
        printf("[MQTT] Command: ClearAlarm\r\n");
    }

    tmpT = strstr(dataBuf, "SetThreshold");
    if(tmpT != NULL)
    {
        parse_int_param(dataBuf, "tempFanOn", &tempFanOn);
        parse_int_param(dataBuf, "tempFanOff", &tempFanOff);
        parse_int_param(dataBuf, "humiAlarmOn", &humiAlarmOn);
        parse_int_param(dataBuf, "humiAlarmOff", &humiAlarmOff);
        printf("[MQTT] Command: SetThreshold tempFanOn=%d tempFanOff=%d humiAlarmOn=%d humiAlarmOff=%d\r\n",
            tempFanOn, tempFanOff, humiAlarmOn, humiAlarmOff);
    }


    // 资源释放
    // 解析命令id
    parse_after_equal(topicBuf, g_response_id, sizeof(g_response_id));
   
    snprintf(g_send_buffer, sizeof(g_send_buffer), MQTT_CLIENT_RESPONSE, g_response_id);
    
    

    g_cmdFlag = 1;

    memset((char *)message->payload, 0, message->payloadlen);
    MQTTClient_freeMessage(&message);
    MQTTClient_free(topic_name);

    return 1;
}

static errcode_t mqtt_connect(void)
{
    int ret;
    MQTTClient_connectOptions conn_opts = MQTTClient_connectOptions_initializer;
    /* 初始化MQTT客户端 */
    MQTTClient_init();
    /* 创建 MQTT 客户端 */
    ret = MQTTClient_create(&client, SERVER_IP_ADDR, CLIENT_ID, MQTTCLIENT_PERSISTENCE_NONE, NULL);
    if (ret != MQTTCLIENT_SUCCESS) {
        printf("Failed to create MQTT client, return code %d\n", ret);
        return ERRCODE_FAIL;
    }
    conn_opts.keepAliveInterval = KEEP_ALIVE_INTERVAL;
    conn_opts.cleansession = 1;
#ifdef IOT
    conn_opts.username = DEVICEID;
    conn_opts.password = CLIENTPASSWORD;
#endif
    // 绑定回调函数
    MQTTClient_setCallbacks(client, NULL, connlost, messageArrived, delivered);

    // 尝试连接
    if ((ret = MQTTClient_connect(client, &conn_opts)) != MQTTCLIENT_SUCCESS) {
        printf("Failed to connect, return code %d\n", ret);
        MQTTClient_destroy(&client); // 连接失败时销毁客户端
        return ERRCODE_FAIL;
    }
    printf("Connected to MQTT broker!\n");
    osDelay(DELAY_TIME_MS);
    // 订阅MQTT主题
    mqtt_subscribe(MQTT_CMDTOPIC_SUB);

    return ERRCODE_SUCC;
}

void mqtt_init_task(const char *argument)
{
    unused(argument);
    osDelay(DELAY_TIME_MS);
    mqtt_connect();

    while(1){
            // 响应平台命令部分
        osDelay(DELAY_TIME_MS); // 需要延时 否则会发布失败
        if (g_cmdFlag) {
            snprintf(g_send_buffer, sizeof(g_send_buffer), MQTT_CLIENT_RESPONSE, g_response_id);
            // 设备响应命令
            mqtt_publish(g_send_buffer, g_response_buf);
            g_cmdFlag = 0;
            memset(g_response_id, 0, sizeof(g_response_id) / sizeof(g_response_id[0]));
        }

        printf("construct json tree\r\n");
        Setup_JSON_Tree_JX();   
        mqtt_publish(MQTT_DATATOPIC_PUB, A_JSON_Tree);
        memset(A_JSON_Tree, 0,sizeof(A_JSON_Tree));
        osDelay(DELAY_TIME_MS);   //延时1000Ms
        //osal_msleep(1000);  //每1秒采集一次
    }

}

/*********************************************************************
 * 函数名：mqtt_app_start
 * 描述：MQTT应用启动入口（创建MQTT任务）
 * 参数：无
 * 返回值：ERRCODE_SUCC(0)-成功，ERRCODE_FAIL(-1)-失败
 ********************************************************************/
void mqtt_app_start(void)
{
    // osal_kthread_lock();
	 
	// osal_task *task1 = osal_kthread_create((osal_kthread_handler)mqtt_init_task, 0, "mqtt_init_task", 0x3000);
	// osal_kthread_set_priority(task1, 10);
	// printf("Create mqtt_init_task succ.\r\n");

	// osal_kthread_unlock();

    // printf("Enter network_wifi_mqtt_example()!");

    // 配置新任务的属性
    osThreadAttr_t options;
    options.name = "mqtt_init_task";     // 任务名称
    options.attr_bits = 0;               // 属性位
    options.cb_mem = NULL;               // 控制块内存地址
    options.cb_size = 0;                 // 控制块大小
    options.stack_mem = NULL;            // 栈内存地址
    options.stack_size = 0x6000;         // 栈大小（12KB）
    options.priority = osPriorityNormal; // 任务优先级

    // 创建并启动MQTT初始化任务
    mqtt_init_task_id = osThreadNew((osThreadFunc_t)mqtt_init_task, NULL, &options);
    if (mqtt_init_task_id != NULL) {
        printf("ID = %d, Create mqtt_init_task_id is OK!", mqtt_init_task_id);
    }


}

