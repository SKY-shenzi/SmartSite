/*
 * 板载蜂鸣器驱动（有源蜂鸣器，板上三极管驱动，3.3V）
 *
 * GPIO 高电平 → 响，低电平 → 停
 */

#include "beep.h"
#include "gpio.h"
#include "pinctrl.h"
#include "stdio.h"

#ifndef CONFIG_BEEP_ACTIVE_LEVEL
#define CONFIG_BEEP_ACTIVE_LEVEL 1   /* 板载有源蜂鸣器：高电平有效 */
#endif
#ifndef CONFIG_BEEP_PIN
#define CONFIG_BEEP_PIN 0            /* GPIO_00 */
#endif

static pin_t g_beep_pin = CONFIG_BEEP_PIN;

static gpio_level_t beep_active_level(void)
{
    return CONFIG_BEEP_ACTIVE_LEVEL ? GPIO_LEVEL_HIGH : GPIO_LEVEL_LOW;
}

static gpio_level_t beep_inactive_level(void)
{
    return CONFIG_BEEP_ACTIVE_LEVEL ? GPIO_LEVEL_LOW : GPIO_LEVEL_HIGH;
}

int beep_init(void)
{
    uapi_pin_set_mode(g_beep_pin, PIN_MODE_0);
    uapi_gpio_set_dir(g_beep_pin, GPIO_DIRECTION_OUTPUT);
    uapi_gpio_set_val(g_beep_pin, beep_inactive_level());
    printf("Beeper initialized: GPIO_%d, active_level=%d\r\n", g_beep_pin, CONFIG_BEEP_ACTIVE_LEVEL);
    return 0;
}

int beep_on(void)
{
    uapi_gpio_set_val(g_beep_pin, beep_active_level());
    printf("Beeper ON\r\n");
    return 0;
}

int beep_off(void)
{
    uapi_gpio_set_val(g_beep_pin, beep_inactive_level());
    printf("Beeper OFF\r\n");
    return 0;
}

int beep_get_status(void)
{
    return uapi_gpio_get_val(g_beep_pin) == beep_active_level();
}
