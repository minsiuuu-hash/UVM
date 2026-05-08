#include "xil_printf.h"
#include <string.h>

#include "ap_main.h"
#include "../HAL/TMR/TMR.h"
#include "TimeClock/TimeClock.h"
#include "UpCounter/UpCounter.h"
#include "interrupt.h"
#include "../driver/Button/Button.h"
#include "../driver/LED/LED.h"
#include "DispService/DispService.h"

typedef struct {
	uint32_t SR;
	uint32_t TDR;
	uint32_t RDR;
	uint32_t CR;
}UART_Typedef_t;

#define UART_BASE_ADDR XPAR_UART_0_S00_AXI_BASEADDR
#define UART0 ((UART_Typedef_t *)(UART_BASE_ADDR))

uint8_t UART_IsSending(UART_Typedef_t *uart)
{
	return (uart->SR & 1U <<0) ? 0 : 1;
}

uint8_t UART_IsAvailable(UART_Typedef_t *uart)
{
	return (uart->SR & 1U <<0) ? 1 : 0;
}

void UART_SendByte(UART_Typedef_t *uart, uint8_t data)
{
	while(UART_IsSending(uart));
	uart->TDR = data;
}

uint8_t UART_RecvByte(UART_Typedef_t *uart)
{
	uint8_t rx_data;
	while(!UART_IsAvailable(uart));
	rx_data = uart->RDR;
	return rx_data;
}

void UART_Send(UART_Typedef_t *uart, uint8_t *pData , uint16_t len)
{
	for(int i=0; i<len; i++) {
		UART_SendByte(uart,pData[i]);
	}
}



typedef enum {
	TIME_CLOCK,
	UP_COUNTER
} mode_state_t;

mode_state_t modeState = TIME_CLOCK;

hBtn_t hbtnMode;

void ap_init() {
	Button_Init(&hbtnMode, GPIOA, GPIO_PIN_5);

	UpCounter_Init();
	TimeClock_Init();
	SetupInterruptSystem();

	TMR0_Init();
	TMR1_Init();
	TMR2_Init();
}

void ap_execute()
{
	//UART_Send(UART0, "Hello World KCCI STC",len);

	char str[] = {"Hello World KCCI STC\n"};
	uint8_t rxData;
	for (int i = 0; i < strlen(str); i ++){
		UART_SendByte(UART0, str[i]);
		rxData = UART_RecvByte(UART0);
		xil_printf("%c", rxData);
	}

	while (1)
	{
		switch (modeState) {
		case TIME_CLOCK:
			TimeClock_Execute();
			Disp_SetMode(DISP_TIME_CLOCK);
			if (Button_GetState(&hbtnMode) == ACT_RELEASED) {
				modeState = UP_COUNTER;
				FND_SetDP(FND_DIGIT_100,OFF);
			}
			break;

		case UP_COUNTER:
			UpCounter_Execute();
			Disp_SetMode(DISP_UP_COUNTER);
			if (Button_GetState(&hbtnMode) == ACT_RELEASED) {
				modeState = TIME_CLOCK;
			}
			break;
		}
	}
}














