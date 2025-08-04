# UART/SPI Test Suite

This directory contains comprehensive tests for validating the UART/SPI maximized user project design.

## Test Overview

The test suite validates that your design with 7 UARTs and 6 SPIs (13 total peripherals) is correctly integrated into the user_project_wrapper and that all peripherals can be read/written through the Wishbone interface.

## Test Structure

### 1. uart_spi_wb_test
**Purpose**: Validates Wishbone interface access to all UART and SPI peripherals
**Files**: 
- `uart_spi_wb_test.c` - Firmware that tests register access
- `uart_spi_wb_test.py` - Cocotb test that monitors GPIO signals
- `uart_spi_wb_test.yaml` - Test configuration

**What it tests**:
- Write/read operations to all UART control registers
- Write/read operations to all SPI control registers
- Proper address decoding for each peripheral
- Wishbone interface functionality

### 2. uart_spi_io_test
**Purpose**: Validates I/O pin connections and functionality
**Files**:
- `uart_spi_io_test.c` - Firmware that enables peripherals and drives pins
- `uart_spi_io_test.py` - Cocotb test that monitors pin states
- `uart_spi_io_test.yaml` - Test configuration

**What it tests**:
- UART TX pin activation when UARTs are enabled
- SPI output pin configuration (MOSI, SCLK, CS)
- Proper pin direction configuration (io_oeb signals)
- I/O pin connectivity

### 3. uart_spi_reg_test
**Purpose**: Validates register access and address decoding
**Files**:
- `uart_spi_reg_test.c` - Firmware that tests register write/read cycles
- `uart_spi_reg_test.py` - Cocotb test that monitors test completion
- `uart_spi_reg_test.yaml` - Test configuration

**What it tests**:
- Write/read verification for all registers
- Address decoding accuracy
- Error detection for failed register access
- Peripheral isolation (no cross-talk between peripherals)

### 4. uart_spi_comprehensive_test
**Purpose**: Complete validation of all aspects in one test
**Files**:
- `uart_spi_comprehensive_test.c` - Comprehensive firmware test
- `uart_spi_comprehensive_test.py` - Complete validation test
- `uart_spi_comprehensive_test.yaml` - Test configuration

**What it tests**:
- All register access patterns
- Address decoding for all peripherals
- Invalid address handling
- I/O pin verification
- Complete system integration

## Pin Mapping

### UART Peripherals (7 total)
| UART | RX Pin | TX Pin | Address Range | GPIO Test Signal |
|------|--------|--------|---------------|------------------|
| UART0 | io_in[0] | io_out[1] | 0x3000_0000 - 0x3000_0FFF | GPIO 2 |
| UART1 | io_in[2] | io_out[3] | 0x3000_1000 - 0x3000_1FFF | GPIO 3 |
| UART2 | io_in[4] | io_out[5] | 0x3000_2000 - 0x3000_2FFF | GPIO 4 |
| UART3 | io_in[6] | io_out[7] | 0x3000_3000 - 0x3000_3FFF | GPIO 5 |
| UART4 | io_in[8] | io_out[9] | 0x3000_4000 - 0x3000_4FFF | GPIO 6 |
| UART5 | io_in[10] | io_out[11] | 0x3000_5000 - 0x3000_5FFF | GPIO 7 |
| UART6 | io_in[12] | io_out[13] | 0x3000_6000 - 0x3000_6FFF | GPIO 8 |

### SPI Peripherals (6 total)
| SPI | MISO Pin | MOSI Pin | SCLK Pin | CS Pin | Address Range | GPIO Test Signal |
|-----|----------|----------|----------|--------|---------------|------------------|
| SPI0 | io_in[14] | io_out[15] | io_out[16] | io_out[17] | 0x3000_7000 - 0x3000_7FFF | GPIO 9 |
| SPI1 | io_in[18] | io_out[19] | io_out[20] | io_out[21] | 0x3000_8000 - 0x3000_8FFF | GPIO 10 |
| SPI2 | io_in[22] | io_out[23] | io_out[24] | io_out[25] | 0x3000_9000 - 0x3000_9FFF | GPIO 11 |
| SPI3 | io_in[26] | io_out[27] | io_out[28] | io_out[29] | 0x3000_A000 - 0x3000_AFFF | GPIO 12 |
| SPI4 | io_in[30] | io_out[31] | io_out[32] | io_out[33] | 0x3000_B000 - 0x3000_BFFF | GPIO 13 |
| SPI5 | io_in[34] | io_out[35] | io_out[36] | io_out[37] | 0x3000_C000 - 0x3000_CFFF | GPIO 14 |

## Running the Tests

### Prerequisites
1. Ensure your design is synthesized and the netlist is available
2. Verify that the user_project_wrapper.v file contains your UART/SPI design
3. Make sure the cocotb environment is set up

### Running Individual Tests

```bash
# Navigate to the test directory
cd verilog/dv/cocotb/user_proj_tests

# Run the comprehensive test (recommended)
make uart_spi_comprehensive_test

# Run individual tests
make uart_spi_wb_test
make uart_spi_io_test
make uart_spi_reg_test
```

### Running All Tests

```bash
# Run all tests including the original counter tests
make all

# Run only UART/SPI tests
make uart_spi_wb_test uart_spi_io_test uart_spi_reg_test uart_spi_comprehensive_test
```

## Test Results

### Success Indicators
- All tests complete without timeouts
- GPIO signals show proper progression (2-8 for UARTs, 9-14 for SPIs)
- Final GPIO 0 signal indicates successful completion
- No error signals (GPIO 0xFF)

### Failure Indicators
- Test timeouts
- GPIO 0xFF error signal
- Missing GPIO progression signals
- Assertion failures in Python tests

## Debugging

### Common Issues
1. **Address Decoding**: Verify peripheral_sel signals in your design
2. **Wishbone Interface**: Check wbs_ack_o and wbs_dat_o connections
3. **I/O Configuration**: Ensure io_oeb signals are properly set
4. **Clock/Reset**: Verify wb_clk_i and wb_rst_i connections

### Debug Commands
```bash
# Run with verbose output
make uart_spi_comprehensive_test SIM_ARGS="-v"

# Run with waveform generation
make uart_spi_comprehensive_test SIM_ARGS="-v --wave=uart_spi_test.vcd"
```

## Expected Behavior

### UART Tests
- Each UART should respond to its specific address range
- TX pins should become active when UART is enabled
- Register write/read operations should succeed
- No cross-talk between UART peripherals

### SPI Tests
- Each SPI should respond to its specific address range
- Output pins (MOSI, SCLK, CS) should be configured as outputs
- Register write/read operations should succeed
- No cross-talk between SPI peripherals

### Integration Tests
- All 13 peripherals should be accessible
- Address decoding should be accurate
- Invalid addresses should not cause crashes
- GPIO monitoring should show proper test progression 