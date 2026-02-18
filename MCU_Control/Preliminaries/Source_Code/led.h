/* ------------------------------------------------------------------------------------
   파 일 명: led.h
   내용설명: led 를 제어하는 shift register 를 작동하는 함수 모음
   기능상세: 
   ------------------------------------------------------------------------------------ */


#ifndef LED_H_
#define LED_H_

// 사용자 정의 헤더파일
#include "delay.h"				// delay 함수를 직접 구현한 헤더파일

// shift register 동작 핀 정의
#define led_ds_pin PD2			// D2번핀
#define led_st_cp_pin PC2		// A2번핀
#define led_sh_cp_pin PC3		// A3번핀

/* ------------------------------------------------------------------------------------ 
   shift register 작동 함수 
   ------------------------------------------------------------------------------------ */

void shift_register_write(uint16_t data) {
    // 데이터의 각 비트를 클럭을 직접 제어하며 한 비트씩 전송
    for (uint16_t i = 0; i < 16; i++) {
		// 시프트 클럭 하강 edge
		PORTC &= ~(1 << led_sh_cp_pin);		// led_sh_cp_pin 핀을 LOW로 설정
		
        // 데이터의 MSB부터 LSB까지 차례대로 전송
        if (data & (1 << (15 - i))) {
            PORTD |= (1 << led_ds_pin);		// led_ds_pin 핀을 HIGH로 설정
        } else {
            PORTD &= ~(1 << led_ds_pin);	// led_ds_pin 핀을 LOW로 설정
        }

        // 시프트 클럭 상승 edge
        PORTC |= (1 << led_sh_cp_pin);		// led_sh_cp_pin 핀을 HIGH로 설정
        delay_ms(1);						// 약간의 지연
        
    }

    // 스토리지 클럭 상승 edge 와 하강 edge 를 통해 shift register 출력 핀으로 데이터 출력
    PORTC |= (1 << led_st_cp_pin);			// led_st_cp_pin 핀을 HIGH로 설정
    delay_ms(1);							// 약간의 지연
    PORTC &= ~(1 << led_st_cp_pin);			// led_st_cp_pin 핀을 LOW로 설정
}



#endif /* LED_H_ */
/* ---------------------------------------------------------------------------------- */