#ifndef __PWM_LAMP_H__
#define __PWM_LAMP_H__

#if defined(CONFIG_PWM_SUPPORT_LPM)
#include "pm_veto.h"
#endif
#include "common_def.h"
#include "pinctrl.h"
#include "pwm.h"
#include "gpio.h"
#include "tcxo.h"
#include "soc_osal.h"
#include "app_init.h"

#ifndef CONFIG_FAN_PWM_CHANNEL
#define CONFIG_FAN_PWM_CHANNEL     2
#endif

#ifndef CONFIG_FAN_PWM_GROUP_ID
#define CONFIG_FAN_PWM_GROUP_ID    0
#endif

#ifndef CONFIG_FAN_PWM_PIN
#define CONFIG_FAN_PWM_PIN         2
#endif

#ifndef CONFIG_FAN_PWM_PIN_MODE
#define CONFIG_FAN_PWM_PIN_MODE    1
#endif

#ifndef CONFIG_FAN_PWM_FREQ_HZ
#define CONFIG_FAN_PWM_FREQ_HZ     1000
#endif

#define TEST_TCXO_DELAY_20MS       20
#define TEST_TCXO_DELAY_50MS       50
#define TEST_TCXO_DELAY_100MS      100
#define TEST_TCXO_DELAY_1000MS     1000

#define PWM_TASK_PRIO              24
#define PWM_TASK_STACK_SIZE        0x1000

#define PWM_CHANNEL                CONFIG_FAN_PWM_CHANNEL
#define PWM_GROUP_ID               CONFIG_FAN_PWM_GROUP_ID
#define PWM_PIN                    CONFIG_FAN_PWM_PIN
#define PWM_PIN_MODE               CONFIG_FAN_PWM_PIN_MODE

#define PWM_BASE_CLOCK_HZ          24000000
#define PWM_DESIRED_FREQ_HZ        CONFIG_FAN_PWM_FREQ_HZ

#define BREATH_MIN_DUTY            5
#define BREATH_MAX_DUTY            95
#define BREATH_STEP                1
#define BREATH_CYCLE_COUNT         2

errcode_t pwm_init_module(void);
errcode_t pwm_setup_output(uint32_t freq, uint8_t duty);
void pwm_test_fixed_duty(void);
void pwm_start_breathing_effect(void);
void pwm_stop_breathing_effect(void);
void pwm_cleanup(void);
void pwm_print_info(void);

#endif
