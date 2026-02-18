/*
 * matrix.h
 *
 * Created: 2024-11-20 오후 9:44:53
 *  Author: rohsw
 */ 


#ifndef MATRIX_H_
#define MATRIX_H_

#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>
#include <util/twi.h>
#include <avr/interrupt.h>
#include <stdio.h>

#include "communication.h"
#include "shift_register.h"

#define ROWS			5
#define COLS			8
#define MODULES_NUMBER	8  // 32x8 매트릭스는 4개의 8x8 매트릭스로 구성

// MAX7219 Registers Address
#define NOP         0x00
#define DIG0        0x01
#define DIG1        0x02
#define DIG2        0x03
#define DIG3        0x04
#define DIG4        0x05
#define DIG5        0x06
#define DIG6        0x07
#define DIG7        0x08
#define DECODE      0x09
#define INTENSITY   0x0A
#define SCAN_LIMIT  0x0B
#define SHUTDOWN    0x0C
#define TEST        0x0F

#define seg7_data0	0b00000011
#define seg7_data1	0b11110011
#define seg7_data2	0b00100101
#define seg7_data3	0b00001101
#define seg7_data4	0b10011001


extern uint8_t keysArr0[ROWS][COLS];
extern char keysArr1[ROWS][COLS];
extern char keysArr2[ROWS][COLS];

extern unsigned char Pattern[12][8];
extern unsigned char Pattern_init[8][8]; 

// SPI 마스터 초기화 함수
void SPI_MasterInit(void);

// SPI 데이터 전송 함수
void SPI_Transmit(unsigned char data);
void MAX7219_TOTAL(unsigned char address, unsigned char data);
void MAX7219_Init(void);
// MAX7219 LED
void MAX7219_Target(int Target, unsigned char address, unsigned char data);

void init_KeyMatrix(void);
void active_key_matrix(void);


#endif /* MATRIX_H_ */