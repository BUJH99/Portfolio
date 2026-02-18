/* ------------------------------------------------------------------------------------
	파 일 명: motor.h 
	내용설명: 스텝 모터 동작과 관련한 함수 모음
	기능상세: 
------------------------------------------------------------------------------------ */
	
	
#ifndef MOTOR_H_
#define MOTOR_H_


#include <avr/io.h>

// 사용자 정의 헤더파일
#include "delay.h"											// delay 함수를 직접 구현한 헤더파일

// 노즐 모터 동작 핀 정의
#define nozzle_pin1 PD4										// D4 핀
#define nozzle_pin2 PD5		     							// D5 핀
#define nozzle_pin3 PD6										// D6 핀
#define nozzle_pin4 PD7										// D7 핀
#define except_nozzle_pins 0x0F								// 노즐 모터 동작 핀을 제외한 핀
#define nozzle_pins 0xF0									// 노즐 모터 동작 핀

// 수압 모터 동작 핀 정의
#define water_pressure_pin1 PB2								// D10 핀
#define water_pressure_pin2 PB3								// D11 핀
#define water_pressure_pin3 PB4								// D12 핀
#define water_pressure_pin4 PB5								// D13 핀
#define except_water_pressure_pins 0xC3						// 수압 모터 동작 핀을 제외한 핀
#define water_pressure_pins 0x3C							// 수압 모터 동작 핀

// 스텝 모터 관련 상수 정의
#define minimum_steps 256									// 2048스텝당 1바퀴이므로 45도를 최소로 잡음
#define upper_limit_nozzle_motor_step 1280					// 노즐 모터 위치 조정 상한선
#define lower_limit_nozzle_motor_step 256					// 노즐 모터 위치 조정 하한선
#define bidet_nozzle_motor_steps 1024						// 비데 모드 노즐 기본 위치
#define wash_nozzle_motor_steps 512							// 세정 모드 노즐 기본 위치
#define DELAY_BETWEEN_STEPS 3								// 1step당 최소 간격이 3ms

// 스텝 모터 변수 정의, 초기화
int current_nozzle_motor_steps = 0;							// 현재 노즐 모터 돌아간 스텝 수
int current_water_pressure_motor_steps = 0;					// 현재 수압 모터 돌아간 스텝 수

int array_water_pressure_motor_step[3] = {512, 1024, 1536};	// 수압 단계별 스텝 수를 담은 배열
	
	
/* ------------------------------------------------------------------------------------ 
	노즐 스텝 모터 동작 함수 
	------------------------------------------------------------------------------------ */


// 노즐 위치 전진 함수
void forward_nozzle_motor(int steps) {
	// 스텝 모터 동작을 위한 배열 및 변수 선언
	char front[4] = {0x80,0x40,0x20,0x10};
	int temp;
	
	// steps 만큼 반복하여 노즐 모터 앞으로 동작
	for(int i = 0; i < steps; i++){
		temp=i%4;
		PORTD = (PORTD & except_nozzle_pins)
			| ((1 << nozzle_pin1 & front[temp])	
			| (1 << nozzle_pin2 & front[temp])	
			| (1 << nozzle_pin3 & front[temp])	
			| (1 << nozzle_pin4 & front[temp]));			// 배열을 이용하여 스텝 모터 동작
			
		current_nozzle_motor_steps++;						// 현재 노즐 모터 스텝 수를 증가하여 저장
		delay_ms(DELAY_BETWEEN_STEPS);						// 모터 동작을 위한 최소한의 delay
	}
	PORTD &= except_nozzle_pins;							// 노즐 핀 초기화
}

// 노즐 위치 후진 함수
void backward_nozzle_motor(int steps) {
	// 스텝 모터 동작을 위한 배열 및 변수 선언
	char back[4] = {0x10,0x20,0x40,0x80};
	int temp;
	
	// steps 만큼 반복하여 노즐 모터 뒤로 동작
	for(int i = 0; i < steps; i++){
		temp=i%4;
		PORTD = (PORTD & except_nozzle_pins)
			| ((1 << nozzle_pin1 & back[temp])
			| (1 << nozzle_pin2 & back[temp])
			| (1 << nozzle_pin3 & back[temp])
			| (1 << nozzle_pin4 & back[temp]));				// 배열을 이용하여 스텝 모터 동작
			
		current_nozzle_motor_steps--;						// 현재 노즐 모터 스텝 수를 감소하여 저장
		delay_ms(DELAY_BETWEEN_STEPS);						// 모터 동작을 위한 최소한의 delay
	}
	PORTD &= except_nozzle_pins;							// 노즐 핀 초기화
}


// 비데 모드 노즐 기본 위치 조정 함수
void control_bidet_nozzle_motor() {
	if(current_nozzle_motor_steps < bidet_nozzle_motor_steps) {
		forward_nozzle_motor(bidet_nozzle_motor_steps - current_nozzle_motor_steps);	// 노즐이 비데모드 기본 위치보다 적게 나와있는 경우 그만큼 앞으로 이동
	} else if (current_nozzle_motor_steps > bidet_nozzle_motor_steps) {
		backward_nozzle_motor(current_nozzle_motor_steps - bidet_nozzle_motor_steps);	// 노즐이 비데모드 기본 위치보다 많이 나와있는 경우 그만큼 뒤로 이동
	}
}

// 세정 모드 노즐 기본 위치 조정 함수
void control_wash_nozzle_motor() {
	if(current_nozzle_motor_steps < wash_nozzle_motor_steps) {
		forward_nozzle_motor(wash_nozzle_motor_steps - current_nozzle_motor_steps);		// 노즐이 세정모드 기본 위치보다 적게 나와있는 경우 그만큼 앞으로 이동
	} else if (current_nozzle_motor_steps > wash_nozzle_motor_steps) {
		backward_nozzle_motor(current_nozzle_motor_steps - wash_nozzle_motor_steps);	// 노즐이 세정모드 기본 위치보다 많이 나와있는 경우 그만큼 뒤로 이동
	}
}

// 노즐 위치 상승 조정 함수
void control_nozzle_motor_forward() {
	if (current_nozzle_motor_steps < upper_limit_nozzle_motor_step) {
		forward_nozzle_motor(minimum_steps);											// 노즐 모터 상한선보다 적게 나와있는 경우에만 45도 만큼 앞으로 상승
	}
}

// 노즐 위치 하강 조정 함수
void control_nozzle_motor_backward() {
	if (current_nozzle_motor_steps > lower_limit_nozzle_motor_step) {
		backward_nozzle_motor(minimum_steps);											// 노즐 모터 하한선보다 많이 나와있는 경우에만 45도 만큼 앞으로 상승
	}
}

// 노즐 위치를 초기 상태로 되돌리는 함수
void init_nozzle_motor() {																		// 노즐 모터가 앞으로 나와있는 경우
	if (current_nozzle_motor_steps > 0) { backward_nozzle_motor(current_nozzle_motor_steps); }	// 현재 노즐 모터 스텝 수만큼 뒤로 작동
	else { current_nozzle_motor_steps = 0;}														// 예외처리
}



/* ------------------------------------------------------------------------------------ 
	수압 조절 스텝 모터 동작 함수
	------------------------------------------------------------------------------------ */


// 수압 상승 함수
void forward_water_pressure_motor(int steps) {
	// 스텝 모터 동작을 위한 배열 및 변수 선언
	char front[4] = {0x20,0x10,0x08,0x04};
	int temp;
	
	// steps 만큼 반복하여 수압 모터 앞으로 동작
	for(int i = 0; i < steps; i++){
		temp=i%4;
		PORTB = (PORTB & except_water_pressure_pins)
			| ((1 << water_pressure_pin1 & front[temp])
			| (1 << water_pressure_pin2 & front[temp])
			| (1 << water_pressure_pin3 & front[temp])
			| (1 << water_pressure_pin4 & front[temp]));	// 배열을 이용하여 스텝 모터 동작
			
		current_water_pressure_motor_steps++;				// 현재 수압 모터 스텝 수를 감소하여 저장
		delay_ms(DELAY_BETWEEN_STEPS);						// 모터 동작을 위한 최소한의 delay
	}
	PORTB &= except_water_pressure_pins;					// 수압 핀 초기화
}

// 수압 하강 함수
void backward_water_pressure_motor(int steps) {
	// 스텝 모터 동작을 위한 배열 및 변수 선언
	char back[4] = {0x04,0x08,0x10,0x20};
	int temp;
	
	// steps 만큼 반복하여 수압 모터 뒤로 동작
	for(int i = 0; i < steps; i++){
		temp=i%4;
		PORTB = (PORTB & except_water_pressure_pins)
			| ((1 << water_pressure_pin1 & back[temp])
			| (1 << water_pressure_pin2 & back[temp])
			| (1 << water_pressure_pin3 & back[temp])
			| (1 << water_pressure_pin4 & back[temp]));		// 배열을 이용하여 스텝 모터 동작
			
		current_water_pressure_motor_steps--;				// 현재 수압 모터 스텝 수를 감소하여 저장
		delay_ms(DELAY_BETWEEN_STEPS);						// 모터 동작을 위한 최소한의 delay
	}
	PORTB &= except_water_pressure_pins;					// 수압 핀 초기화
}

// 수압 설정값에 맞게 스텝 모터를 작동시키는 함수
void control_water_pressure_motor(uint8_t water_pressure_level) {
	// 수압 단계별 스텝 수를 담은 배열로부터 현재 수압 단계에 맞는 스텝 수를 읽어와서 변수에 저장
	int target_motor_steps = array_water_pressure_motor_step[water_pressure_level];
	
	if (current_water_pressure_motor_steps < target_motor_steps) {
		forward_water_pressure_motor(target_motor_steps - current_water_pressure_motor_steps);		// 현재 수압이 수압 설정값보다 낮은 경우 그만큼 모터를 앞으로 작동
	} else if (current_water_pressure_motor_steps > target_motor_steps) {
		backward_water_pressure_motor(current_water_pressure_motor_steps - target_motor_steps);		// 현재 수압이 수압 설정값보다 높은 경우 그만큼 모터를 뒤로 작동
	}
}


// 수압 스텝 모터를 초기 상태로 되돌리는 함수
void init_water_pressure_motor() {
	if (current_water_pressure_motor_steps > 0) {													// 수압 모터가 앞으로 나와있는 경우 (물이 나오고 있는 상태)
		backward_water_pressure_motor(current_water_pressure_motor_steps);							// 현재 수압 모터 스텝 수만큼 뒤로 작동
	} else {
		current_water_pressure_motor_steps = 0;														// 예외처리
	}															
}



	#endif /* MOTOR_H_ */
	/* ---------------------------------------------------------------------------------- */