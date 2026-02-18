/* ------------------------------------------------------------------------------------
   파 일 명: button.h 
   내용설명: 버튼 동작에 관련한 함수 모음
   기능상세: 
   ------------------------------------------------------------------------------------ */


#ifndef BUTTON_H_
#define BUTTON_H_


#include <avr/io.h>

// 사용자 정의 헤더파일
#include "ADC.h"				// ADC설정 및 압력, thermistor, fan, 수위 조절 관련 함수 가 있는 헤더파일
#include "motor.h"				// 스텝 모터 동작과 관련한 함수 가 있는 헤더파일
#include "delay.h"				// delay 함수를 직접 구현한 헤더파일

// 핀 정의
#define BUTTON_PIN 0			// A0핀, 버튼값을 읽기 위한 핀

// 상수 정의
#define CHATTERING_READY_MS 50	// 채터링 방지를 위한 대기 시간(ms)

/* ------------------------------------------------------------------------------------ 
   버튼 입력 함수 
   ------------------------------------------------------------------------------------ */

// 버튼에 해당하는 값(0~9) 를 반환하는 함수
int get_button() {
	// ADC 초기화
	ADC_INIT();
	
	// 변수의 선언과 초기화
	int adcValue = 0;						// 0~1023의 값을 갖는 ADC값을 받을 변수
	
	// 버튼핀에 걸리는 전압값 ADC 변환하여 읽기
	adcValue = ADC_READ(BUTTON_PIN);

	if (adcValue < 80)	return 0;			// 버튼 X			실험값:5
	else if (adcValue < 167) return 1;		// 버튼 세정			실험값:111
	else if (adcValue < 278) return 2;		// 버튼 비데			실험값:222
	else if (adcValue < 389) return 3;		// 버튼 온풍			실험값:333
	else if (adcValue < 500) return 4;		// 버튼 정지			실험값:444
	else if (adcValue < 611) return 5;		// 버튼 노즐 상승		실험값:555
	else if (adcValue < 722) return 6;		// 버튼 노즐 하강		실험값:666
	else if (adcValue < 832) return 7;		// 버튼 수압			실험값:780
	else if (adcValue < 956) return 8;		// 버튼 시트			실험값:900
	else return 9;							// 버튼 온수			실험값:1023
}

// 버튼 채터링을 방지하여 값을 반환하는 함수
int get_button_chattering_fix() {
	
	int button = get_button();			// 버튼에 해당하는 값(0~9)를 가져와서 저장
	delay_ms(CHATTERING_READY_MS);		// 채터링을 방지하기 위해 잠시 기다림
	if(get_button() == button) {		// 잠시 기다린 후에도 같은 상태라면 아직 눌려있거나, 애초에 눌리지 않았던 경우
		while(get_button() != 0);		// 버튼을 다시 뗄 때까지 대기, 애초에 눌리지 않았으면 바로 값 반환
		return button;					// 값 반환
	}
	return button;						// 잠시 기다리는 와중에 버튼을 떼었다고 판단하고 값 반환
}

/* ------------------------------------------------------------------------------------ 
   버튼 입력에 따른 작동 함수 
   ------------------------------------------------------------------------------------ */

// 비데 버튼 작동 함수
void button_bidet_function(char* current_mode, uint8_t* water_pressure_level) {
	if (*current_mode != 'B'){									// 모드 버튼 중복 방지
		turn_off_fan();											// 온풍 팬 중단
		control_bidet_nozzle_motor();							// 노즐 (비데 기본세팅)
		control_water_pressure_motor(*water_pressure_level);	// 수압 (현재 수압)        
		*current_mode = 'B';									// 현재 모드 -> 비데
	}
}

// 세정 버튼 작동 함수
void button_wash_function(char* current_mode, uint8_t* water_pressure_level) {
	if (*current_mode != 'W'){									// 모드 버튼 중복 방지
		turn_off_fan();											// 온풍 팬 중단
		control_wash_nozzle_motor();							// 노즐 (세정 기본세팅)
		control_water_pressure_motor(*water_pressure_level);	// 수압 (현재 수압)
		*current_mode = 'W';									// 현재 모드 -> 세정
	}
}

// 온풍 버튼 작동 함수
void button_dry_function(char* current_mode) {
	if (*current_mode != 'D'){									// 모드 버튼 중복 방지
		init_water_pressure_motor();							// 수압 모터 초기화
		init_nozzle_motor();									// 노즐 모터 초기화
		turn_on_fan();											// 온풍 팬 가동
		*current_mode = 'D';									// 현재 모드 -> 온풍
	}
}

// 정지 버튼 작동 함수
void button_stop_function(char* current_mode) {
	if (*current_mode != 'S'){									// 모드 버튼 중복 방지
		turn_off_fan();											// 온풍 팬 중단
		init_water_pressure_motor();							// 수압 모터 초기화
		init_nozzle_motor();									// 노즐 모터 초기화
		*current_mode = 'S';									// 현재 모드 -> 정지
	}
}

// 노즐 상승 버튼 작동 함수
void button_nozzle_up_function(char* current_mode) {
	if (*current_mode == 'B' || *current_mode == 'W') {			// 비데, 세정 모드일때만 작동
		control_nozzle_motor_forward();							// 노즐 상승 코드
	}
}

// 노즐 하강 버튼 작동 함수
void button_nozzle_down_function(char* current_mode) {
	if (*current_mode == 'B' || *current_mode == 'W') {			// 비데, 세정 모드일때만 작동
		control_nozzle_motor_backward();						// 노즐 하강 코드
	}
}

// 수압 버튼 작동 함수(수압 led 동작)
void button_water_pressure_function(char* current_mode, uint8_t* water_pressure_level, uint8_t* led_state) {
	if (*current_mode == 'B' || *current_mode == 'W') {						// 비데, 세정 모드일때만 작동
		*water_pressure_level = (*water_pressure_level + 1) % 3;			// 수압 단계 상승 (0~2단계 존재)
		control_water_pressure_motor(*water_pressure_level);				// 수압 단계에 따른 스텝 모터 작동
		
		*led_state = (*led_state & 0xF8) | (1 << *water_pressure_level);	// 수압 버튼에 해당하는 led 핀만 HIGH 하도록 데이터 설정
		shift_register_write(*led_state);									// shift register 를 이용하여 led 를 키는 함수
	}
}
	
// 시트 온도 버튼 작동 함수(시트 온도 led 동작)
void button_seat_heat_button_function(char* current_mode, uint8_t* seat_heat_level, uint8_t* led_state) {
	*seat_heat_level = (*seat_heat_level + 1) % 4;							// 시트 온도 단계 상승 (0~3단계 존재)
	
	if (*seat_heat_level == 0) {											// 시트 온도 단계가  0일때
		*led_state = (*led_state & 0xC7);									// 시트 온도 버튼에 해당하는 led 핀 전부 LOW 하도록 데이터 설정
		shift_register_write(*led_state);									// shift register 를 이용하여 led 를 키는 함수
		
	} else {																// 시트 온도 단계가 1~3일때
		*led_state = (*led_state & 0xC7) | (1 << (*seat_heat_level + 2));	// 시트 온도 버튼에 해당하는 led 핀만 HIGH 하도록 데이터 설정
		shift_register_write(*led_state);									// shift register 를 이용하여 led 를 키는 함수
	}
}

// 온수 온도 버튼 작동 함수(온수 온도 led 동작)
void button_water_heat_function(char* current_mode, uint8_t* water_heat_level, uint8_t* led_state) {
	*water_heat_level = (*water_heat_level + 1) % 4;						// 온수 온도 단계 상승 (0~3단계 존재)
	if (*water_heat_level == 0) {											// 온수 온도 단계가  0일때
		*led_state = (*led_state & 0x3F);									// 온수 온도 버튼에 해당하는 led 핀 전부 LOW 하도록 데이터 설정
		shift_register_write(*led_state);									// shift register 를 이용하여 led 를 키는 함수
		
	} else {																// 온수 온도 단계가 1~3일때
		*led_state = (*led_state & 0x3F) | (1 << (*water_heat_level + 5));	// 온수 온도 버튼에 해당하는 led 핀만 HIGH 하도록 데이터 설정
		shift_register_write(*led_state);									// shift register 를 이용하여 led 를 키는 함수
	}
}


#endif /* BUTTON_H_ */
/* ---------------------------------------------------------------------------------- */