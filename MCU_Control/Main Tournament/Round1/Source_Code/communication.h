/* ------------------------------------------------------------------------------------
   파 일 명: communication.h
   내용설명: 통신을 위한 함수 선언
   기능상세: 
   ------------------------------------------------------------------------------------ */


#ifndef COMMUNICATION_H_
#define COMMUNICATION_H_

#include <avr/io.h>
#include <util/twi.h>
#include <stdlib.h>

// UART 통신 함수
void UART_init(void);
void UART_transmit(unsigned char data);
void UART_transmit_string(const char* data);
void UART_transmit_number(int number);
unsigned char UART_receive(void);

// I2C 통신 함수
void I2C_init(void);
void I2C_start(void);
uint8_t I2C_transmit(uint8_t data);
void I2C_transmit_string(const char *data);
uint8_t I2C_receive(void);
void I2C_stop(void);


#endif /* COMMUNICATION_H_ */

/* ---------------------------------------------------------------------------------- */