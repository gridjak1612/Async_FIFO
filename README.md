# Asynchronous FIFO – Dual-Clock Domain Communication

## Description
This project implements an **asynchronous FIFO** in **Verilog HDL** to
safely transfer data between **independent write and read clock domains**.
Clock domain crossing (CDC) is handled with **Gray-coded pointers** and
**dual flip-flop synchronizers**, and full/empty detection is performed
directly in the Gray domain.

## Specifications
| Parameter        | Value                                   |
|------------------|-----------------------------------------|
| Data width       | 8 bits                                  |
| Depth            | 8 entries                               |
| Pointer width    | 4 bits (3 address bits + 1 wrap bit)    |
| Read latency     | 1 read-clock cycle (registered output)  |
| Synchronizer     | 2-flop synchronizer + 1 margin register |
| Flag comparison  | Directly in Gray code                   |

## Architecture
```
            wr_clk domain                         rd_clk domain
  wr_en ──►┌──────────────┐                 ┌──────────────┐◄── rd_en
  wr_data─►│ wr_ptr (bin) │──► mem[7:0] ───►│ rd_ptr (bin) │──► rd_data
           │ wr_ptr_gray  │──► ff1→ff2→sync ►│ empty logic  │──► empty
  full ◄───│ full logic   │◄── sync←ff2←ff1 ◄│ rd_ptr_gray  │
           └──────────────┘                 └──────────────┘
```

### Key Design Points
- **Binary pointers** address the memory using the lower 3 bits;
  the MSB is a wrap bit that distinguishes *full* from *empty*.
- **Gray pointers are registered in the source domain**, so only
  clean, glitch-free values with a single-bit change per increment
  cross into the other clock domain.
- **Synchronization:** each Gray pointer passes through a 2-flop
  synchronizer (`ff1 → ff2`) followed by an extra register stage
  (`sync`) for additional metastability margin.
- **Empty** (read domain): `rd_ptr_gray == wr_ptr_gray_sync`
- **Full** (write domain): write Gray pointer equals the synchronized
  read Gray pointer with its **top two bits inverted**.
- Flags are **pessimistic**: because each domain sees a slightly
  delayed copy of the other pointer, the FIFO may briefly report
  full/empty longer than necessary, but it can **never overflow or
  underflow**.

## File Structure
| File                   | Description                                  |
|------------------------|----------------------------------------------|
| `asynchronous_fifo.v`  | FIFO RTL (`async_fifo` module)               |
| `test_1_async_fifo.v`  | Testbench 1: write fast (10 ns), read slow (20 ns) – exercises FULL |
| `test_2_async_fifo.v`  | Testbench 2: write slow (20 ns), read fast (10 ns) – exercises EMPTY |

## Verification
| Testbench | Write clk | Read clk | Scenario                                        |
|-----------|-----------|----------|-------------------------------------------------|
| Test 1    | 10 ns     | 20 ns    | 10 write attempts into 8-deep FIFO → FULL asserted, then drain |
| Test 2    | 20 ns     | 10 ns    | 5 writes, 10 read attempts → EMPTY asserted     |

Checked in both tests:
- Correct full and empty flag generation
- Data integrity (data read out in the same order it was written)
- Pointer synchronization latency across domains

## How to Run

### Icarus Verilog + GTKWave
```bash
# Test 1
iverilog -o test1.vvp asynchronous_fifo.v test_1_async_fifo.v
vvp test1.vvp
gtkwave FIFO_test1.vcd

# Test 2
iverilog -o test2.vvp asynchronous_fifo.v test_2_async_fifo.v
vvp test2.vvp
gtkwave FIFO_test2.vcd
```

### Xilinx Vivado
1. Create a project and add `asynchronous_fifo.v` as a design source.
2. Add one testbench as a simulation source and set it as top.
3. Run Behavioral Simulation and inspect the waveform.

## Future Improvements
- Per-domain reset synchronizers (asynchronous assert, synchronous deassert)
- Parameterized data width and depth
- `almost_full` / `almost_empty` flags and overflow/underflow error flags
- Self-checking constrained-random testbench with truly unrelated clocks
  and simultaneous read/write
- SystemVerilog assertions and CDC timing constraints (`ASYNC_REG`,
  `set_max_delay -datapath_only`)