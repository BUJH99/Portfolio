#include <stdio.h>
#include <string.h>        // strcmp 사용
#include "source_code.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "xil_io.h"
#include <xparameters.h>

/*    For UART Config start    */
#ifdef STDOUT_IS_16550
 #include "xuartns550_l.h"
 #define UART_BAUD 9600
#endif

void
enable_caches()
{
#ifdef __PPC__
    Xil_ICacheEnableRegion(CACHEABLE_REGION_MASK);
    Xil_DCacheEnableRegion(CACHEABLE_REGION_MASK);
#elif __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_USE_ICACHE
    Xil_ICacheEnable();
#endif
#ifdef XPAR_MICROBLAZE_USE_DCACHE
    Xil_DCacheEnable();
#endif
#endif
}

void
disable_caches()
{
#ifdef __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_USE_DCACHE
    Xil_DCacheDisable();
#endif
#ifdef XPAR_MICROBLAZE_USE_ICACHE
    Xil_ICacheDisable();
#endif
#endif
}

void
init_uart()
{
#ifdef STDOUT_IS_16550
    XUartNs550_SetBaud(STDOUT_BASEADDR, XPAR_XUARTNS550_CLOCK_HZ, UART_BAUD);
    XUartNs550_SetLineControlReg(STDOUT_BASEADDR, XUN_LCR_8_DATA_BITS);
#endif
    /* Bootrom/BSP configures PS7/PSU UART to 115200 bps */
}

void
init_platform()
{
    /*
     * If you want to run this example outside of SDK,
     * uncomment one of the following two lines and also #include "ps7_init.h"
     * or #include "ps7_init.h" at the top, depending on the target.
     * Make sure that the ps7/psu_init.c and ps7/psu_init.h files are included
     * along with this example source files for compilation.
     */
    /* ps7_init();*/
    /* psu_init();*/
    enable_caches();
    init_uart();
}

void
cleanup_platform()
{
    disable_caches();
}

/*    For UART Config end    */

#define MODE_AXI_BASEADDR 0xA0000000U   // s_axi_lite_module base address (reg0)

int main()
{
    char mode_str[8];       // 입력 문자열 ("00","01","10","11" 등)
    unsigned int mode_val;  // 실제 모드 값 (0~3)

    init_platform();
    print("Mode Control Application\n\r");
    print("Input mode: 0(bypass), 1(sharpen), 2(edge enhance))\n\r");

    while (1) {
        print("\n\rEnter mode (0/1/2): ");

        // 최대 7글자까지 안전하게 입력
        scanf("%7s", mode_str);

        // 문자열에 따라 모드 결정
        if (!strcmp(mode_str, "0")) {
            mode_val = 0;
			xil_printf("Selected mode: bypass\r\n");
        } else if (!strcmp(mode_str, "1")) {
            mode_val = 1;
			xil_printf("Selected mode: sharpen\r\n");
        } else if (!strcmp(mode_str, "2")) {
            mode_val = 2;
			xil_printf("Selected mode: edge enhance\r\n");
        } else {
			xil_printf("Invalid input\r\n");
        }

        // xil_printf("Selected mode = %u\r\n", mode_val);

        // reg0 에 모드 값 쓰기 (하위 2비트만 사용)
        // s_axi_lite_module 의 reg0[1:0] -> mode 출력을 통해 탑모듈로 전달
        Xil_Out32(MODE_AXI_BASEADDR, mode_val & 0x3);

        usleep(100);
    }

    cleanup_platform();
    return 0;
}
