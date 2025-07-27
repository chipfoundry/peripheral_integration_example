# User Project Tests

This directory contains testbenches for the SPI/UART integration user project.

## Test Structure

### SPI/UART Integration Tests (`spi_uart_integration/`)
- **spi_uart_basic**: Tests basic GPIO functionality and initial states
- **spi_uart_wishbone**: Tests Wishbone bus access to registers
- **spi_uart_interrupts**: Tests interrupt functionality
- **spi_uart_gpio_control**: Tests GPIO control of enable signals
- **spi_uart_logic_analyzer**: Tests logic analyzer integration

### SPI/UART Wishbone Tests (`spi_uart_wishbone/`)
- **spi_uart_wishbone_basic**: Tests basic Wishbone connectivity
- **spi_uart_wishbone_registers**: Tests control register access
- **spi_uart_wishbone_data_transfer**: Tests data transfer to SPI/UART IPs

## GPIO Pin Mapping

- **GPIO 5**: SPI MOSI (output)
- **GPIO 6**: SPI MISO (input)
- **GPIO 7**: SPI SCLK (output)
- **GPIO 8**: SPI CSB (output)
- **GPIO 9**: UART TX (output)
- **GPIO 10**: UART RX (input)
- **GPIO 11**: SPI activity LED (output)
- **GPIO 12**: UART activity LED (output)
- **GPIO 13**: SPI enable control (input)
- **GPIO 14**: UART enable control (input)

## Running Tests

Use the standard cocotb test framework to run these tests against the SPI/UART integration design.
 
