/*****************************************************************************************/
/*                                                                                       */
/*                  版权所有：沈阳市网联通信规划设计有限公司                                 */
/*                  开发人员：程国辉 刘艳                                                  */
/*                  联系方式：908536420  3512904489                                        */
/*                  程序主题：TCP+WIFi+MQTT连接华为云实验                                   */
/*                  开发时间：2025年11月                                                  */
/*                  本程序只供学习使用，未经作者许可，不得用于其它任何用途                    */
/*                  版本：V1.0                                                           */
/*                  版权所有，盗版必究                                                    */
/*                                                                                       */
/*****************************************************************************************/

#include "lwip/netifapi.h"
#include "wifi_hotspot.h"
#include "wifi_hotspot_config.h"
#include "stdlib.h"
#include "uart.h"
#include "lwip/nettool/misc.h"
#include "soc_osal.h"
#include "app_init.h"
#include "cmsis_os2.h"
#include "wifi_device.h"
#include "wifi_event.h"
#include "lwip/sockets.h"
#include "lwip/ip4_addr.h"
#include "wifi/wifi_connect.h"
#include "dht11/dht11.h"
#include "oled/oled.h"
#include "app_main.h"
#include "adc/ldr.h"
#include "hcsr04/hcsr04.h"
#include "led/led.h"
#include "motor/motor.h"
#include "mq2/mq2.h"
#include "co2/co2.h"
#include "beep/beep.h"
#include "voice/voice.h"


#define WIFI_TASK_STACK_SIZE 0x2000

#define DELAY_TIME_MS 100

DHT11_Data_TypeDef DHT11_Data;  //存放温度数据

char LampSt[4] = {0};//灯状态
char FanSt[4] = {0}; //风扇状态
char BuzzerSt[4] = "OFF"; //蜂鸣器状态
int lampState=1;
int fanState=1;           // 风扇状态 0=ON, 1=OFF
int buzzerState=1;        // 蜂鸣器状态 0=ON, 1=OFF

int32_t distance;
uint16_t alsData;
uint16_t ldr_value;
uint16_t mq2_value;       // MQ2 烟雾浓度 0-100%
uint16_t co2_value;      // CO2 浓度 (PPM)


//以下为采集环境信息的子任务，源源不断的采集各种物联网环境信息数据
static void *environment_task(const char *arg)
{
     unused(arg);

     char lcd_buff[100]={0};
     errcode_t result;
     osal_msleep(1000);  //先稳定一下情绪每秒钟采集一次信息

     while(1)
     {

        result = dht11_read_data(&DHT11_Data);
         if(result ==  ERRCODE_SUCC)
         {
            printf("Temperature:%d.%d, Humidity:%d.%d\n", DHT11_Data.temp_high8bit, DHT11_Data.temp_low8bit, DHT11_Data.humi_high8bit, DHT11_Data.humi_low8bit);
            memset(lcd_buff,0,100);
            sprintf(lcd_buff, "Temp:%d.%d " ,DHT11_Data.temp_high8bit,DHT11_Data.temp_low8bit);
            bsp_oled_DrawString(0, 0, lcd_buff, Font_7x10, White);
            memset(lcd_buff,0,100);
            sprintf(lcd_buff, "Humi:%d.%d " ,DHT11_Data.humi_high8bit,DHT11_Data.humi_low8bit);
            bsp_oled_DrawString(0, 10, lcd_buff, Font_7x10, White);
            bsp_oled_UpdateScreen();
        }
        else{
            printf("Read DHT11 data fail.\n");
         }

        ldr_value = get_adc_value();
        memset(lcd_buff,0,100);
        sprintf(lcd_buff, "Lumi:%d   " ,ldr_value);
        bsp_oled_DrawString(0, 20, lcd_buff, Font_7x10, White);

        distance=hcsr04_get_distance();
        memset(lcd_buff,0,100);
        sprintf(lcd_buff, "Dist:%d  mm " ,distance);
        bsp_oled_DrawString(0, 30, lcd_buff, Font_7x10, White);
        mq2_value = get_mq2_value();
        memset(lcd_buff,0,100);
        sprintf(lcd_buff, "Smoke:%d%%   " ,mq2_value);
        bsp_oled_DrawString(0, 50, lcd_buff, Font_7x10, White);
        memset(lcd_buff,0,100);

        co2_value = co2_get_eco2();
        printf("CO2:%d PPM\n", co2_value);

        memset(LampSt,0,4);
        if(lampState==0)
            snprintf_s(LampSt, sizeof(LampSt), sizeof(LampSt)-1, "ON");
        else
            snprintf_s(LampSt, sizeof(LampSt), sizeof(LampSt)-1, "OFF");

        memset(FanSt,0,4);
        if(fanState==0)
            snprintf_s(FanSt, sizeof(FanSt), sizeof(FanSt)-1, "ON");
        else
            snprintf_s(FanSt, sizeof(FanSt), sizeof(FanSt)-1, "OFF");

        memset(BuzzerSt,0,4);
        if(buzzerState==0)
            snprintf_s(BuzzerSt, sizeof(BuzzerSt), sizeof(BuzzerSt)-1, "ON");
        else
            snprintf_s(BuzzerSt, sizeof(BuzzerSt), sizeof(BuzzerSt)-1, "OFF");

        osDelay(DELAY_TIME_MS);
        // osal_msleep(1000);  //每1秒采集一次
     }

    return NULL;
}


//本函数处理GPIO输出灯泡，电机的初始化，GPIO输入属性的初始化
static void gpio_init(void)
{
    uart_gpio_init();   // 初始化语音模块UART GPIO（GPIO_07/08）
    uart_init_config(); // 初始化语音模块UART（UART_BUS_2, 115200）
}

//本函数处理环境传感器的初始化、显示屏、串口的初始化
static void environment_sensor_init(void)
{
    dht11_init();
    oled_init();
    hcsr04_init();
    adc_init();
    led_init();
    motor_init();   // 初始化风扇电机（TB6612 + PWM）
    mq2_init();     // 初始化MQ2烟雾传感器（ADC）
    co2_init(0);        // 初始化CO2传感器（硬件UART1, 9600）
    beep_init();        // 初始化蜂鸣器（GPIO_00, 有源）
}




static void *appmain_start(const char *argument)
{
    unused(argument);

    gpio_init();    //完成gpio输出相关的初始化，部分输入KEY的初始化
    environment_sensor_init();//完成采集传感器的初始化、显示屏和串口初始化
    wifi_connect(); //连接WIFI热点

    return NULL;
}



static void app_main(void)
{
    printf(" HUAWEI IOT BEGIN.....\r\n");

   // osDelay(DELAY_TIME_MS);   //延时100Ms
    osal_kthread_lock();
        osal_task *task1 = osal_kthread_create((osal_kthread_handler)appmain_start, 0, "appmain_start", 0x1000);
        osal_kthread_set_priority(task1, 10);
        printf("Create appmain_start succ.\r\n");

        osal_task *task2 = osal_kthread_create((osal_kthread_handler)environment_task, 0, "Environment_task", 0x1000);
        osal_kthread_set_priority(task2, 10);
        printf("Create Environment_task succ.\r\n");

        osal_task *task3 = osal_kthread_create((osal_kthread_handler)uart_voice_task, 0, "UartVoiceTask", 0x1000);
        osal_kthread_set_priority(task3, 10);
        printf("Create UartVoiceTask succ.\r\n");
  	osal_kthread_unlock();   
}

/* Run the app_main. */
app_run(app_main);