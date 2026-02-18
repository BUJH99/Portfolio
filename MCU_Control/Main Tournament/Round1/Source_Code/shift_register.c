/* ------------------------------------------------------------------------------------
   파 일 명: shift_register.h 
   내용설명: 시프트 레지스터 동작 함수 정의
   기능상세: 
   ------------------------------------------------------------------------------------ */


#include "shift_register.h"

// 8비트 데이터를 시프트 레지스터를 이용하여 전송
void shift_register_write_8bit_led(uint8_t data) {
	for (uint8_t i = 0; i < 8; i++) {
		// 데이터의 MSB부터 LSB까지 차례대로 전송
		if (data & ( 1 << (7-i) ))
			PORTC |= (1 << LED_DS_PIN);			// 포트 위치에 따라 수정
		else
			PORTC &= ~(1 << LED_DS_PIN);		// 포트 위치에 따라 수정

		// 시프트 레지스터 클럭 파형 생성
		PORTB |= (1 << LED_SH_CP_PIN);			// 포트 위치에 따라 수정
		PORTB &= ~(1 << LED_SH_CP_PIN);			// 포트 위치에 따라 수정
	}

	// 스토리지 레지스터 클럭 파형 생성
	PORTC |= (1 << LED_ST_CP_PIN);				// 포트 위치에 따라 수정
	PORTC &= ~(1 << LED_ST_CP_PIN);				// 포트 위치에 따라 수정
}

// 8비트 데이터를 시프트 레지스터를 이용하여 전송
void shift_register_write_8bit_key(uint8_t data) {
	for (uint8_t i = 0; i < 8; i++) {
		// 데이터의 MSB부터 LSB까지 차례대로 전송
		if (data & ( 1 << (7-i) ))
		PORTC |= (1 << KEY_DS_PIN);			// 포트 위치에 따라 수정
		else
		PORTC &= ~(1 << KEY_DS_PIN);		// 포트 위치에 따라 수정

		// 시프트 레지스터 클럭 파형 생성
		PORTD |= (1 << KEY_SH_CP_PIN);			// 포트 위치에 따라 수정
		PORTD &= ~(1 << KEY_SH_CP_PIN);			// 포트 위치에 따라 수정
	}

	// 스토리지 레지스터 클럭 파형 생성
	PORTD|= (1 << KEY_ST_CP_PIN);				// 포트 위치에 따라 수정
	PORTD &= ~(1 << KEY_ST_CP_PIN);				// 포트 위치에 따라 수정
}
/* ---------------------------------------------------------------------------------- */