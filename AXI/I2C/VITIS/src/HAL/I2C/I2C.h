#ifndef SRC_HAL_I2C_I2C_H_
#define SRC_HAL_I2C_I2C_H_

#include <stdint.h>
#include "xparameters.h"
#include "../../common/common.h"

typedef struct {
     uint32_t CR;        // 0x00
     uint32_t TXDATA;    // 0x04
     uint32_t UNUSED;    // 0x08
     uint32_t STATUS;    // 0x0C
} I2C_Typedef_t;

#define I2C_BASE_ADDR XPAR_I2C_0_S00_AXI_BASEADDR
#define I2C0 ((I2C_Typedef_t *)I2C_BASE_ADDR)

#define I2C_START_BIT   (1 << 0)
#define I2C_WRITE_BIT   (1 << 1)
#define I2C_READ_BIT    (1 << 2)
#define I2C_STOP_BIT    (1 << 3)

#define I2C_DONE_BIT    (1 << 8)
#define I2C_ACKOUT_BIT  (1 << 9)
#define I2C_BUSY_BIT    (1 << 10)

uint32_t I2C_ReadStatus(void);
uint8_t I2C_ReadRxData(void);
uint8_t I2C_ReadAckOut(void);

void I2C_Start(void);
void I2C_Stop(void);
uint8_t I2C_WriteRaw(uint8_t data);
uint8_t I2C_ReadRaw(void);

#endif /* SRC_HAL_I2C_I2C_H_ */
