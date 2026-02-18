/*
 * led_blink.c
 *
 * Created: 2024-11-20 오전 11:25:12
 *  Author: rohsw
 */ 

#include "led_blink.h"

void led_timer_init(void) {
	sei();
	led_state = 0;
	led_count = 0;							// count 값 초기화
	TCCR0B |= (1 << CS02) | (1 << CS00);	// 분주비 1024 설정
	TIMSK0 |= (1 << TOIE0);				// 오버플로 인터럽트 허용
}



ISR(TIMER0_OVF_vect) {
	cli();
	led_count++;
	if (led_count >= 64) {
		led_count = 0;
		led_state = !led_state;
		if (led_state) PORTB |= (1 << LED_BLINK_PIN);
		else PORTB &= ~(1 << LED_BLINK_PIN);
	}
	sei();
}