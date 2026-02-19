# Asynchronous FIFO – Dual-Clock Domain Communication

## Description
This project implements an **asynchronous FIFO** in **Verilog HDL** to safely transfer data between **independent read and write clock domains**.  
The design uses **Gray-coded pointers** and **dual flip-flop synchronization** to handle clock domain crossing (CDC) and avoid metastability.

The FIFO is verified using multiple testbenches with **asymmetric clock rates** to validate correct full/empty behavior and data integrity.

---

## Design Overview
- Independent **write clock** and **read clock** domains
- Binary read/write pointers with **Gray code conversion**
- Dual flip-flop synchronizers for pointer crossing
- Full and empty detection based on synchronized Gray pointers
- Simple memory array used as FIFO storage

---

## Key Features
- Safe CDC using Gray-coded pointers
- Dual flip-flop synchronization for metastability reduction
- Correct full and empty flag generation
- Supports write-faster/read-slower and read-faster/write-slower scenarios

---

## FIFO Operation
- **Write side** increments the write pointer when `wr_en` is asserted and FIFO is not full
- **Read side** increments the read pointer when `rd_en` is asserted and FIFO is not empty
- Read and write pointers are synchronized across clock domains using two-stage flip-flops
- Full and empty conditions are detected directly in the Gray code domain

---

## Verification
The FIFO is verified using **two custom Verilog testbenches**:

### Testbench Coverage
- Write faster than read clock
- Read faster than write clock
- Full and empty condition validation
- Data integrity across clock domains

Waveforms are generated in `.vcd` format and inspected using **GTKWave**.

