// SPDX-FileCopyrightText: 2025 ChipFoundry, a DBA of Umbralogic Technologies LLC

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//      http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// SPDX-License-Identifier: Apache-2.0

#include <firmware_apis.h>

// UART register offsets (based on CF_UART_regs.h)
#define UART_RXDATA          0x00    // Read-only data register
#define UART_TXDATA          0x04    // Write-only data register
#define UART_PR              0x08    // Prescale register
#define UART_CTRL            0x0C    // Control register
#define UART_CFG             0x10    // Configuration register
#define UART_MATCH           0x18    // Match register

// SPI register offsets (based on CF_SPI_regs.h)
#define SPI_RXDATA           0x00    // Read-only data register
#define SPI_TXDATA           0x04    // Write-only data register
#define SPI_CFG              0x08    // Configuration register
#define SPI_CTRL             0x0C    // Control register
#define SPI_PR               0x10    // Prescale register
#define SPI_STATUS           0x14    // Status register

// UART base addresses
#define UART0_BASE   0x30000000
#define UART1_BASE   0x30001000
#define UART2_BASE   0x30002000
#define UART3_BASE   0x30003000
#define UART4_BASE   0x30004000
#define UART5_BASE   0x30005000
#define UART6_BASE   0x30006000

// SPI base addresses
#define SPI0_BASE    0x30007000
#define SPI1_BASE    0x30008000
#define SPI2_BASE    0x30009000
#define SPI3_BASE    0x3000A000
#define SPI4_BASE    0x3000B000
#define SPI5_BASE    0x3000C000

void main() {
    // Enable management GPIO as output to use as indicator for finishing configuration
    ManagmentGpio_outputEnable();
    ManagmentGpio_write(0);
    
    enableHkSpi(0); // disable housekeeping spi
    
    // Configure all GPIOs as user output for monitoring
    GPIOs_configureAll(GPIO_MODE_USER_STD_OUT_MONITORED);
    GPIOs_loadConfigs(); // load the configuration
    
    User_enableIF(); // enable interface for wishbone communication
    
    ManagmentGpio_write(1); // configuration finished
    
    // Test UART TX pins (odd-numbered pins 1,3,5,7,9,11,13)
    // Each UART TX pin should be driven high when UART is enabled
    for (int uart = 0; uart < 7; uart++) {
        int tx_pin = uart * 2 + 1;  // UART TX pins: 1,3,5,7,9,11,13
        
        // Enable UART and TX
        uint32_t base_addr = UART0_BASE + (uart * 0x1000);
        USER_writeWord(base_addr + UART_CTRL, 0x7);  // Enable UART, TX, and RX
        
        // Set GPIO to indicate UART TX test
        ManagmentGpio_write(uart + 2);
    }
    
    // Test SPI output pins (pins 15,16,17,19,20,21,23,24,25,27,28,29,31,32,33,35,36,37)
    // Each SPI should drive its output pins when enabled
    for (int spi = 0; spi < 6; spi++) {
        int mosi_pin = 15 + spi * 4;  // SPI MOSI pins: 15,19,23,27,31,35
        int sclk_pin = 16 + spi * 4;  // SPI SCLK pins: 16,20,24,28,32,36
        int cs_pin = 17 + spi * 4;    // SPI CS pins: 17,21,25,29,33,37
        
        // Enable SPI
        uint32_t base_addr = SPI0_BASE + (spi * 0x1000);
        USER_writeWord(base_addr + SPI_CTRL, 0x7);  // Enable SPI, RX, and SS
        
        // Set GPIO to indicate SPI test
        ManagmentGpio_write(spi + 9);
    }
    
    ManagmentGpio_write(0); // all tests completed
    
    return;
} 