/*
 * key_matrix.c
 *
 * Created: 2024-11-20 (수) 오전 11:57:37
 * Author : chamna
 */ 

#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>
#include <stdint.h>

#include "communication.h"
#include "shift_register.h"
#include "pin.h"
#include "led_blink.h"
#include "matrix.h"



void main_init(void) {
	sei();
	DDRB |= (1 << LED_SH_CP_PIN | 1 << LED_BLINK_PIN);
	DDRC |= (1 << LED_ST_CP_PIN | 1 << LED_DS_PIN | 1 << KEY_DS_PIN);
	DDRD |= (1 << KEY_SH_CP_PIN | 1 << KEY_ST_CP_PIN);
	led_timer_init();
}


int main(void){
	main_init();
	UART_init();
	
	while(1)
	{
		active_key_matrix();
		WS2812_send(led_current_color, LED_COUNT);
	}
}