/* ------------------------------------------------------------------------------------
   파 일 명: communication.h
   내용설명: 통신을 위한 함수 선언
   기능상세: 
   ------------------------------------------------------------------------------------ */


#ifndef COMMUNICATION_H_
#define COMMUNICATION_H_

#define F_CPU			16000000UL
#define BAUD			31250

#include <avr/io.h>
#include <util/twi.h>
#include <stdlib.h>
#include <util/delay.h>


#define LED_COUNT		22

extern uint8_t led_color_init[LED_COUNT][3];
extern uint8_t led_current_color[LED_COUNT][3];

// UART 통신 함수
void UART_init(void);
void UART_transmit(uint8_t data);
unsigned char UART_receive(void);
void MIDI_ON(uint8_t MIDI_CH, uint8_t TONE, uint8_t Velocity);
void MIDI_OFF(uint8_t MIDI_CH, uint8_t TONE, uint8_t Velocity);
void active_MIDI(uint8_t data);

// I2C 통신 함수
void I2C_init(void);
void I2C_start(void);
uint8_t I2C_transmit(uint8_t data);
void I2C_transmit_string(const char *data);
uint8_t I2C_receive(void);
void I2C_stop(void);

// SPI 통신 함수
void SPI_init();
void SPI_send(uint8_t data);
void WS2812_send_color(uint8_t red, uint8_t green, uint8_t blue);
void WS2812_send(uint8_t (*colors)[3], uint8_t count);
#endif /* COMMUNICATION_H_ */

/* ---------------------------------------------------------------------------------- */