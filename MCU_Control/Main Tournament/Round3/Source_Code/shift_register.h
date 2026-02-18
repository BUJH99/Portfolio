/* ------------------------------------------------------------------------------------
   파 일 명: shift_register.h 
   내용설명: 시프트 레지스터 동작 함수 선언
   기능상세: 
   ------------------------------------------------------------------------------------ */


#ifndef SHIFT_REGISTER_H_
#define SHIFT_REGISTER_H_

#include <avr/io.h>
#include "pin.h"


void shift_register_write_8bit_led(uint8_t data);		// 시프트 레지스터 출력 함수
void shift_register_write_8bit_key(uint8_t data);


#endif /* SHIFT_REGISTER_H_ */

/* ---------------------------------------------------------------------------------- */