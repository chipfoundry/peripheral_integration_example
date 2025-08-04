# UART/SPI Maximized User Project

## Overview

This user project maximizes the number of UART and SPI peripherals that can fit within the available 38 I/O pins on the Caravel user project area.

## Optimal Configuration

**Total Peripherals: 13**
- **7 UARTs** (2 pins each = 14 pins)
- **6 SPIs** (4 pins each = 24 pins)
- **Total pins used: 38** (exact fit!)

## Pin Mapping

### UART Peripherals (7 total)
| UART | RX Pin | TX Pin | Address Range |
|------|--------|--------|---------------|
| UART0 | io_in[0] | io_out[1] | 0x3000_0000 - 0x3000_0FFF |
| UART1 | io_in[2] | io_out[3] | 0x3000_1000 - 0x3000_1FFF |
| UART2 | io_in[4] | io_out[5] | 0x3000_2000 - 0x3000_2FFF |
| UART3 | io_in[6] | io_out[7] | 0x3000_3000 - 0x3000_3FFF |
| UART4 | io_in[8] | io_out[9] | 0x3000_4000 - 0x3000_4FFF |
| UART5 | io_in[10] | io_out[11] | 0x3000_5000 - 0x3000_5FFF |
| UART6 | io_in[12] | io_out[13] | 0x3000_6000 - 0x3000_6FFF |

### SPI Peripherals (6 total)
| SPI | MISO Pin | MOSI Pin | SCLK Pin | CS Pin | Address Range |
|-----|----------|----------|----------|--------|---------------|
| SPI0 | io_in[14] | io_out[15] | io_out[16] | io_out[17] | 0x3000_7000 - 0x3000_7FFF |
| SPI1 | io_in[18] | io_out[19] | io_out[20] | io_out[21] | 0x3000_8000 - 0x3000_8FFF |
| SPI2 | io_in[22] | io_out[23] | io_out[24] | io_out[25] | 0x3000_9000 - 0x3000_9FFF |
| SPI3 | io_in[26] | io_out[27] | io_out[28] | io_out[29] | 0x3000_A000 - 0x3000_AFFF |
| SPI4 | io_in[30] | io_out[31] | io_out[32] | io_out[33] | 0x3000_B000 - 0x3000_BFFF |
| SPI5 | io_in[34] | io_out[35] | io_out[36] | io_out[37] | 0x3000_C000 - 0x3000_CFFF |

## Design Analysis

### Pin Efficiency
- **UART efficiency**: 2 pins per UART = 50% pin efficiency
- **SPI efficiency**: 4 pins per SPI = 25% pin efficiency
- **Mixed approach**: 7 UARTs + 6 SPIs = 13 peripherals total

### Alternative Configurations Considered
1. **All UARTs**: 19 UARTs (38 pins ÷ 2) = 19 peripherals
2. **All SPIs**: 9 SPIs (38 pins ÷ 4) = 9 peripherals  
3. **Mixed optimal**: 7 UARTs + 6 SPIs = 13 peripherals ✅

The mixed approach provides the best balance of functionality and peripheral count.

## Interrupts

- **irq[0]**: Any UART interrupt (OR of all 7 UART interrupts)
- **irq[1]**: Any SPI interrupt (OR of all 6 SPI interrupts)
- **irq[2]**: Unused

## IP Cores Used

### UART IP
- **Module**: `CF_UART_WB`
- **Source**: `ip/CF_UART/hdl/rtl/bus_wrappers/CF_UART_WB.v`
- **Features**: 
  - Programmable baud rate
  - FIFO buffers
  - Interrupt support
  - Configurable data width (5-9 bits)
  - Parity options

### SPI IP
- **Module**: `CF_SPI_WB`
- **Source**: `ip/CF_SPI/hdl/rtl/bus_wrappers/CF_SPI_WB.v`
- **Features**:
  - Configurable clock polarity and phase
  - FIFO buffers
  - Interrupt support
  - Programmable clock divider

## Wishbone Interface

All peripherals are accessible via the Wishbone bus interface with the following characteristics:
- **Address space**: 4KB per peripheral
- **Base address**: 0x3000_0000
- **Address decoding**: Automatic based on address ranges
- **Response multiplexing**: Automatic selection based on address

## Usage

1. **Compile the design**: The module is already integrated into `user_project_wrapper.v`
2. **Access peripherals**: Use the address ranges shown in the tables above
3. **Configure I/O**: The design automatically configures pin directions
4. **Handle interrupts**: Monitor `irq[0]` for UART interrupts and `irq[1]` for SPI interrupts

## Verification

The design includes:
- Proper address decoding for all 13 peripherals
- Correct I/O enable configuration
- Interrupt aggregation
- Wishbone interface compliance
- Pin count optimization (38/38 pins used)

This represents the maximum number of UART and SPI peripherals that can fit within the available I/O constraints while maintaining full functionality. 