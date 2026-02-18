/* ------------------------------------------------------------------------------------
   파 일 명: ADC.h 
   내용설명: ADC설정 및 압력, thermistor, fan, 수위 조절 관련 함수 모음
   기능상세: 
   ------------------------------------------------------------------------------------ */


#ifndef ADC_H_
#define ADC_H_


#include <avr/io.h>
#include <math.h>						// thermistor 를 통한 온도 계산을 위한 헤더파일

// 사용자 정의 헤더파일
#include "delay.h"						// 함수를 직접 구현한 헤더파일

// 입력 핀
#define PRESSURE_PIN 4					// A4 핀, 압력 입력 핀 설정 
#define WATER_LEVEL_PIN 5				// A5 핀, 수위 입력 핀 설정 
#define THERMISTOR_PIN 1				// A1 핀, 온도저항 핀 설정
// 출력 핀
#define WATER_LEVEL_LED_PIN PD3			// D3 핀, 수위 led 핀 설정
#define HEATER_PIN PB0					// D8 핀, 히터 핀 설정
#define FAN_PIN PB1						// D9 핀, fan 핀 설정

// thermistor 관련 상수
#define BETA 3435.0						// B parameter equation 의 베타 상수
#define TEMPERATURE25_KELVIN 298.15		// 25도일때의 캘빈값
#define R0 10000.0						// thermistor 의 25도 일때의 저항값
#define R1 10000.0						// thermistor 와 직렬 연결된 저항

// 상수 정의
#define WATER_LEVEL_THRESHOLD 250		// 수위 센서의 임계값
#define PRESSURE_THRESHOLD 512			// 압력 센서의 임계값

// 시트 온도 설정값
int Temperature[4] = {0, 30, 40, 50};	// 0단계 -> 시트X, 1단계 -> 30도설정, 2단계 -> 40도 설정, 3단계 -> 50도 설정




/* ------------------------------------------------------------------------------------ 
   ADC 동작 함수 
   ------------------------------------------------------------------------------------ */

// ADC 초기화
void ADC_INIT(){
	ADMUX = (1 << REFS0);							// ADMUX REG의 REFS BITS를 01로 설정(AVCC 사용)
	ADCSRA = (1 << ADEN) | 0b00000111;				// ADEN => ADC활성화, ADPS => 128분주비 설정
}

// ADC 활성화
uint16_t ADC_READ(uint8_t input_pin){
	ADMUX = (ADMUX & 0xF0) | (0x0F & input_pin);	// ADMUX의 ANALOG CHANNEL SELECTION BITS 설정
	ADCSRA |= (1 << ADSC);							// ADC 변환 시작
	
	while(ADCSRA & (1 << ADSC));					// ADC 변환이 끝날때까지 대기
	uint16_t ADC_VALUE = ADCL;						// ADCL 부분을 ADC_VALUE에 저장
	ADC_VALUE |= (ADCH << 8);						// ADCH 부분을 8비트만큼 shift left 해서 ADC_VALUE에 저장
	
	return ADC_VALUE;								// ADC_VALUE 반환
}


/* ------------------------------------------------------------------------------------ 
   압력과 수위 조절 함수 
   ------------------------------------------------------------------------------------ */

// 압력 체크 함수
uint8_t is_pressure() {											// 압력이 임계치 초과이면 1, 이하이면 0 반환
	// ADC 초기화
	ADC_INIT();
	return ADC_READ(PRESSURE_PIN) > PRESSURE_THRESHOLD ? 1 : 0;	// ADC입력을 받아서 임계값 이상이면 1, 이하이면 0 반환
}

// 수위 유지 함수
void maintain_water_level() {
	// ADC 초기화
	ADC_INIT();
	
	if(ADC_READ(WATER_LEVEL_PIN) > WATER_LEVEL_THRESHOLD )		// 수위가 임계치 초과일때 led on
	{
		// 물 보충하는 프로세스 시작 //
		PORTD |= (1 << WATER_LEVEL_LED_PIN);					// 수위 led on
	} else {
		PORTD &= ~(1 << WATER_LEVEL_LED_PIN);					// 수위 led off
	}
}



/* ------------------------------------------------------------------------------------ 
   thermistor 를 이용한 온도 조절 함수 
   ------------------------------------------------------------------------------------ */

// thermistor 온도를 읽고 반환하는 함수
int get_temperature() {
	// ADC 초기화
	ADC_INIT();
	
	// 변수의 선언과 초기화
	uint16_t adcValue = 0;					// 0~1023의 값을 갖는 ADC값을 받을 변수
	float resistance = 0.0;					// 저항값을 저장할 변수
	float temperature = 0.0;				// 온도값을 저장할 변수
	
	// ADC 활성화
	adcValue = ADC_READ(THERMISTOR_PIN);	// 채널 선택
	
	// ADC값을 통해 온도값 계산
	if (adcValue == 0.0) {
		return 999;							// 오류 처리
	} else {
		resistance = (1023.0 * R1) / (float)adcValue - R1;											// voltage divider 를 통한 저항값 계산
		temperature = 1.0 / (1.0 / TEMPERATURE25_KELVIN + log(resistance / R0) / BETA ) - 273.15;	// B 파라미터방정식을 통한 온도 계산
		return (int)temperature;																	// 정수로 변환해서 반환
	}
}

// 시트 히터 가동
void turn_on_seat_heater() {
	PORTB |= (1 << HEATER_PIN);				// HEATER_PIN 핀을 HIGH로 설정
}

// 시트 히터 중단
void turn_off_seat_heater() {
	PORTB &= ~(1 << HEATER_PIN);			// HEATER_PIN 핀을 LOW로 설정
}

// 목표 온도에 도달할 때까지 시트 히터 제어하는 함수
void control_seat_heater(uint8_t* target_temperature_level) {
	// thermistor 온도 읽기
	int current_temperature = get_temperature();	
	
	// 캡톤 필름 히터 동작 여부 판단
	if (current_temperature < Temperature[*target_temperature_level]) {	// 현재 시트 온도가 목표 온도보다 낮은 경우 
		turn_on_seat_heater();											// 시트 히터 가동
		
	} else {															// 현재 시트 온도가 목표 온도 이상인 경우
		turn_off_seat_heater();											// 시트 히터 중단
	}
}

// 목표 온도에 도달할 때까지 온수 히터 제어
void control_water_heater(uint8_t* target_temperature_level) {
	/*
		시트 히터만 구현하고, 온수 히터는 중복되므로 구현하지 않았음
	*/
}



/* ------------------------------------------------------------------------------------ 
   온풍 팬 작동 함수 
   ------------------------------------------------------------------------------------ */

// 온풍 팬 가동 함수
void turn_on_fan() {
	PORTB |= (1 << FAN_PIN);				// FAN_PIN 핀을 HIGH로 설정
}

// 온풍 팬 중단 함수
void turn_off_fan() {
	PORTB &= ~(1 << FAN_PIN);				// FAN_PIN 핀을 LOW로 설정
}

#endif /* ADC_H_ */
/* ---------------------------------------------------------------------------------- */