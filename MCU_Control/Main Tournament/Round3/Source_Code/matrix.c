/*
 * matrix.c
 *
 * Created: 2024-11-20 오후 9:45:07
 *  Author: rohsw
 */ 

#include "matrix.h"


uint8_t keysArr0[ROWS][COLS] = {{seg7_data0, seg7_data0, seg7_data0, seg7_data4, seg7_data3, seg7_data3, seg7_data3, seg7_data3},		// 옥타브 표시
							{seg7_data3, seg7_data3, seg7_data3, seg7_data3, seg7_data3, seg7_data3, seg7_data3, seg7_data3},
							{seg7_data2, seg7_data2, seg7_data2, seg7_data2, seg7_data2, seg7_data2, seg7_data2, seg7_data2},
							{seg7_data2, seg7_data2, seg7_data2, seg7_data2, seg7_data1, seg7_data1, seg7_data1, seg7_data1},
							{seg7_data1, seg7_data1, seg7_data1, seg7_data1, seg7_data1, seg7_data1, seg7_data1, seg7_data1}};
char keysArr1[ROWS][COLS] = {{'0', '0', '0', 'C', 'B', 'B', 'A', 'A'},		// 음계 표시
							{'G', 'G', 'F', 'E', 'E', 'D', 'D', 'C'},
							{'B', 'B', 'A', 'A', 'G', 'G', 'F', 'E'},
							{'E', 'D', 'D', 'C', 'B', 'B', 'A', 'A'},
							{'G', 'G', 'F', 'E', 'E', 'D', 'D', 'C'}};
char keysArr2[ROWS][COLS] = {{'0', '0', '0', '0', '0', 'b', '0', 'b'},		// 플랫 표시
							{'0', 'b', '0', '0', 'b', '0', 'b', '0'},
							{'0', 'b', '0', 'b', '0', 'b', '0', '0'},
							{'b', '0', 'b', '0', '0', 'b', '0', 'b'},
							{'0', 'b', '0', '0', 'b', '0', 'b', '0'}};
	
unsigned char Pattern[12][8] = {
	{0x00,0x70,0x80,0x80,0x80,0x80,0x80,0x70},	// C0
	{0x00,0xe0,0x90,0x90,0xf0,0x90,0x90,0xe0},	// B0
	{0x08,0xee,0x9a,0x9e,0xf0,0x90,0x90,0xe0},	// Bb
	{0x00,0x60,0x90,0x90,0xf0,0x90,0x90,0x90},	// A0
	{0x08,0x6e,0x9a,0x9e,0xf0,0x90,0x90,0x90},	// Ab
	{0x00,0xf0,0x80,0x80,0xb0,0x90,0x90,0xf0},	// G0
	{0x08,0xfe,0x8a,0x8e,0xb0,0x90,0x90,0xf0},	// Gb
	{0x00,0xf0,0x80,0x80,0xf0,0x80,0x80,0x80},	// F0
	{0x00,0xf0,0x80,0x80,0xf0,0x80,0x80,0xf0},	// E0
	{0x08,0xfe,0x8a,0x8e,0xf0,0x80,0x80,0xf0},	// Eb
	{0x00,0xe0,0x90,0x90,0x90,0x90,0x90,0xe0},	// D0
	{0x08,0xee,0x9a,0x9e,0x90,0x90,0x90,0xe0},	// Db
};
unsigned char Pattern_init[8][8] = {
	{0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00},	// 초기화
	{0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00},	// 초기화
	{0x32,0x4a,0x4a,0x32,0x16,0x1c,0x14,0x1c},	// 입
	{0x00,0x04,0x44,0x44,0x74,0x04,0x04,0x00},	// 니
	{0x00,0x04,0x74,0x46,0x74,0x04,0x04,0x00},	// 다
	{0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00},	// 초기화
	{0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00},	// 초기화
	{0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00}	// 초기화
};


// SPI 마스터 초기화 함수
void SPI_MasterInit(void)
{
	DDRB |= (1<<DD_MOSI)|(1<<DD_SCK)|(1<<DD_SS); // MOSI, SCK, SS 핀을 출력으로 설정
	SPCR = (1<<SPE)|(1<<MSTR)|(1<<SPR0); // SPI 활성화, 마스터 모드, 클럭 속도 fck/16 설정
}

// SPI 데이터 전송 함수
void SPI_Transmit(unsigned char data)
{
	SPDR = data;                      // 데이터를 SPI 데이터 레지스터에 전송
	while(!(SPSR&(1<<SPIF)));         // 전송 완료 대기
}
void MAX7219_TOTAL(unsigned char address, unsigned char data)
{
	PORTB &= ~(1 << DD_SS);						//SS 핀을 LOW로 설정
	for(int i = 0; i < MODULES_NUMBER; i++) {
		SPI_Transmit(address);               // 주소 전송
		SPI_Transmit(data);                  // 데이터 전송
	}
	PORTB |= (1 << DD_SS);   // SS 핀을 HIGH로 설정
}

void MAX7219_Init(void){
	MAX7219_TOTAL(DECODE,0x00);            // 디코딩 모드 해제 *LED Matrix 사용 시 반드시 디코딩 모드 해제 필요
	MAX7219_TOTAL(INTENSITY,0x01);         // 밝기 설정 = 0x00 ~ 0x0F
	MAX7219_TOTAL(SCAN_LIMIT,0x07);        // 행 활성화 개수 = 0~7에서 선택가능
	MAX7219_TOTAL(SHUTDOWN,0x01);          // 셧다운 : 0=OFF / 1=ON
	MAX7219_TOTAL(TEST,0x00);              // 테스트 모드 : 0=정상 / 1=LED 강제 ON
	
	for(int Ind = 0; Ind < MODULES_NUMBER; Ind++) {
		for(int Row = 0; Row < 8; Row++) {
			MAX7219_Target(Ind, Row + 1, Pattern_init[Ind][Row]);
		}
	}

}


// MAX7219 LED
void MAX7219_Target(int Target, unsigned char address, unsigned char data)
{
	PORTB &= ~(1 << DD_SS);
	
	for(int i = 0; i < MODULES_NUMBER; i++) {
		if(i == Target) {
			SPI_Transmit(address);
			SPI_Transmit(data);
		} else {
			SPI_Transmit(NOP);
			SPI_Transmit(0x00);
		}
	}
	PORTB |= (1 << DD_SS);
}


void init_KeyMatrix(void)
{
	// ROW 연결 핀 설정
	DDRC &= ~(1 << KEY_ROW_PIN1);													// 입력
	DDRD &= ~( (1 << KEY_ROW_PIN2) | (1 << KEY_ROW_PIN3) | (1 << KEY_ROW_PIN4) | 1 << KEY_ROW_PIN5);	// 입력
}


void active_key_matrix(void) {
	uint8_t KeyCurrentPressed[ROWS][COLS] = {0, };
	static uint8_t KeyPastPressed[ROWS][COLS] = {0, };
	uint8_t row, col;
	// col 돌아가며 버튼 상태 검사
	for(col = 0; col < COLS; col++){
		shift_register_write_8bit_key((1 << col));			// shift register 이용하여 해당 col에 high 출력
		
		_delay_ms(3); // 출력 안정화
		// row 의 입력을 읽어서, HIGH값이면 버튼이 눌려진 상태로 인식
		KeyCurrentPressed[0][col] = (PINC & (1 << KEY_ROW_PIN1)) >> KEY_ROW_PIN1;
		KeyCurrentPressed[1][col] = (PIND & (1 << KEY_ROW_PIN2)) >> KEY_ROW_PIN2;
		KeyCurrentPressed[2][col] = (PIND & (1 << KEY_ROW_PIN3)) >> KEY_ROW_PIN3;
		KeyCurrentPressed[3][col] = (PIND & (1 << KEY_ROW_PIN4)) >> KEY_ROW_PIN4;
		KeyCurrentPressed[4][col] = (PIND & (1 << KEY_ROW_PIN5)) >> KEY_ROW_PIN5;
		
	}
	for(row = 0; row < ROWS; row++){
		for(col = 0; col < COLS; col++){
			if(KeyCurrentPressed[row][col] != KeyPastPressed[row][col]) {
				if (KeyCurrentPressed[row][col] == 0) {
					MIDI_OFF(0, ( 63 - (row*8 + col) ), 100);
					KeyPastPressed[row][col] = 0;
					for (int i = 0; i < 3; i++){
						led_current_color[51 - (row*8 + col)][i] = 0;
					}
				}
				else if ( (row != 0) | (col > 2) ) {
					MIDI_ON(0, ( 63 - (row*8 + col) ), 100);
					KeyPastPressed[row][col] = 1;
					for (int i = 0; i < 3; i++){
						led_current_color[51 - (row*8 + col)][i] = 128;
					}
				}
			}
		}
	}
}

