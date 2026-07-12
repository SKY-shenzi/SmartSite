#include "fan.h"

#include "gpio.h"
#include "pinctrl.h"
#include "stdio.h"
#include "pwm_lamp.h"

#ifndef CONFIG_FAN_MOTOR_AIN1_PIN
#define CONFIG_FAN_MOTOR_AIN1_PIN 10
#endif

#ifndef CONFIG_FAN_MOTOR_AIN2_PIN
#define CONFIG_FAN_MOTOR_AIN2_PIN 11
#endif

#ifndef CONFIG_FAN_PWM_DUTY_PERCENT
#define CONFIG_FAN_PWM_DUTY_PERCENT 100
#endif

static unsigned char g_fan_inited = 0;
static unsigned char g_fan_running = 0;

static uint8_t fan_limit_duty(uint8_t duty)
{
    return duty > 100 ? 100 : duty;
}

static void fan_force_off_level(void)
{
    uapi_pin_set_mode(PWM_PIN, PIN_MODE_0);
    uapi_gpio_set_dir(PWM_PIN, GPIO_DIRECTION_OUTPUT);
    uapi_gpio_set_val(PWM_PIN, GPIO_LEVEL_LOW);
}

static void fan_set_forward(void)
{
    uapi_gpio_set_val(CONFIG_FAN_MOTOR_AIN1_PIN, GPIO_LEVEL_HIGH);
    uapi_gpio_set_val(CONFIG_FAN_MOTOR_AIN2_PIN, GPIO_LEVEL_LOW);
}

static void fan_set_stop(void)
{
    uapi_gpio_set_val(CONFIG_FAN_MOTOR_AIN1_PIN, GPIO_LEVEL_LOW);
    uapi_gpio_set_val(CONFIG_FAN_MOTOR_AIN2_PIN, GPIO_LEVEL_LOW);
}

int fan_init(void)
{
    pwm_print_info();
    errcode_t ret = pwm_init_module();
    if (ret != ERRCODE_SUCC) {
        printf("Fan PWM init failed: %d\r\n", ret);
        fan_force_off_level();
        return -1;
    }

    uapi_pin_set_mode(CONFIG_FAN_MOTOR_AIN1_PIN, PIN_MODE_0);
    uapi_pin_set_mode(CONFIG_FAN_MOTOR_AIN2_PIN, PIN_MODE_0);
    uapi_gpio_set_dir(CONFIG_FAN_MOTOR_AIN1_PIN, GPIO_DIRECTION_OUTPUT);
    uapi_gpio_set_dir(CONFIG_FAN_MOTOR_AIN2_PIN, GPIO_DIRECTION_OUTPUT);
    fan_set_stop();

    g_fan_inited = 1;
    g_fan_running = 0;
    fan_force_off_level();
    printf("Fan TB6612 initialized: PWMA=GPIO_%d, AIN1=GPIO_%d, AIN2=GPIO_%d\r\n",
        PWM_PIN, CONFIG_FAN_MOTOR_AIN1_PIN, CONFIG_FAN_MOTOR_AIN2_PIN);
    return 0;
}

int fan_set_speed(uint8_t duty)
{
    if (!g_fan_inited && fan_init() != 0) {
        return -1;
    }

    duty = fan_limit_duty(duty);
    if (duty == 0) {
        return fan_off();
    }

    fan_set_forward();
    uapi_pin_set_mode(PWM_PIN, PWM_PIN_MODE);
    errcode_t ret = pwm_setup_output(PWM_DESIRED_FREQ_HZ, duty);
    if (ret != ERRCODE_SUCC) {
        printf("Fan PWM output failed: %d\r\n", ret);
        fan_set_stop();
        fan_force_off_level();
        g_fan_running = 0;
        return -1;
    }

    g_fan_running = 1;
    printf("Fan PWM ON: channel=%d pin=%d freq=%d duty=%d%%\r\n",
        PWM_CHANNEL, PWM_PIN, PWM_DESIRED_FREQ_HZ, duty);
    return 0;
}

int fan_on(void)
{
    return fan_set_speed(CONFIG_FAN_PWM_DUTY_PERCENT);
}

int fan_off(void)
{
    if (g_fan_running) {
        uapi_pwm_close(PWM_CHANNEL);
    }
    fan_set_stop();
    fan_force_off_level();
    g_fan_running = 0;
    printf("Fan PWM OFF\r\n");
    return 0;
}

int fan_get_status(void)
{
    return g_fan_running;
}
