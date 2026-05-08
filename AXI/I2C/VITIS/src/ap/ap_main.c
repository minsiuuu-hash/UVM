#include "ap_main.h"

hBtn_t hbtnStart;
hBtn_t hbtnWrite;
hBtn_t hbtnRead;

static uint8_t sw_data = 0;
static uint8_t rx_data = 0;
static uint8_t ack = 0;

void ap_init()
{
    Button_Init(&hbtnStart, GPIOB, GPIO_PIN_5);
    Button_Init(&hbtnWrite, GPIOB, GPIO_PIN_6);
    Button_Init(&hbtnRead,  GPIOB, GPIO_PIN_7);

    Led_Init();
    Switch_Init();

    LED_AllOff();
}

void ap_execute()
{
    sw_data = Switch_Read();

    if (Button_GetState(&hbtnStart) == ACT_PUSHED)
    {
        I2C_Start();

        GPIO_WritePort(GPIOC, 0x01);
    }

    if (Button_GetState(&hbtnWrite) == ACT_PUSHED)
    {
        ack = I2C_WriteRaw(sw_data);

        if (ack == 0)
        {
            GPIO_WritePort(GPIOC, 0x0A);
        }
        else
        {
            GPIO_WritePort(GPIOC, 0xF0);
        }
    }

    if (Button_GetState(&hbtnRead) == ACT_PUSHED)
    {
        rx_data = I2C_ReadRaw();

        GPIO_WritePort(GPIOC, rx_data);
    }
}
