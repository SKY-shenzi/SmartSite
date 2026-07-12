#ifndef CEMENT_FAN_H
#define CEMENT_FAN_H

#include <stdint.h>

int fan_init(void);
int fan_on(void);
int fan_off(void);
int fan_set_speed(uint8_t duty);
int fan_get_status(void);

#endif
