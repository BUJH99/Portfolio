/*
 * led_blink.h
 *
 * Created: 2024-11-20 오전 11:35:46
 *  Author: rohsw
 */ 


#ifndef LED_BLINK_H_
#define LED_BLINK_H_

#include <avr/io.h>
#include <avr/interrupt.h>

#include "communication.h"
#include "pin.h"

volatile int led_count;
volatile int led_state;



void led_counter_init(void);
void led_blink_1sec(void);




#endif /* LED_BLINK_H_ */