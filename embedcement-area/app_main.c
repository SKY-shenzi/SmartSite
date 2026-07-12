#include "soc_osal.h"
#include "app_init.h"
#include "cmsis_os2.h"
#include "errcode.h"

#include <stdio.h>
#include <string.h>

#include "wifi/wifi_connect.h"
#include "dht11/dht11.h"
#include "oled/oled.h"
#include "app_main.h"
#include "fan/fan.h"
#include "beep/beep.h"

#define DELAY_TIME_MS 100

DHT11_Data_TypeDef DHT11_Data;

char FanSt[4] = "OFF";
char AlarmSt[4] = "OFF";
char Mode[8] = "AUTO";

int tempFanOn = 32;
int tempFanOff = 30;
int humiAlarmOn = 60;
int humiAlarmOff = 55;

static void set_state(char *state, size_t state_size, const char *value)
{
    memset(state, 0, state_size);
    snprintf(state, state_size, "%s", value);
}

static void cement_area_auto_control(void)
{
    if (strcmp(Mode, "AUTO") != 0) {
        return;
    }

    if (DHT11_Data.humidity >= (float)humiAlarmOn) {
        set_state(AlarmSt, sizeof(AlarmSt), "ON");
        beep_on();
    } else if (DHT11_Data.humidity <= (float)humiAlarmOff) {
        set_state(AlarmSt, sizeof(AlarmSt), "OFF");
        beep_off();
    }

    if (DHT11_Data.temperature >= (float)tempFanOn) {
        set_state(FanSt, sizeof(FanSt), "ON");
        fan_on();
    } else if (DHT11_Data.temperature <= (float)tempFanOff) {
        set_state(FanSt, sizeof(FanSt), "OFF");
        fan_off();
    }
}

static void *environment_task(const char *arg)
{
    (void)arg;

    char lcd_buff[100] = {0};
    errcode_t result;

    osal_msleep(1000);
    while (1) {
        result = dht11_read_data(&DHT11_Data);
        if (result == ERRCODE_SUCC) {
            cement_area_auto_control();

            printf("Temperature:%4.2f, Humidity:%4.2f, FanSt:%s, AlarmSt:%s, Mode:%s\n",
                DHT11_Data.temperature, DHT11_Data.humidity, FanSt, AlarmSt, Mode);

            memset(lcd_buff, 0, sizeof(lcd_buff));
            snprintf(lcd_buff, sizeof(lcd_buff), "Temp:%4.1f ", DHT11_Data.temperature);
            bsp_oled_DrawString(0, 0, lcd_buff, Font_7x10, White);

            memset(lcd_buff, 0, sizeof(lcd_buff));
            snprintf(lcd_buff, sizeof(lcd_buff), "Humi:%4.1f ", DHT11_Data.humidity);
            bsp_oled_DrawString(0, 10, lcd_buff, Font_7x10, White);

            memset(lcd_buff, 0, sizeof(lcd_buff));
            snprintf(lcd_buff, sizeof(lcd_buff), "Fan:%s Alarm:%s ", FanSt, AlarmSt);
            bsp_oled_DrawString(0, 20, lcd_buff, Font_7x10, White);

            memset(lcd_buff, 0, sizeof(lcd_buff));
            snprintf(lcd_buff, sizeof(lcd_buff), "Mode:%s ", Mode);
            bsp_oled_DrawString(0, 30, lcd_buff, Font_7x10, White);
            bsp_oled_UpdateScreen();
        } else {
            printf("Read DHT11 data fail.\n");
        }

        osDelay(DELAY_TIME_MS);
    }

    return NULL;
}

static void gpio_init(void)
{
}

static void environment_sensor_init(void)
{
    dht11_init();
    oled_init();
    fan_init();
    beep_init();
    fan_off();
    beep_off();
    set_state(FanSt, sizeof(FanSt), "OFF");
    set_state(AlarmSt, sizeof(AlarmSt), "OFF");
    set_state(Mode, sizeof(Mode), "AUTO");
}

static void *appmain_start(const char *argument)
{
    (void)argument;

    gpio_init();
    environment_sensor_init();
    wifi_connect();

    return NULL;
}

static void app_main(void)
{
    printf(" CEMENT AREA IOT BEGIN.....\r\n");

    osal_kthread_lock();
    osal_task *task1 = osal_kthread_create((osal_kthread_handler)appmain_start, 0, "appmain_start", 0x1000);
    osal_kthread_set_priority(task1, 10);
    printf("Create appmain_start succ.\r\n");

    osal_task *task2 = osal_kthread_create((osal_kthread_handler)environment_task, 0, "Environment_task", 0x1000);
    osal_kthread_set_priority(task2, 10);
    printf("Create Environment_task succ.\r\n");
    osal_kthread_unlock();
}

app_run(app_main);
