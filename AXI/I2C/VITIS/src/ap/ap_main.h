#ifndef SRC_AP_AP_MAIN_H_
#define SRC_AP_AP_MAIN_H_

#include <stdint.h>

#include "../driver/Button/Button.h"
#include "../driver/LED/LED.h"
#include "../driver/Switch/Switch.h"
#include "../HAL/I2C/I2C.h"

void ap_init();
void ap_execute();

#endif /* SRC_AP_AP_MAIN_H_ */
