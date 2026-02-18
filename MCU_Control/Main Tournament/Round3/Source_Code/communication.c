 /* ------------------------------------------------------------------------------------
   파 일 명: communication.c
   내용설명: 통신을 위한 함수 정의
   기능상세: 
   ------------------------------------------------------------------------------------ */


#include "communication.h"


uint8_t led_color_init[LED_COUNT][3] = {
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0}
};
uint8_t led_current_color[LED_COUNT][3] = {
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0},
	{255, 0, 0}
};

/* ------------------------------------------------------------------------------------ 
   UART 통신 함수 
   ------------------------------------------------------------------------------------ */

// UART 통신 초기 설정 함수
void UART_init(void) {
	unsigned int ubrr = (F_CPU / (16UL * BAUD)) - 1;
	UBRR0H = (unsigned char)(ubrr >> 8);
	UBRR0L = (unsigned char)ubrr;
	UCSR0B |= (1 << RXEN0) | (1 << TXEN0); // 송신기 및 수신기 활성화
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00); // 비동기 & 8bit 데이터 통신 설정
}
// UART 데이터 송신 함수
void UART_transmit(uint8_t data) {
	while( !(UCSR0A & (1 << UDRE0)) );							// 송신 가능해질 때까지 대기
	UDR0 = data;												// 송신 버퍼에 있는 데이터 송신
}

// UART 데이터 수신 함수
unsigned char UART_receive(void) {
	while( !(UCSR0A & (1 << RXC0)) );							// 수신 가능해질 때까지 대기
	return UDR0;												// 수신된 데이터값 반환
}

void MIDI_ON(uint8_t MIDI_CH, uint8_t TONE, uint8_t Velocity) {
	UART_transmit(0x90 | (MIDI_CH & 0x0F));						// 상태 바이트 (노트 ON, 채널)
	_delay_us(100);
	UART_transmit(TONE & 0x7F);									// 데이터 바이트 1 (노트 데이터)
	_delay_us(100);
	UART_transmit(Velocity & 0x7F);
	_delay_us(100);
}

void MIDI_OFF(uint8_t MIDI_CH, uint8_t TONE, uint8_t Velocity) {
	UART_transmit( 0x80 | (MIDI_CH & 0x0F) );						// 상태 바이트 (노트 OFF, 채널)
	_delay_us(100);
	UART_transmit(TONE & 0x7F);									// 데이터 바이트 1 (노트 데이터)
	_delay_us(100);
	UART_transmit(Velocity & 0x7F);								// 데이터 바이트 2 (속도)
	_delay_us(100);
}

void active_MIDI(uint8_t data) {
	if (UCSR0A & (1 << RXC0)) {			// UART 데이터가 들어왔는지 확인
		MIDI_ON(0, data, 100);			// 수신한 데이터로 MIDI ON
		MIDI_OFF(0, data, 100);			// 동일한 데이터로 MIDI OFF
	}
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




// SPI 초기화 함수
void SPI_init() {
	// MOSI와 SCK 핀을 출력으로 설정
	DDRB |= (1 << PB3) | (1 << PB5);
	// SPI를 마스터 모드, 클럭 속도 fosc/8로 설정 (8MHz)
	SPCR = (1 << SPE) | (1 << MSTR) | (1 << CPHA); // fosc/2
	SPSR = (1 << SPI2X); // SPI2X 비활성화
	WS2812_send(led_color_init, LED_COUNT);
	
}


// SPI로 데이터 전송 함수
void SPI_send(uint8_t data) {
	SPDR = data; // 데이터를 전송 레지스터에 저장
	while (!(SPSR & (1 << SPIF))); // 전송 완료 대기
}

// WS2812B로 1개의 LED에 대한 데이터 전송
void WS2812_send_color(uint8_t red, uint8_t green, uint8_t blue) {
	uint8_t colors[3] = {green, red, blue};
	for (uint8_t i = 0; i < 3; i++) {
		for (int8_t bit = 7; bit >= 0; bit--) {
			if (colors[i] & (1 << bit)) {
				SPI_send(0b11111110); // "1" 비트
				} else {
				SPI_send(0b11000000); // "0" 비트
			}
		}
	}
}

// WS2812B로 여러 LED의 데이터 전송
void WS2812_send(uint8_t (*colors)[3], uint8_t count) {
	for (uint8_t i = 0; i < count; i++) {
		WS2812_send_color(colors[i][0], colors[i][1], colors[i][2]);
	}
	_delay_us(80); // 데이터 전송 후 80μs 이상 대기
}


/* ---------------------------------------------------------------------------------- */