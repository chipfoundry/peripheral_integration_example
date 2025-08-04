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
#define UART_RX_FIFO_LEVEL   0x4000  // RX FIFO level
#define UART_RX_FIFO_THRESHOLD 0x4004 // RX FIFO threshold
#define UART_RX_FIFO_FLUSH  0x4008  // RX FIFO flush
#define UART_TX_FIFO_LEVEL   0x400C  // TX FIFO level
#define UART_TX_FIFO_THRESHOLD 0x4010 // TX FIFO threshold
#define UART_TX_FIFO_FLUSH  0x4014  // TX FIFO flush
#define UART_IM              0x4040  // Interrupt mask
#define UART_MIS             0x4044  // Masked interrupt status
#define UART_RIS             0x4048  // Raw interrupt status
#define UART_IC              0x404C  // Interrupt clear

// SPI register offsets (based on CF_SPI_regs.h)
#define SPI_RXDATA           0x00    // Read-only data register
#define SPI_TXDATA           0x04    // Write-only data register
#define SPI_CFG              0x08    // Configuration register
#define SPI_CTRL             0x0C    // Control register
#define SPI_PR               0x10    // Prescale register
#define SPI_STATUS           0x14    // Status register
#define SPI_RX_FIFO_LEVEL   0x4000  // RX FIFO level
#define SPI_RX_FIFO_THRESHOLD 0x4004 // RX FIFO threshold
#define SPI_RX_FIFO_FLUSH   0x4008  // RX FIFO flush
#define SPI_TX_FIFO_LEVEL   0x400C  // TX FIFO level
#define SPI_TX_FIFO_THRESHOLD 0x4010 // TX FIFO threshold
#define SPI_TX_FIFO_FLUSH   0x4014  // TX FIFO flush
#define SPI_IM               0x4040  // Interrupt mask
#define SPI_MIS              0x4044  // Masked interrupt status
#define SPI_RIS              0x4048  // Raw interrupt status
#define SPI_IC               0x404C  // Interrupt clear

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
    
    // Test all UART peripherals
    for (int uart = 0; uart < 7; uart++) {
        uint32_t base_addr = UART0_BASE + (uart * 0x1000);
        
        // Write to UART control registers
        USER_writeWord(base_addr + UART_CTRL, 0x7);      // Enable UART, TX, and RX
        USER_writeWord(base_addr + UART_CFG, 0x70);      // 8-bit data, 1 stop bit, no parity
        USER_writeWord(base_addr + UART_PR, 0x1);        // Set prescale for baud rate
        
        // Read back to verify
        uint32_t ctrl_val = USER_readWord(base_addr + UART_CTRL);
        uint32_t cfg_val = USER_readWord(base_addr + UART_CFG);
        
        // Set GPIO to indicate UART test completion
        ManagmentGpio_write(uart + 2);
    }
    
    // Test all SPI peripherals
    for (int spi = 0; spi < 6; spi++) {
        uint32_t base_addr = SPI0_BASE + (spi * 0x1000);
        
        // Write to SPI control registers
        USER_writeWord(base_addr + SPI_CTRL, 0x7);       // Enable SPI, RX, and SS
        USER_writeWord(base_addr + SPI_CFG, 0x0);        // SPI mode 0 (CPOL=0, CPHA=0)
        USER_writeWord(base_addr + SPI_PR, 0x2);         // Set prescale
        
        // Read back to verify
        uint32_t ctrl_val = USER_readWord(base_addr + SPI_CTRL);
        uint32_t cfg_val = USER_readWord(base_addr + SPI_CFG);
        
        // Set GPIO to indicate SPI test completion
        ManagmentGpio_write(spi + 9);
    }
    
    ManagmentGpio_write(0); // all tests completed
    
    return;
} 