# Hack Instruction Set

## A Instructions

A instructions set the A-register to whatever the operand is.

|          | Instruction        | Note                           |
|----------|--------------------|--------------------------------|
| symbolic | `@xxx`             | `xxx` is 0 - 32767             |
| binary   | `0vvvvvvvvvvvvvvv` | 15-bit representation of `xxx` |

### Predefined Symbols
|  symbol   | value |
|   `R0`    |   0   |
|    ...    |  ...  |
|   `R15`   |  15   |
|   `SP`    |   0   |
|   `LCL`   |   1   |
|   `ARG`   |   2   |
|  `THIS`   |   3   |
|  `THAT`   |   4   |
| `SCREEN`  | 16384 |
|   `KBD`   | 24576 |

## C Instructions

|          | Instruction        | Note       |
|----------|--------------------|------------|
| symbolic | `dest=comp;jump`   | `comp` req |
| binary   | `111accccccdddjjj` | see below  |

```
 1 1 1 a c c c c c c d d d j j j
 | |_| | |_________| |___| |___|
 |  |  |      |        |     |
 |  \  \    comp     dest  jump
 |   \  register select
 op   not used, must be '11'
```

### Computation

| `a`=0 | `a`=1 | comp          |
|-------|-------|---------------|
|  `0`  |       | `1 0 1 0 1 0` |
|  `1`  |       | `1 1 1 1 1 1` |
| `-1`  |       | `1 1 1 0 1 0` |
|  `D`  |       | `0 0 1 1 0 0` |
|  `A`  |  `M`  | `1 1 0 0 0 0` |
| `!D`  | `!M`  | `1 1 0 0 0 1` |
| `-D`  |       | `0 0 1 1 1 1` |
| `-A`  | `-M`  | `1 1 0 0 1 1` |
| `D+1` |       | `0 1 1 1 1 1` |
| `A+1` | `M+1` | `1 1 0 1 1 1` |
| `D-1` |       | `0 0 1 1 1 0` |
| `A-1` | `M-1` | `1 1 0 0 1 0` |
| `D+A` | `D+M` | `0 0 0 0 1 0` |
| `D-A` | `D-M` | `0 1 0 0 1 1` |
| `A-D` | `M-D` | `0 0 0 1 1 1` |
| `D&A` | `D&M` | `0 0 0 0 0 0` |
| `D|A` | `D|M` | `0 1 0 1 0 1` |

### Destination

| dest  | `d d d` |
|-------|---------|
| null  | `0 0 0` |
|  `M`  | `0 0 1` |
|  `D`  | `0 1 0` |
| `DM`  | `0 1 1` |
|  `A`  | `1 0 0` |
| `AM`  | `1 0 1` |
| `AD`  | `1 1 0` |
| `ADM` | `1 1 1` |

### Jump

| jump  | `j j j` | effect    |
|-------|---------|-----------|
| null  | `0 0 0` | no jump   |
| `JGT` | `0 0 1` | comp >  0 |
| `JEQ` | `0 1 0` | comp =  0 |
| `JGE` | `0 1 1` | comp >= 0 |
| `JLT` | `1 0 0` | comp <  0 |
| `JNE` | `1 0 1` | comp != 0 |
| `JLE` | `1 1 0` | comp <= 0 |
| `JMP` | `1 1 1` | always    |

# Emulator Design

Tick-Tock (Read-Write) Cycle

Tick: read data from RAM/ROM and put into registers
Tock: process data and write to RAM

A little deviation from the HDL of the original nand2tetris design, the registers read in from the ALU, however, given the tick/dock of this emulator design, it takes 2 clock cycles to get data into the ALU (given it does calculations on the tock) - an internal `alu_busy` state indicates to the emulator that we're gonna take another clock cycle. When busy, the program counter will not increment.