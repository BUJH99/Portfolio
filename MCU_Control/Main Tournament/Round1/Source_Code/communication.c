 /* ------------------------------------------------------------------------------------
   파 일 명: communication.c
   내용설명: 통신을 위한 함수 정의
   기능상세: 
   ------------------------------------------------------------------------------------ */


#include "communication.h"

/* ------------------------------------------------------------------------------------ 
   UART 통신 함수 
   ------------------------------------------------------------------------------------ */

// UART 통신 초기 설정 함수
void UART_init(void) {
	UCSR0A |= (1 << U2X0);										// 비동기 2배속 설정
	UBRR0H = 0x00;												// 보율(Baud rate) 설정
	UBRR0L = 207;												// 보율(Baud rate) 설정
	UCSR0B |= (1 << RXEN0) | (1 << TXEN0);						// 송신기 및 수신기 활성화
	UCSR0C = 0x06;												// 비동기 & parityX & 8bit 데이터 통신 설정
}

// UART 데이터 송신 함수
void UART_transmit(unsigned char data) {
	while( !(UCSR0A & (1 << UDRE0)) );							// 송신 가능해질 때까지 대기
	UDR0 = data;												// 송신 버퍼에 있는 데이터 송신
}

// UART 문자열 데이터 송신 함수
void UART_transmit_string(const char* data) {
	while (*data != '\0') {
		UART_transmit((unsigned char)*data);
		data++;
   }
}

void UART_transmit_number(int number) {
	char buffer[12]; // 숫자를 문자열로 변환하기 위한 버퍼
	itoa(number, buffer, 10); // 숫자를 문자열로 변환 (10진수)
	UART_transmit_string(buffer); // 문자열을 UART로 전송
}

// UART 데이터 수신 함수
unsigned char UART_receive(void) {
	while( !(UCSR0A & (1 << RXC0)) );							// 수신 가능해질 때까지 대기
	return UDR0;												// 수신된 데이터값 반환
}

/* ------------------------------------------------------------------------------------ 
   I2C 통신 함수 
   ------------------------------------------------------------------------------------ */


void I2C_init(void) {
	TWBR = 32;														// I2C clock 주파수 200KHz 설정
	TWCR = (1 << TWEN) | (1 << TWEA);								// I2C 활성화, ACK 허용
}

void I2C_start(void) {
	TWCR = (1 << TWINT) | (1 << TWSTA) | (1 << TWEN) | (1 << TWEA);	// 시작 신호 전송
	while( !(TWCR & (1 << TWINT)) );								// 완료 대기
}

uint8_t I2C_transmit(uint8_t data) {	
	TWDR = data;													// 송신 버퍼에 데이터 올리기
	TWCR = (1 << TWINT) | (1 << TWEN) | (1 << TWEA);				// 송신 시작
	while( !(TWCR & (1 << TWINT)) );
	return (TWSR & 0xF8);											// 상태 반환
}

void I2C_transmit_string(const char *data) {
	while (*data) {
		if (I2C_transmit((uint8_t)*data) != TW_MT_DATA_ACK) {
			break;													// 데이터 ACK 실패 시 중단
		}
		data++;
   }
}

uint8_t I2C_receive(void) {
	TWCR = (1 << TWINT) | (1 << TWEN) | (1 << TWEA);				// 수신 시작
	while( !(TWCR & (1 << TWINT)) );								// 완료 대기
	return TWDR;													// 수신 데이터 반환
}

void I2C_stop(void) {
	TWCR = (1 << TWINT) | (1 << TWSTO) | (1 << TWEN) | (1 << TWEA);	// 정지 신호 전송
}

/* ---------------------------------------------------------------------------------- */