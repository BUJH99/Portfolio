/*
 * led_blink.c
 *
 * Created: 2024-11-20 오전 11:25:12
 *  Author: rohsw
 */ 

#include "led_blink.h"

void led_counter_init(void) {
	led_state = 0;
	led_count = 0;							// count 값 초기화
	TCCR0A |= (1 << WGM01);					// CTC 모드 설정
	TCCR0B |= (1 << CS02) | (1 << CS00);	// 분주비 1024 설정
	OCR0A = 128;							// 기준값
	TIMSK0 |= (1 << OCIE0A);				// OCR0A와 TCNT0 비교 인터럽트 허용
}


void led_blink_1sec(void) {
	if (led_count >= 122) {
		led_count = 0;
		led_state = !led_state;
		if (led_state) {
			PORTB |= (1 << LED_BLINK_PIN);
			UART_transmit('y');
		}
		else {
			(PORTB &= ~(1 << LED_BLINK_PIN));
			UART_transmit('n');
		}
		
		//reduce_wave_dot_matrix();
	}
}

ISR(TIMER0_COMPA_vect) {
	led_count++;
}