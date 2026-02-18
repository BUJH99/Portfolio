#include <avr/io.h>         // AVR I/O 레지스터 정의
#include <util/delay.h>     // _delay_ms() 함수 사용을 위한 유틸리티
#include <stdint.h>         // uint8_t 등의 정수형 데이터 타입 사용

#define F_CPU 16000000UL


#define BAUD 31250 *MIDI 사용시 고정임

uint8_t INPUT_TONE = 0;

// UART 통신 초기 설정 함수
void UART_init(void) {
	UBRR0H = 0x00;												// 보율(Baud rate) 설정
	UBRR0L = 31;												// 보율(Baud rate) 설정
	UCSR0B |= (1 << RXEN0) | (1 << TXEN0);						// 송신기 및 수신기 활성화
	UCSR0C = 0x06;												// 비동기 & parityX & 8bit 데이터 통신 설정  
}

// UART 데이터 송신 함수
void UART_Transmit(uint8_t data) {
	while( !(UCSR0A & (1 << UDRE0)) );							// 송신 가능해질 때까지 대기
	UDR0 = data;												// 송신 버퍼에 있는 데이터 송신
}

uint8_t UART_Receive(void) {
	// UART로 데이터 수신하는 함수
	while (!(UCSR0A & (1 << RXC0)));   // 수신 완료 플래그를 기다림
	return UDR0;                       // 수신된 데이터 반환
}


void MIDI_ON(uint8_t MIDI_CH, uint8_t TONE, uint8_t Velocity) {
    UART_Transmit(0x90 | (MIDI_CH & 0x0F)); // 상태 바이트 (노트 ON, 채널)
    UART_Transmit(TONE & 0x7F);             // 데이터 바이트 1 (노트 데이터)
    UART_Transmit(Velocity & 0x7F);         
}

void MIDI_OFF(uint8_t MIDI_CH, uint8_t TONE, uint8_t Velocity) {
	UART_Transmit(0x80 | (MIDI_CH & 0x0F)); // 상태 바이트 (노트 OFF, 채널)
	UART_Transmit(TONE & 0x7F);             // 데이터 바이트 1 (노트 데이터)
	UART_Transmit(Velocity & 0x7F);                // 데이터 바이트 2 (속도)
}

int main(void) {
    UART_init();
    
    while (1) {
        uint8_t received = (uint8_t)UART_Receive(); // 입력 데이터 수신
        if (UCSR0A & (1 << RXC0)) { // UART 데이터가 들어왔는지 확인  
            MIDI_ON(0, received, 100);        // 수신한 데이터로 MIDI ON
            _delay_ms(300);
            MIDI_OFF(0, received, 100);       // 동일한 데이터로 MIDI OFF
            _delay_ms(300);
        }
        _delay_ms(10);
    }
  }