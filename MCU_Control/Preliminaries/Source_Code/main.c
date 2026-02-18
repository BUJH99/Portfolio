/* ------------------------------------------------------------------------------------
   파 일 명: main.c
   내용설명: main 함수
   기능상세: 
   ------------------------------------------------------------------------------------ */


#include <avr/io.h>		

// 사용자 정의 헤더파일
#include "ADC.h"		// ADC설정 및 압력, thermistor, fan, 수위 조절 관련 함수가 있는 헤더파일
#include "motor.h"		// 스텝 모터 동작과 관련한 함수가 있는 헤더파일
#include "button.h"		// 버튼 동작에 관련한 함수가 있는 헤더파일
#include "delay.h"		// delay 함수를 직접 구현한 헤더파일
#include "led.h"		// 여러개의 led 를 적은 수의 핀으로 작동하기 위하여 shift register 를 이용하는 함수가 있는 헤더파일

// 수압, 시트온도, 온수온도 단계를 담는 변수 선언 및 초기화
uint8_t init_water_pressure_level = 0;
uint8_t init_seat_heat_level = 0;
uint8_t init_water_heat_level = 0;

uint8_t* water_pressure_level = &init_water_pressure_level;
uint8_t* seat_heat_level = &init_seat_heat_level;
uint8_t* water_heat_level = &init_water_heat_level;

// 버튼과 led 의 상태를 담는 변수 선언 및 초기화
uint8_t init_button_state = 0;
uint8_t init_led_state = 0;

uint8_t* button_state = &init_button_state;
uint16_t* led_state = &init_led_state;

// 모드를 담는 변수 선언 (button.h)
char init_value = 'S';    // 단일 문자 저장
char* current_mode = &init_value;    // 포인터가 mode_value를 가리키게 설정



/* ------------------------------------------------------------------------------------ 
   main 함수 
   ------------------------------------------------------------------------------------ */
#define F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>




int main(void) {
	// 포트 입출력 setting
	DDRB = 0x3F;						// D8~D13번 핀까지 출력 set
	DDRC = 0x0C;						// A2, A3번 핀 출력 set
	DDRD = 0xFC;						// D2~D7 번 핀까지 출력 set
	// 초기 setting
	*water_pressure_level = 1;			// 수압 초기화
	*seat_heat_level = 0;				// 시트 온도 초기화
	*water_heat_level = 0;				// 온수 온도 초기화
	*current_mode = 'S';				// 모드 초기화
	*button_state = 0;					// 버튼 상태 초기화
	*led_state = 0x0000;				// led 초기화
	
	// led 초기화
	shift_register_write(*led_state);	// shift register 를 이용하여 led 를 키는 함수
	
	/* 전원 ON 동안 계속 루프 -------------------------------------------------------------------- */
	while(1){
		// 사람이 앉았을 때
		if (is_pressure()) {
			/* 사람이 앉아있는 동안 계속 루프 --------------------------------------- */
			while(is_pressure()){									// 사람이 앉아있는 동안 계속 루프
				*button_state = get_button_chattering_fix();		// 버튼 상태 읽어오기
				switch(*button_state) {
					case 0: break;																					// 입력 없음
					case 1: button_bidet_function(current_mode, water_pressure_level); break;						// 비데 버튼
					case 2: button_wash_function(current_mode, water_pressure_level); break;						// 세정 버튼
					case 3: button_dry_function(current_mode); break;												// 온풍 버튼
					case 4: button_stop_function(current_mode); break;												// 정지 버튼
					case 5: button_nozzle_up_function(current_mode); break;											// 노즐 상승 버튼
					case 6: button_nozzle_down_function(current_mode); break;										// 노즐 하강 버튼
					case 7: button_water_pressure_function(current_mode, water_pressure_level, led_state); break;	// 수압 조절 버튼 LED 번호 0 1 2
					case 8: button_seat_heat_button_function(current_mode, seat_heat_level, led_state); break;		// 시트 온도 조절 버튼 3 4 5
					case 9: button_water_heat_function(current_mode, water_heat_level, led_state); break;			// 온수 온도 조절 버튼 6 7 8
					default: break;															   						// 예외 처리
				}
				control_seat_heater(seat_heat_level);				// 시트 히터 작동
				control_water_heater(water_heat_level);				// 온수 히터 작동
				maintain_water_level();								// 수위 유지 동작
			}
			/* 사람이 앉아있다 일어섰을 때 ------------------------------------------------- */
			init_water_pressure_motor();							// 수압 모터 초기화
			init_nozzle_motor();									// 노즐 모터 초기화
			turn_off_fan();											// 온풍 팬 off
			turn_off_seat_heater();									// 시트 히터 off
		}
		// 사람이 앉지 않았을 때 ------------------------------------------------- */
		control_water_heater(water_heat_level);						// 온수 히터 작동
		maintain_water_level();										// 수위 유지 동작
		delay_ms(1000);												// 1초 Delay (과도한 동작 방지)
	}
}


/* ---------------------------------------------------------------------------------- */