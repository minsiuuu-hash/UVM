#include "ap_main.h"

hBtn_t hbtnStart;

static uint8_t tx_data = 0;
static uint8_t rx_data = 0;

static uint8_t spi_waiting = 0;
static uint8_t busy_seen = 0;

void ap_init()
{
    Button_Init(&hbtnStart, GPIOB, GPIO_PIN_5);

    Led_Init();
    Switch_Init();
    FND_Init();

    SPI_SetClkDiv(49);

    FND_SetNum(0);
    LED_AllOff();
}

void ap_execute()
{
    FND_DispDigit();

    tx_data = Switch_Read();

    if (!spi_waiting && Button_GetState(&hbtnStart) == ACT_PUSHED)
    {
        SPI_SetTxData(tx_data);
        SPI_Start(0, 0);

        spi_waiting = 1;
        busy_seen = 0;
    }

    if (spi_waiting)
    {
        if (SPI_IsBusy())
        {
            busy_seen = 1;
        }

        if (busy_seen && !SPI_IsBusy())
        {
            rx_data = SPI_ReadRxData();

            GPIO_WritePort(GPIOC, rx_data);
            FND_SetNum(rx_data);

            spi_waiting = 0;
            busy_seen = 0;
        }
    }
}
