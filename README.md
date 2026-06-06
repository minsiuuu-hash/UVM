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
| `SPI` | SPI protocol verification using UVM | Random 8-bit SPI transfer, master transmit, slave receive data matching |
| `I2C` | I2C protocol verification using UVM | START/address write/data write/STOP sequence, ACK check, data matching |
| `AXI` | AXI-Lite peripheral wrapper and study | Memory-mapped register interface and peripheral integration |
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

## Code-Based Verification Focus

| Target | Verification Focus |
|---|---|
| RAM | Random sequence, write-read sequence, full address sweep, and reference memory based read-data comparison |
| UART | UART start/data/stop bit driving using fixed bit period and TX/RX data comparison |
| APB RAM | APB SETUP/ACCESS phase driving, `PREADY` wait, and `PRDATA` comparison using reference memory |
| SPI | Random 8-bit SPI transfer, `start` control, `slave_done` capture, and TX/RX data matching |
| I2C | START → address write → data write → STOP sequence, ACK check, and received-data comparison |
| AXI | AXI-Lite slave register wrapper and memory-mapped peripheral integration study |

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

## SPI Verification

SPI is a synchronous serial communication protocol using `SCLK`, `MOSI`, `MISO`, and `CS` signals.

The SPI UVM testbench generates random 8-bit transmit data.  
The driver sends the data through the SPI master using the `start` signal.  
The monitor captures transmit data and received slave data, and the scoreboard compares them.

| Verification Item | Description |
|---|---|
| Random Transaction | Generates randomized 8-bit SPI data |
| Master Transfer | Sends data using `start` control |
| Receive Capture | Captures received data when `slave_done` is asserted |
| Scoreboard | Compares transmitted data and received data |
| Coverage | Checks important TX data patterns and data ranges |

---

## I2C Verification

I2C is a two-wire serial communication protocol using `SCL` and `SDA`.

The I2C UVM testbench verifies write transaction behavior.  
The driver performs the transaction sequence using START, address write, data write, and STOP.  
The driver also checks ACK response after write operation.  
The monitor captures written data and slave received data, and the scoreboard compares them.

```text
START → WRITE(address + W) → WRITE(random data) → STOP
```

| Verification Item | Description |
|---|---|
| START Condition | Starts I2C transaction |
| Address Write | Sends slave address with write bit |
| Data Write | Sends randomized 8-bit data |
| ACK Check | Checks ACK response after write operation |
| STOP Condition | Ends I2C transaction |
| Scoreboard | Compares transmitted data and received slave data |
| Coverage | Checks important TX data patterns and data ranges |

---

## AXI-Lite Peripheral Study

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
[260420_SPI_I2C_UVM_Verification_정민수.pdf](https://github.com/user-attachments/files/26885559/260420_SPI_I2C_UVM_Verification_.pdf)<br>
AXI Project<br>
[260508_SoC_AXI_Peripheral_정민수.pdf](https://github.com/user-attachments/files/28446928/260508_SoC_AXI_Peripheral_.pdf)
