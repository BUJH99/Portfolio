/* dma_loopback_HWACC_irq_sweep_avg_with_dump.c
 * - AXI DMA (Simple, 32-bit stream), IRQ timing
 * - Sweep N in {10,32,64,128,256,512,1000,1024}
 * - Per N: warmup x2 (no measure) -> ONE verification run (print RX) -> measure x10 (mean/best)
 * - Timing window: start(before arming) → S2MM IOC
 */

 #include "xparameters.h"
 #include "xparameters_ps.h"
 #include "xil_types.h"
 #include "xaxidma.h"
 #include "xaxidma_hw.h"
 #include "xscugic.h"
 #include "xil_exception.h"
 #include "xil_cache.h"
 #include "xil_printf.h"
 #include "xil_io.h"
 #include "xstatus.h"
 
 #include <stdint.h>
 #include <string.h>
 
 /* ===== Guards ===== */
 #if (XPAR_XAXIDMA_0_INCLUDE_SG != 0)
 # error "Requires Simple DMA (INCLUDE_SG == 0)."
 #endif
 #if (XPAR_XAXIDMA_0_MM2S_DATA_WIDTH != 0x20) || (XPAR_XAXIDMA_0_S2MM_DATA_WIDTH != 0x20)
 # error "AXIS stream width must be 32-bit (0x20)."
 #endif
 
 /* ===== Sweep set & runs ===== */
 static const unsigned kSweepN[] = {10, 32, 64, 128, 256};
 #define NUM_SWEEP   (sizeof(kSweepN)/sizeof(kSweepN[0]))
 #define WARMUP      2u
 #define RUNS        10u
 
 /* ===== Config ===== */
 #define BYTES_PER_BEAT   4u
 #define TIMEOUT      20000000u
 #define ALIGN_BYTES      64u
 #define MAX_CLASSES   1024u
 
 /* ===== Verification dump control ===== */
 #define DUMP_ALL_ELEMS   1   /* 1: 모든 원소 출력, 0: 일부만 */
 #define DUMP_MAX_ELEMS  32   /* DUMP_ALL_ELEMS=0일 때 최대 출력 개수 */
 
 /* ===== IRQ IDs (Zynq: FPGA0/1 → 61/62) ===== */
 #if defined(XPAR_SCUGIC_SINGLE_DEVICE_ID)
 # define INTC_DEVICE_ID  XPAR_SCUGIC_SINGLE_DEVICE_ID
 #else
 # define INTC_DEVICE_ID  0
 #endif
 #define DMA_IRQ0_ID  XPS_FPGA0_INT_ID
 #define DMA_IRQ1_ID  XPS_FPGA1_INT_ID
 
 /* ===== Global Timer (SCU GT) ===== */
 #ifndef XPAR_PS7_GLOBALTIMER_0_BASEADDR
 # define XPAR_PS7_GLOBALTIMER_0_BASEADDR 0xF8F00200U
 #endif
 #define GT_BASE   XPAR_PS7_GLOBALTIMER_0_BASEADDR
 #define GT_LSB    (GT_BASE + 0x00U)
 #define GT_MSB    (GT_BASE + 0x04U)
 #define GT_CTRL   (GT_BASE + 0x08U)
 #define GT_EN     0x00000001U
 
 /* CPU=100MHz 가정 -> GT=50MHz */
 #define CPU_CLK_HZ  (100000000U)
 #define GT_FREQ_HZ  (CPU_CLK_HZ/2U)
 
 static inline void GT_Init(void){
   Xil_Out32(GT_CTRL, Xil_In32(GT_CTRL) | GT_EN);
 }
 static inline u64 GT_Read(void){
   u32 lo, hi1, hi2;
   do { hi1 = Xil_In32(GT_MSB); lo = Xil_In32(GT_LSB); hi2 = Xil_In32(GT_MSB); } while (hi1 != hi2);
   return (((u64)hi1) << 32) | lo;
 }
 
 /* ===== Base dataset (120 floats), reused cyclically ===== */
 #define KTXLEN 120u
 static const float kTxVals[KTXLEN] = {
   7.413f, 5.238f, 9.671f, 6.892f, 8.105f, 5.764f, 9.297f, 6.021f, 7.958f, 8.643f,
   5.489f, 7.226f, 9.884f, 6.347f, 8.412f, 5.913f, 9.128f, 7.541f, 6.278f, 5.332f,
   8.977f, 7.804f, 6.615f, 9.452f, 5.786f, 7.689f, 5.942f, 8.231f, 6.873f, 9.036f,
   7.413f, 5.238f, 9.671f, 6.892f, 8.105f, 5.764f, 9.297f, 6.021f, 7.958f, 8.643f,
   5.489f, 7.226f, 9.884f, 6.347f, 8.412f, 5.913f, 9.128f, 7.541f, 6.278f, 5.332f,
   8.977f, 7.804f, 6.615f, 9.452f, 5.786f, 7.689f, 5.942f, 8.231f, 6.873f, 9.036f,
   7.413f, 5.238f, 9.671f, 6.892f, 8.105f, 5.764f, 9.297f, 6.021f, 7.958f, 8.643f,
   5.489f, 7.226f, 9.884f, 6.347f, 8.412f, 5.913f, 9.128f, 7.541f, 6.278f, 5.332f,
   8.977f, 7.804f, 6.615f, 9.452f, 5.786f, 7.689f, 5.942f, 8.231f, 6.873f, 9.036f,
   7.413f, 5.238f, 9.671f, 6.892f, 8.105f, 5.764f, 9.297f, 6.021f, 7.958f, 8.643f,
   5.489f, 7.226f, 9.884f, 6.347f, 8.412f, 5.913f, 9.128f, 7.541f, 6.278f, 5.332f,
   8.977f, 7.804f, 6.615f, 9.452f, 5.786f, 7.689f, 5.942f, 8.231f, 6.873f, 9.036f
 };
 
 /* ===== HW instances & buffers ===== */
 static XAxiDma  AxiDma;
 static XScuGic  Intc;
 
 static float    txF[MAX_CLASSES] __attribute__((aligned(ALIGN_BYTES)));
 static uint32_t rxU[MAX_CLASSES] __attribute__((aligned(ALIGN_BYTES)));
 
 /* ===== Runtime flags & timestamps ===== */
 static volatile int  TxDone = 0;
 static volatile int  RxDone = 0;
 static volatile int  DmaErr = 0;
 
 static volatile u64  t_start_ticks = 0;
 static volatile u64  t_s2mm_done   = 0;
 
 /* ===== Float fixed-point print (for xil_printf) ===== */
 #define DECIMALS 9
 static void print_float_fixed(float v){
   int neg = (v < 0.0f);
   double a = neg ? -(double)v : (double)v;
   int32_t ip = (int32_t)a;
   double frac = a - (double)ip;
 
   unsigned long long scale = 1ull;
   for (int i = 0; i < DECIMALS; ++i) scale *= 10ull;
 
   unsigned long long fp = (unsigned long long)(frac * (double)scale + 0.5);
   if (fp >= scale) { ip += 1; fp -= scale; }
 
   char frac_str[DECIMALS + 1];
   for (int i = DECIMALS - 1; i >= 0; --i) { frac_str[i] = (char)('0' + (fp % 10ull)); fp /= 10ull; }
   frac_str[DECIMALS] = '\0';
 
   xil_printf("%c%d.%s", neg ? '-' : ' ', ip, frac_str);
 }
 
 /* ===== DMA utils & IRQ ===== */
 static int dma_soft_reset(XAxiDma *p){
   XAxiDma_Reset(p);
   u32 t = TIMEOUT;
   while(!XAxiDma_ResetIsDone(p)){ if(!t--) return XST_FAILURE; }
   return XST_SUCCESS;
 }
 static void EnableDmaInterrupts(XAxiDma *d){
   u32 txsr = XAxiDma_ReadReg(d->RegBase + XAXIDMA_TX_OFFSET, XAXIDMA_SR_OFFSET);
   u32 rxsr = XAxiDma_ReadReg(d->RegBase + XAXIDMA_RX_OFFSET, XAXIDMA_SR_OFFSET);
   XAxiDma_WriteReg(d->RegBase + XAXIDMA_TX_OFFSET, XAXIDMA_SR_OFFSET, txsr);
   XAxiDma_WriteReg(d->RegBase + XAXIDMA_RX_OFFSET, XAXIDMA_SR_OFFSET, rxsr);
 
   u32 txcr = XAxiDma_ReadReg(d->RegBase + XAXIDMA_TX_OFFSET, XAXIDMA_CR_OFFSET);
   u32 rxcr = XAxiDma_ReadReg(d->RegBase + XAXIDMA_RX_OFFSET, XAXIDMA_CR_OFFSET);
   txcr |= (XAXIDMA_IRQ_IOC_MASK | XAXIDMA_IRQ_ERROR_MASK);
   rxcr |= (XAXIDMA_IRQ_IOC_MASK | XAXIDMA_IRQ_ERROR_MASK);
   XAxiDma_WriteReg(d->RegBase + XAXIDMA_TX_OFFSET, XAXIDMA_CR_OFFSET, txcr);
   XAxiDma_WriteReg(d->RegBase + XAXIDMA_RX_OFFSET, XAXIDMA_CR_OFFSET, rxcr);
 }
 static void DisableDmaInterrupts(XAxiDma *d){
   u32 txcr = XAxiDma_ReadReg(d->RegBase + XAXIDMA_TX_OFFSET, XAXIDMA_CR_OFFSET);
   u32 rxcr = XAxiDma_ReadReg(d->RegBase + XAXIDMA_RX_OFFSET, XAXIDMA_CR_OFFSET);
   txcr &= ~(XAXIDMA_IRQ_ALL_MASK);
   rxcr &= ~(XAXIDMA_IRQ_ALL_MASK);
   XAxiDma_WriteReg(d->RegBase + XAXIDMA_TX_OFFSET, XAXIDMA_CR_OFFSET, txcr);
   XAxiDma_WriteReg(d->RegBase + XAXIDMA_RX_OFFSET, XAXIDMA_CR_OFFSET, rxcr);
 }
 static void DmaIrqHandler(void *Callback){
   XAxiDma *DmaPtr = (XAxiDma *)Callback;
 
   u32 risr = XAxiDma_ReadReg(DmaPtr->RegBase + XAXIDMA_RX_OFFSET, XAXIDMA_SR_OFFSET);
   if (risr){
     if (risr & XAXIDMA_IRQ_IOC_MASK){ t_s2mm_done = GT_Read(); RxDone = 1; }
     if (risr & XAXIDMA_IRQ_ERROR_MASK) DmaErr = 1;
     XAxiDma_WriteReg(DmaPtr->RegBase + XAXIDMA_RX_OFFSET, XAXIDMA_SR_OFFSET, risr);
   }
   u32 tisr = XAxiDma_ReadReg(DmaPtr->RegBase + XAXIDMA_TX_OFFSET, XAXIDMA_SR_OFFSET);
   if (tisr){
     if (tisr & XAXIDMA_IRQ_IOC_MASK) TxDone = 1;
     if (tisr & XAXIDMA_IRQ_ERROR_MASK) DmaErr = 1;
     XAxiDma_WriteReg(DmaPtr->RegBase + XAXIDMA_TX_OFFSET, XAXIDMA_SR_OFFSET, tisr);
   }
 }
 static int SetupInterruptSystem(XScuGic *IntcPtr, XAxiDma *DmaPtr){
   int Status;
   XScuGic_Config *Cfg = XScuGic_LookupConfig(INTC_DEVICE_ID);
   if(!Cfg) return XST_FAILURE;
   Status = XScuGic_CfgInitialize(IntcPtr, Cfg, Cfg->CpuBaseAddress);
   if (Status != XST_SUCCESS) return Status;
   XScuGic_SetPriorityTriggerType(IntcPtr, DMA_IRQ0_ID, 0xA0, 0x1);
   XScuGic_SetPriorityTriggerType(IntcPtr, DMA_IRQ1_ID, 0xA0, 0x1);
   XScuGic_Connect(IntcPtr, DMA_IRQ0_ID, (Xil_InterruptHandler)DmaIrqHandler, (void*)DmaPtr);
   XScuGic_Connect(IntcPtr, DMA_IRQ1_ID, (Xil_InterruptHandler)DmaIrqHandler, (void*)DmaPtr);
   XScuGic_Enable(IntcPtr, DMA_IRQ0_ID);
   XScuGic_Enable(IntcPtr, DMA_IRQ1_ID);
   Xil_ExceptionInit();
   Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
                                (Xil_ExceptionHandler)XScuGic_InterruptHandler,
                                (void *)IntcPtr);
   Xil_ExceptionEnable();
   return XST_SUCCESS;
 }
 
 /* ===== Helpers ===== */
 static void fill_input(float* dst, unsigned N){
   for (unsigned i=0;i<N;++i) dst[i] = kTxVals[i % KTXLEN];
 }
 static void print_u64_dec(u64 v){
   char buf[32]; int i=0;
   if (v==0){ xil_printf("0"); return; }
   while (v>0 && i<31){ buf[i++] = (char)('0' + (v % 10ULL)); v /= 10ULL; }
   while (i--) xil_printf("%c", buf[i]);
 }
 static void print_3digits_u32(u32 v){
   char s[4];
   s[0]=(char)('0'+(v/100)%10); s[1]=(char)('0'+(v/10)%10); s[2]=(char)('0'+(v%10)); s[3]='\0';
   xil_printf("%s", s);
 }
 static void print_ms_q3(u64 ns){
   u32 ms_i = (u32)(ns / 1000000ULL);
   u32 ms_f = (u32)((ns % 1000000ULL) / 1000ULL);
   /* int part */
   char buf[16]; int i=0; u32 x=ms_i;
   if (x==0) xil_printf("0"); else { while (x>0 && i<15){ buf[i++]=(char)('0'+(x%10)); x/=10; } while (i--) xil_printf("%c", buf[i]); }
   xil_printf("."); print_3digits_u32(ms_f); xil_printf(" ms");
 }
 static void print_MBps_q3(u32 bytes, u64 ticks, u32 fGT){
   if (ticks==0){ xil_printf("inf MB/s"); return; }
   u64 num = (u64)bytes * (u64)fGT * 1000ULL;
   u64 den = (u64)ticks * 1000000ULL;
   u64 q1000 = num / den;
   u32 i = (u32)(q1000 / 1000ULL);
   u32 f = (u32)(q1000 % 1000ULL);
   char buf[16]; int k=0; u32 t=i;
   if (t==0) xil_printf("0"); else { while (t>0 && k<15){ buf[k++]=(char)('0'+(t%10)); t/=10; } while (k--) xil_printf("%c", buf[k]); }
   xil_printf("."); print_3digits_u32(f); xil_printf(" MB/s");
 }
 static void print_melems_q3(u32 N, u64 ticks, u32 fGT){
   if (ticks==0){ xil_printf("inf Melem/s"); return; }
   u64 num = (u64)N * (u64)fGT * 1000ULL;
   u64 den = (u64)ticks * 1000000ULL;
   u64 q1000 = num / den;
   u32 i = (u32)(q1000 / 1000ULL);
   u32 f = (u32)(q1000 % 1000ULL);
   char buf[16]; int k=0; u32 t=i;
   if (t==0) xil_printf("0"); else { while (t>0 && k<15){ buf[k++]=(char)('0'+(t%10)); t/=10; } while (k--) xil_printf("%c", buf[k]); }
   xil_printf("."); print_3digits_u32(f); xil_printf(" Melem/s");
 }
 
 /* ===== One IRQ run; if do_dump=1, print RX once ===== */
 static int dma_run_once_irq(unsigned N, u64* out_ticks, int do_dump){
   const u32 bytes = N * BYTES_PER_BEAT;
 
   fill_input(txF, N);
   for (unsigned i=0;i<N;++i) rxU[i] = 0xCDCDCDCDu;
 
   Xil_DCacheFlushRange((UINTPTR)txF, bytes);
   Xil_DCacheInvalidateRange((UINTPTR)rxU, bytes);
 
   TxDone = 0; RxDone = 0; DmaErr = 0; t_s2mm_done = 0;
 
   /* Clear pending */
   u32 txsr = XAxiDma_ReadReg(AxiDma.RegBase + XAXIDMA_TX_OFFSET, XAXIDMA_SR_OFFSET);
   u32 rxsr = XAxiDma_ReadReg(AxiDma.RegBase + XAXIDMA_RX_OFFSET, XAXIDMA_SR_OFFSET);
   if (txsr) XAxiDma_WriteReg(AxiDma.RegBase + XAXIDMA_TX_OFFSET, XAXIDMA_SR_OFFSET, txsr);
   if (rxsr) XAxiDma_WriteReg(AxiDma.RegBase + XAXIDMA_RX_OFFSET, XAXIDMA_SR_OFFSET, rxsr);
 
   t_start_ticks = GT_Read();
 
   int st = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR)rxU, bytes, XAXIDMA_DEVICE_TO_DMA);
   if (st != XST_SUCCESS) return st;
   st = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR)txF, bytes, XAXIDMA_DMA_TO_DEVICE);
   if (st != XST_SUCCESS) return st;
 
   /* Poll for IRQ-completion with crude timeout */
   u32 to = TIMEOUT;
   while (!RxDone && !DmaErr){ if (!to--) return XST_FAILURE; }
   if (DmaErr) return XST_FAILURE;
 
   *out_ticks = (t_s2mm_done >= t_start_ticks) ? (t_s2mm_done - t_start_ticks) : 0ULL;
 
   if (do_dump){
     /* Show RX (once) for golden compare */
     Xil_DCacheInvalidateRange((UINTPTR)rxU, bytes);
     xil_printf("\r\n-- RX dump (N=%u) --\r\n", (unsigned)N);
 #if DUMP_ALL_ELEMS
     unsigned limit = N;
 #else
     unsigned limit = (N < DUMP_MAX_ELEMS) ? N : DUMP_MAX_ELEMS;
 #endif
     for (unsigned i=0; i<limit; ++i){
       float f; memcpy(&f, &rxU[i], sizeof(float));
       xil_printf("[%03u] ", i); print_float_fixed(f);
       xil_printf("  (0x%08X)\r\n", (unsigned)rxU[i]);
     }
 #if !DUMP_ALL_ELEMS
     if (limit < N) xil_printf("... (%u more not shown)\r\n", (unsigned)(N - limit));
 #endif
   }
 
   return XST_SUCCESS;
 }
 
 /* ===== Bench one N ===== */
 static int bench_one_irq(unsigned N){
   if (N==0 || N>MAX_CLASSES){
     xil_printf("N=%u out of range (1..%u)\r\n", N, (unsigned)MAX_CLASSES);
     return XST_FAILURE;
   }
   const u32 bytes = N * BYTES_PER_BEAT;
 
   /* Warmups (not measured) */
   for (unsigned w=0; w<WARMUP; ++w){
     u64 dummy;
     if (dma_run_once_irq(N, &dummy, 0) != XST_SUCCESS) return XST_FAILURE;
   }
 
   /* ONE verification run (print RX), not measured */
   {
     u64 dummy;
     if (dma_run_once_irq(N, &dummy, 1) != XST_SUCCESS) return XST_FAILURE;
   }
 
   /* Measured runs */
   u64 sum_ticks = 0, best_ticks = ~0ULL;
   for (unsigned r=0; r<RUNS; ++r){
     u64 dt = 0;
     int st = dma_run_once_irq(N, &dt, 0);
     if (st != XST_SUCCESS) return st;
     sum_ticks += dt;
     if (dt < best_ticks) best_ticks = dt;
   }
 
   u64 mean_ticks = sum_ticks / RUNS;
   u64 mean_ns    = (mean_ticks * 1000000000ULL) / (u64)GT_FREQ_HZ;
   u64 best_ns    = (best_ticks * 1000000000ULL) / (u64)GT_FREQ_HZ;
 
   xil_printf("\r\n--- N=%u (stats) ---\r\n", (unsigned)N);
   xil_printf("ticks(mean): 0x%08X%08X (", (u32)(mean_ticks>>32), (u32)mean_ticks); print_u64_dec(mean_ticks); xil_printf(")\r\n");
   xil_printf("ticks(최고): 0x%08X%08X (", (u32)(best_ticks>>32), (u32)best_ticks); print_u64_dec(best_ticks); xil_printf(")\r\n");
 
   xil_printf("Elapsed(mean): "); print_u64_dec(mean_ns); xil_printf(" ns ("); print_ms_q3(mean_ns); xil_printf(")  |  ");
   xil_printf("Throughput(mean): "); print_MBps_q3(bytes, mean_ticks, (u32)GT_FREQ_HZ);
   xil_printf("  |  Rate(mean): "); print_melems_q3(N, mean_ticks, (u32)GT_FREQ_HZ); xil_printf("\r\n");
 
   return XST_SUCCESS;
 }
 
 /* ===== main ===== */
 int main(void){
   xil_printf("\r\n=== AXI DMA 32b Loopback (IRQ) — warmup %u, runs %u ===\r\n",
              (unsigned)WARMUP, (unsigned)RUNS);
   xil_printf("CPU_CLK=%u Hz, GT=%u Hz\r\n", (unsigned)CPU_CLK_HZ, (unsigned)GT_FREQ_HZ);
 
   GT_Init();
 
   XAxiDma_Config *cfg = NULL;
 #if defined(SDT)
   cfg = XAxiDma_LookupConfig(XPAR_XAXIDMA_0_BASEADDR);
 #else
   cfg = XAxiDma_LookupConfigBaseAddr(XPAR_XAXIDMA_0_BASEADDR);
 #endif
   if (!cfg) { xil_printf("ERROR: LookupConfig\r\n"); return XST_FAILURE; }
   if (XAxiDma_CfgInitialize(&AxiDma, cfg) != XST_SUCCESS){ xil_printf("ERROR: CfgInitialize\r\n"); return XST_FAILURE; }
   if (XAxiDma_HasSg(&AxiDma)) { xil_printf("ERROR: SG mode not supported\r\n"); return XST_FAILURE; }
   if (dma_soft_reset(&AxiDma) != XST_SUCCESS) { xil_printf("ERROR: DMA reset\r\n"); return XST_FAILURE; }
 
   if (SetupInterruptSystem(&Intc, &AxiDma) != XST_SUCCESS){ xil_printf("ERROR: IRQ setup\r\n"); return XST_FAILURE; }
   EnableDmaInterrupts(&AxiDma);
 
   for (unsigned i=0; i<NUM_SWEEP; ++i){
     int st = bench_one_irq(kSweepN[i]);
     if (st != XST_SUCCESS) xil_printf("N=%u: ERROR(st=%d)\r\n", kSweepN[i], st);
   }
 
   DisableDmaInterrupts(&AxiDma);
 
   xil_printf("=== Done ===\r\n");
   return XST_SUCCESS;
 }
 