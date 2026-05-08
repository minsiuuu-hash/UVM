#include "I2C.h"

uint32_t I2C_ReadStatus()
{
    return I2C0->STATUS;
}

uint8_t I2C_ReadRxData()
{
    return (uint8_t)(I2C0->STATUS & 0xFF);
}

uint8_t I2C_ReadAckOut()
{
    return (I2C_ReadStatus() & I2C_ACKOUT_BIT) ? 1 : 0;
}

static void I2C_CommandPulse(uint32_t cmd)
{
    I2C0->CR = cmd;
    I2C0->CR = 0;

    delay_ms(5);
}

void I2C_Start()
{
    I2C_CommandPulse(I2C_START_BIT);
}

void I2C_Stop()
{
    I2C_CommandPulse(I2C_STOP_BIT);
}

uint8_t I2C_WriteRaw(uint8_t data)
{
    I2C0->TXDATA = data;

    I2C_CommandPulse(I2C_WRITE_BIT);

    return I2C_ReadAckOut();
}

uint8_t I2C_ReadRaw()
{
    I2C_CommandPulse(I2C_READ_BIT);

    return I2C_ReadRxData();
}
