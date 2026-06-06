# UVM Verification Projects

This repository contains several SystemVerilog UVM-based verification projects.

The main goal of this repository is to build reusable UVM testbench structures and verify digital IPs and communication protocols such as RAM, UART, APB RAM, SPI, I2C, and AXI-based peripherals.

---

## Project List

| Project | Description | Main Verification Focus |
|---|---|---|
| `RAM` | RAM verification using UVM | Read/write operation and data comparison |
| `UART` | UART verification using UVM | TX/RX transaction, serial timing, and scoreboard comparison |
| `UART2` | Additional UART verification project | UART transaction and interface-based verification |
| `APB_RAM` | APB-based RAM verification | APB transfer, address/data/control signal check |
| `SPI` | SPI protocol verification using UVM | Master/slave serial transfer and data matching |
| `I2C` | I2C protocol verification using UVM | Start/stop condition, data transfer, and ACK check |
| `AXI` | AXI-based peripheral verification | AXI handshake, address/data transfer, and peripheral access |
| `STUDY` | UVM study materials | Basic UVM structure and practice examples |

---

## UVM Testbench Architecture

The verification environment was built using a typical UVM testbench structure.

```text
Sequence Item
     ↓
Sequence
     ↓
Sequencer
     ↓
Driver
     ↓
Interface
     ↓
DUT
     ↓
Monitor
     ↓
Scoreboard
```

The sequence generates transaction-level stimulus, and the driver converts the transaction into signal-level behavior through the interface.  
The monitor observes DUT output signals and sends the collected data to the scoreboard.  
The scoreboard compares the expected data with the actual DUT output and checks whether the test passed or failed.

---

## Main Verification Points

| Target | Verification Point |
|---|---|
| RAM | Read/write data consistency |
| UART | Serial TX/RX timing and transmitted/received data matching |
| APB RAM | APB setup/access phase and `PREADY` handshake |
| SPI | Serial shift operation and master/slave data transfer |
| I2C | Start condition, stop condition, data transfer, and ACK response |
| AXI | `VALID/READY` handshake, address channel, data channel, and response check |

---

## SPI Verification

SPI is a synchronous serial communication protocol using `SCLK`, `MOSI`, `MISO`, and `SS/CS` signals.

In this project, SPI master/slave communication was verified using a UVM-based testbench.  
The driver generates SPI transactions, and the monitor samples transferred data from the SPI interface.  
The scoreboard compares the expected data and received data to check whether the serial transfer operation works correctly.

| Verification Point | Description |
|---|---|
| Serial Transfer | Checks whether data is transferred bit by bit through SPI signals |
| Master/Slave Operation | Verifies communication between SPI master and slave |
| Data Matching | Compares transmitted data and received data |
| Scoreboard Check | Checks PASS/FAIL based on expected and actual data |

---

## I2C Verification

I2C is a two-wire serial communication protocol using `SCL` and `SDA`.

In this project, I2C communication was verified using a UVM-based testbench.  
The verification focused on start condition, stop condition, data transfer, and ACK response.  
The monitor observes the `SCL` and `SDA` signals, and the scoreboard checks whether the received data matches the expected transaction.

| Verification Point | Description |
|---|---|
| Start Condition | Checks whether communication starts correctly |
| Stop Condition | Checks whether communication ends correctly |
| Data Transfer | Verifies serial data transfer through `SDA` |
| ACK Response | Checks acknowledge response after data transfer |
| Scoreboard Check | Compares expected data and received data |

---

## AXI Peripheral Verification

AXI is an AMBA bus protocol that uses independent channels for address, data, and response transfers.

In this project, AXI-based peripheral communication was verified using a UVM-based testbench.  
The verification focused on `VALID/READY` handshake, address transfer, write/read data transfer, and response checking.

| Verification Point | Description |
|---|---|
| `VALID/READY` Handshake | Checks whether each AXI transfer occurs only when both valid and ready are asserted |
| Address Transfer | Verifies write/read address channel operation |
| Write Data Transfer | Checks whether write data is transferred correctly |
| Read Data Transfer | Checks whether read data is returned correctly |
| Response Check | Verifies response signals after transfer |
| Peripheral Access | Checks AXI-based access to peripherals such as GPIO, SPI, I2C, and UART |

---

## Results

Each project includes verification-related results such as simulation results, coverage results, timing results, or reports.

| Result Folder | Description |
|---|---|
| `Sim_Result` | Simulation waveform or console result |
| `Coverage_verdi` | Coverage result checked using Verdi |
| `Timing` | Timing-related result |
| `report` | Verification or synthesis report |

---

## Presentation
SPI, I2C Project<br>
-[260420_SPI_I2C_UVM_Verification_정민수.pdf](https://github.com/user-attachments/files/26885559/260420_SPI_I2C_UVM_Verification_.pdf)<br>
AXI Project<br>
-[260508_SoC_AXI_Peripheral_정민수.pdf](https://github.com/user-attachments/files/28446928/260508_SoC_AXI_Peripheral_.pdf)
