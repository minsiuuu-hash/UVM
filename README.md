# UVM Verification Projects

This repository contains several SystemVerilog UVM-based verification projects.

The main goal of this repository is to build reusable UVM testbench structures and verify digital IPs and communication protocols such as RAM, UART, APB RAM, SPI, and I2C.

The `AXI` folder contains AXI-Lite peripheral wrapper and integration study materials for GPIO, SPI, I2C, and UART peripherals.

---

## Project List

| Project | Description | Main Focus |
|---|---|---|
| `RAM` | RAM verification using UVM | Write/read sequence, full address sweep, reference memory comparison |
| `UART` | UART verification using UVM | Random 8-bit UART transaction, serial bit driving, TX/RX data comparison |
| `UART2` | Additional UART verification project | UART transaction and interface-based verification |
| `APB_RAM` | APB-based RAM verification using UVM | APB setup/access phase, `PREADY` wait, write/read data comparison |
| `SPI` | SPI RTL design and UVM verification | Master/slave RTL design, random 8-bit transfer, data matching, and two-board Basys3 test |
| `I2C` | I2C RTL design and UVM verification | Master/slave RTL design, START/STOP/ACK check, data matching, and two-board Basys3 test |
| `AXI` | AXI-Lite peripheral wrapper and Vitis test | Vivado-generated processor system, memory-mapped register access, and peripheral integration |

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

## Code-Based Verification Focus

| Target | Verification Focus |
|---|---|
| RAM | Random sequence, write-read sequence, full address sweep, and reference memory based read-data comparison |
| UART | UART start/data/stop bit driving using fixed bit period and TX/RX data comparison |
| APB RAM | APB SETUP/ACCESS phase driving, `PREADY` wait, and `PRDATA` comparison using reference memory |
| SPI | SPI master/slave RTL design, random 8-bit transfer, `start` control, `slave_done` capture, TX/RX data matching, and two-board Basys3 test |
| I2C | I2C master/slave RTL design, START → address write → data write → STOP sequence, ACK check, received-data comparison, and two-board Basys3 test |
| AXI | AXI-Lite wrapper, Vivado-generated processor system, Vitis C code test, and memory-mapped peripheral access |

---

## RAM Verification

The RAM UVM testbench verifies memory write/read behavior using a reference memory model inside the scoreboard.

The sequence includes random transactions, write-read transactions, and full address sweep transactions.  
During write operation, the scoreboard stores write data into reference memory.  
During read operation, the scoreboard compares DUT read data with the expected value stored in the reference memory.

| Verification Item | Description |
|---|---|
| Random Sequence | Generates randomized RAM transactions |
| Write-Read Sequence | Writes data and reads it back |
| Full Sweep Sequence | Accesses the full address range |
| Scoreboard | Compares `rdata` with reference memory |
| Coverage | Checks write/read operation, address range, read data, and write-address cross coverage |

---

## UART Verification

The UART UVM testbench verifies serial TX/RX data transfer.

The driver sends UART data using start bit, 8 data bits, stop bit, and idle state based on a fixed bit period.  
The scoreboard compares the transmitted `tx_data` with the received `rx_data`.

| Verification Item | Description |
|---|---|
| Random Transaction | Generates randomized 8-bit UART data |
| UART Driving | Drives start bit, data bits, stop bit, and idle state |
| Scoreboard | Compares `tx_data` and `rx_data` |
| Coverage | Checks TX data, RX data, match result, and TX/RX cross coverage |

---

## APB RAM Verification

The APB RAM UVM testbench verifies APB-based memory access.

The driver performs APB transfer using SETUP and ACCESS phases.  
During ACCESS phase, the driver waits until `PREADY` is asserted.  
The scoreboard stores write data into a reference memory and compares read data with the expected value.

| Verification Item | Description |
|---|---|
| APB SETUP Phase | Drives `PSEL`, `PWRITE`, `PADDR`, and `PWDATA` |
| APB ACCESS Phase | Asserts `PENABLE` and waits for `PREADY` |
| Write-Read Sequence | Writes random data and reads it back |
| Scoreboard | Compares `PRDATA` with reference memory |
| Coverage | Checks address range, read/write operation, write data, read data, and address-RW cross coverage |

---

## SPI RTL Design and Verification

SPI is a synchronous serial communication protocol using `SCLK`, `MOSI`, `MISO`, and `CS` signals.

In this project, the SPI master and slave RTL modules were designed and verified.  
The RTL design was implemented to transfer 8-bit data serially between master and slave using SPI signals.

The SPI operation was first verified through a SystemVerilog UVM-based testbench.  
The UVM testbench generates random 8-bit transmit data, drives the SPI master using the `start` signal, and monitors the received slave data.  
The scoreboard compares the transmitted data and received data to check whether the SPI transfer works correctly.

After simulation, the SPI communication was also tested on hardware using two Basys3 FPGA boards.  
One board was used as the SPI master, and the other board was used as the SPI slave.  
The data transfer between the two boards was checked to verify that the SPI RTL design works correctly on real hardware.

| Verification Item | Description |
|---|---|
| RTL Design | Designed SPI master and slave modules |
| Random Transaction | Generates randomized 8-bit SPI data |
| Master Transfer | Sends data using `start` control |
| Slave Receive | Receives serial data from SPI master |
| Scoreboard | Compares transmitted data and received data |
| Coverage | Checks important TX data patterns and data ranges |
| Board Test | Verified SPI communication using two Basys3 boards |

---

## I2C RTL Design and Verification

I2C is a two-wire serial communication protocol using `SCL` and `SDA`.

In this project, the I2C master and slave RTL modules were designed and verified.  
The RTL design was implemented to transfer data using start condition, slave address, write data, ACK response, and stop condition.

The I2C operation was first verified through a SystemVerilog UVM-based testbench.  
The driver performs the transaction sequence using START, address write, data write, and STOP.  
The driver also checks the ACK response after the write operation.  
The monitor captures the transmitted data and slave received data, and the scoreboard compares them.

```text
START → WRITE(address + W) → WRITE(random data) → STOP
```

After simulation, the I2C communication was also tested on hardware using two Basys3 FPGA boards.  
One board was used as the I2C master, and the other board was used as the I2C slave.  
The data transfer and ACK response between the two boards were checked to verify that the I2C RTL design works correctly on real hardware.

| Verification Item | Description |
|---|---|
| RTL Design | Designed I2C master and slave modules |
| START Condition | Starts I2C transaction |
| Address Write | Sends slave address with write bit |
| Data Write | Sends randomized 8-bit data |
| ACK Check | Checks ACK response after write operation |
| STOP Condition | Ends I2C transaction |
| Scoreboard | Compares transmitted data and received slave data |
| Coverage | Checks important TX data patterns and data ranges |
| Board Test | Verified I2C communication using two Basys3 boards |

---

## AXI-Lite Peripheral Study

Unlike the previous RISC-V project, where peripherals were connected to a custom RISC-V CPU, this AXI project used a Vivado-generated processor system and AXI-Lite wrapper.  
The custom peripheral registers were accessed from Vitis C code through memory-mapped I/O.

The `AXI` folder contains AXI-Lite based peripheral wrapper and integration materials.

The AXI peripheral files include memory-mapped slave register interfaces and AXI-Lite channels for write address, write data, write response, read address, and read data.  
This part focuses on understanding AXI-Lite peripheral integration rather than a full UVM testbench structure.

| AXI Item | Description |
|---|---|
| GPIO | AXI-Lite GPIO peripheral wrapper |
| SPI | AXI-Lite SPI peripheral wrapper and result files |
| I2C | AXI-Lite I2C peripheral wrapper and result files |
| UART | AXI-Lite UART peripheral wrapper and result files |
| Vitis | Software-level peripheral access test materials |

---

## Results

Each project includes verification-related results such as simulation results, coverage results, timing results, reports, and hardware test results.

| Result Folder | Description |
|---|---|
| `Sim_Result` | Simulation waveform or console result |
| `Coverage_verdi` | Coverage result checked using Verdi |
| `Timing` | Timing-related result |
| `report` | Verification or synthesis report |

For SPI and I2C, the RTL designs were also verified on hardware using two Basys3 FPGA boards.  
One board operated as the master, and the other board operated as the slave.  
The board-level test was performed to check whether the designed communication protocol works correctly in real FPGA hardware.

---

## Presentation

SPI, I2C Project<br>
[260420_SPI_I2C_UVM_Verification_정민수.pdf](https://github.com/user-attachments/files/26885559/260420_SPI_I2C_UVM_Verification_.pdf)<br>
AXI Project<br>
[260508_SoC_AXI_Peripheral_정민수.pdf](https://github.com/user-attachments/files/28446928/260508_SoC_AXI_Peripheral_.pdf)
