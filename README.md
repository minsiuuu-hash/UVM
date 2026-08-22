# UVM Verification Projects

This repository contains SystemVerilog UVM-based verification projects for memories, bus protocols, and serial communication IPs.

The main goal is to design reusable transaction-level testbenches and verify RTL behavior using constrained-random stimulus, scoreboards, functional coverage, and FPGA board tests.

The repository also includes a separate AXI4-Lite project that integrates custom GPIO, SPI, I2C, and UART peripherals with a MicroBlaze-based processor system and Vitis software.

---

## Project Overview

| Project | Description | Main Focus |
|---|---|---|
| [`RAM`](RAM/) | RAM verification using UVM | Random/write-read sequences, full address sweep, reference memory comparison |
| [`UART`](UART/) | UART verification using UVM | Serial bit driving, randomized 8-bit transactions, TX/RX comparison |
| [`UART2`](UART2/) | Additional UART verification project | Interface-based UART transaction verification |
| [`APB_RAM`](APB_RAM/) | APB-based RAM verification using UVM | SETUP/ACCESS phases, `PREADY` handling, read/write comparison |
| [`SPI`](SPI/) | SPI RTL design and UVM verification | Master/slave RTL, randomized transfer, coverage, two-board test |
| [`I2C`](I2C/) | I2C RTL design and UVM verification | START/STOP/ACK handling, randomized data transfer, two-board test |
| [`AXI`](AXI/) | AXI4-Lite peripheral IP and software verification | Custom slave IP, MicroBlaze integration, Vitis C/HAL, memory-mapped I/O |

For the complete AXI4-Lite architecture and software verification flow, see [AXI/README.md](AXI/README.md).

---

## UVM Testbench Architecture

The verification environments follow a reusable UVM testbench structure.

```text
Sequence Item
     |
     v
Sequence -> Sequencer -> Driver -> Interface -> DUT
                                             |
                                             v
Monitor -> Scoreboard -> Result
        -> Coverage
```

| Component | Responsibility |
|---|---|
| Sequence Item | Defines transaction-level data and constraints |
| Sequence | Generates directed or randomized transactions |
| Sequencer | Sends sequence items to the driver |
| Driver | Converts transactions into signal-level DUT stimulus |
| Interface | Connects the class-based testbench to RTL signals |
| Monitor | Samples DUT activity and reconstructs transactions |
| Scoreboard | Compares expected and actual results |
| Coverage | Measures whether important scenarios and data ranges were exercised |

---

## Verification Summary

| Target | Verification Focus |
|---|---|
| RAM | Random access, write-read sequence, full address sweep, reference memory comparison |
| UART | Start/data/stop bit driving, fixed bit timing, randomized TX/RX comparison |
| APB RAM | APB SETUP/ACCESS phases, `PREADY` wait, memory-model-based `PRDATA` comparison |
| SPI | Master/slave RTL, randomized 8-bit transfer, TX/RX matching, functional coverage, FPGA board test |
| I2C | START, address write, data write, ACK, STOP, received-data comparison, FPGA board test |
| AXI4-Lite | Custom slave wrappers, memory-mapped registers, Vitis software access, peripheral integration |

---

## RAM Verification

The RAM testbench verifies memory write and read behavior using a reference memory model in the scoreboard.

During a write transaction, the scoreboard stores the expected value in the reference memory. During a read transaction, it compares the DUT output with the stored reference value.

| Verification Item | Description |
|---|---|
| Random Sequence | Generates randomized addresses, data, and operations |
| Write-Read Sequence | Writes data and reads it back from the same address |
| Full Sweep Sequence | Accesses the complete address range |
| Scoreboard | Compares `rdata` with the reference memory |
| Coverage | Checks read/write operations, address ranges, data, and cross coverage |

---

## UART Verification

The UART testbench verifies serial TX/RX data transfer.

The driver generates the idle state, start bit, eight data bits, and stop bit according to the configured bit period. The monitor reconstructs the received transaction, and the scoreboard compares transmitted and received data.

| Verification Item | Description |
|---|---|
| Random Transaction | Generates randomized 8-bit UART data |
| Serial Driving | Drives idle, start, data, and stop bits |
| Monitor | Reconstructs received serial data |
| Scoreboard | Compares `tx_data` and `rx_data` |
| Coverage | Checks TX/RX values, match results, and cross coverage |

---

## APB RAM Verification

The APB RAM testbench verifies memory-mapped read and write transfers through the APB protocol.

The driver performs the SETUP and ACCESS phases and waits for `PREADY` before completing a transfer. The scoreboard stores write data in a reference memory and checks returned read data.

| Verification Item | Description |
|---|---|
| SETUP Phase | Drives `PSEL`, `PWRITE`, `PADDR`, and `PWDATA` |
| ACCESS Phase | Asserts `PENABLE` and waits for `PREADY` |
| Write-Read Sequence | Writes randomized data and reads it back |
| Scoreboard | Compares `PRDATA` with the reference memory |
| Coverage | Checks address ranges, operations, data, and address-operation crosses |

---

## SPI RTL Design and Verification

The SPI project includes master/slave RTL design, UVM simulation, functional coverage, and FPGA board verification.

The UVM testbench generates randomized 8-bit transmit data, starts the master transfer, observes the slave result, and compares transmitted and received data in the scoreboard.

After simulation, the design was tested using two Basys3 boards. One board operated as the SPI master and the other as the SPI slave.

| Verification Item | Description |
|---|---|
| RTL Design | SPI master and slave modules |
| Random Transaction | Randomized 8-bit transmit data |
| Master Transfer | Starts and controls serial transmission |
| Slave Receive | Captures serial data from the master |
| Scoreboard | Compares transmitted and received data |
| Coverage | Checks important values and data ranges |
| Board Test | Verifies communication between two Basys3 boards |

---

## I2C RTL Design and Verification

The I2C project includes master/slave RTL design, UVM simulation, ACK checking, functional coverage, and FPGA board verification.

The driver performs the following write transaction:

```text
START -> WRITE(address + W) -> WRITE(random data) -> ACK check -> STOP
```

The monitor captures transmitted and received data, and the scoreboard checks whether the slave received the expected value.

After simulation, the design was tested using two Basys3 boards configured as the I2C master and slave.

| Verification Item | Description |
|---|---|
| RTL Design | I2C master and slave modules |
| START/STOP | Generates and checks transaction boundaries |
| Address Write | Sends the slave address and write bit |
| Data Write | Sends randomized 8-bit data |
| ACK Check | Checks the slave response |
| Scoreboard | Compares transmitted and received data |
| Coverage | Checks important values and data ranges |
| Board Test | Verifies communication between two Basys3 boards |

---

## AXI4-Lite Peripheral Integration

The [`AXI`](AXI/) project focuses on hardware-software integration using custom AXI4-Lite slave peripherals.

GPIO, SPI, I2C, and UART IPs are connected to a MicroBlaze-based processor system and accessed through memory-mapped registers from Vitis C software. The AXI project is documented separately because it focuses on SoC integration and software verification in addition to RTL verification.

[View the complete AXI4-Lite project documentation](AXI/README.md)

---

## Results

Each project directory contains the available verification and implementation evidence.

| Result Directory | Description |
|---|---|
| `Sim_Result` | Simulation waveforms or console results |
| `Coverage_verdi` | Functional coverage results viewed with Verdi |
| `Timing` | Timing analysis results |
| `report` | Verification, synthesis, or implementation reports |

SPI and I2C also include board-level verification using two Basys3 FPGA boards.

---

## Presentation

SPI, I2C Project<br>
[260420_SPI_I2C_UVM_Verification_정민수.pdf](https://github.com/user-attachments/files/26885559/260420_SPI_I2C_UVM_Verification_.pdf)<br>
AXI Project<br>
[260508_SoC_AXI_Peripheral_정민수.pdf](https://github.com/user-attachments/files/28446928/260508_SoC_AXI_Peripheral_.pdf)
