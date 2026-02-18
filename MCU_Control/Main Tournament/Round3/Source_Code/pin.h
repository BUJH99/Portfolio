/* ------------------------------------------------------------------------------------
   파 일 명: pin.h
   내용설명: 사용하는 핀 정의
   기능상세: 
   ------------------------------------------------------------------------------------ */


#ifndef PIN_H_
#define PIN_H_

#define LED_DS_PIN			PC5					// 시프트 레지스터 데이터 핀
#define LED_SH_CP_PIN		PB0					// 시프트 레지스터 클럭 핀
#define LED_ST_CP_PIN		PC4					// 스토리지 레지스터 클럭 핀
#define LED_BLINK_PIN		PB1					// led_blink 출력핀

#define KEY_DS_PIN			PC3
#define KEY_SH_CP_PIN		PD6
#define KEY_ST_CP_PIN		PD7

#define KEY_ROW_PIN1		PC2					// 
#define KEY_ROW_PIN2		PD4					// 
#define KEY_ROW_PIN3		PD3					// 
#define KEY_ROW_PIN4		PD2					// 
#define KEY_ROW_PIN5		PD5					// 

// SPI 통신에 사용되는 핀 정의
#define DD_MOSI				PB3					// MOSI(Master Out Slave In) = DIN이랑 연결
#define DD_MISO				PB4					// MISO(Master In Slave Out)
#define DD_SCK				PB5					// SCK(Serial Clock)
#define DD_SS				PB2					// SS(Slave Select)


// 미사용
#define PWM_PIN				PD3					// PWM 출력 핀
#define I2C_SDA_PIN			PC4					// I2C 통신을 위한 SDA핀
#define I2C_SCL_PIN			PC5					// I2C 통신을 위한 SCL핀


#endif /* PIN_H_ */

/* ---------------------------------------------------------------------------------- */