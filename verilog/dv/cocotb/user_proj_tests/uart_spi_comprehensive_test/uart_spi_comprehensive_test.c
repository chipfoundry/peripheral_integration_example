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
#include "../cf_uart_api.h"
#include "../cf_spi_api.h"

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
    
    // Phase 1: Test UART Register Access and Configuration using proper functions
    for (int uart = 0; uart < 7; uart++) {
        uint32_t base_addr = UART0_BASE + (uart * 0x1000);
        
        // Test 1: Write/Read UART Control Register
        uint32_t test_val = 0x12345678 + uart;
        USER_writeWord(base_addr + UART_CTRL, test_val);
        uint32_t read_val = USER_readWord(base_addr + UART_CTRL);
        if (read_val != test_val) {
            ManagmentGpio_write(0xFF); // Error indicator
            return;
        }
        
        // Test 2: Configure UART for operation using proper functions
        CF_UART_configure(base_addr, 0x70);     // 8-bit data, 1 stop bit, no parity
        CF_UART_setPrescale(base_addr, 0x1);    // Set prescale for baud rate
        CF_UART_enable(base_addr);               // Enable UART, TX, and RX
        CF_UART_setTxFIFOThreshold(base_addr, 3); // Set TX threshold
        CF_UART_enableTx(base_addr);             // Enable TX
        
        // Test 3: Verify configuration
        read_val = USER_readWord(base_addr + UART_CFG);
        if (read_val != 0x70) {
            ManagmentGpio_write(0xFF); // Error indicator
            return;
        }
        
        // Test 4: Test TX FIFO operations using proper functions
        CF_UART_flushTxFIFO(base_addr);
        
        // Test 5: Test RX FIFO operations using proper functions
        CF_UART_flushRxFIFO(base_addr);
        
        // Set GPIO to indicate UART test completion
        ManagmentGpio_write(uart + 2);
    }
    
    // Phase 2: Test SPI Register Access and Configuration using proper functions
    for (int spi = 0; spi < 6; spi++) {
        uint32_t base_addr = SPI0_BASE + (spi * 0x1000);
        
        // Test 1: Write/Read SPI Control Register
        uint32_t test_val = 0x87654321 + spi;
        USER_writeWord(base_addr + SPI_CTRL, test_val);
        uint32_t read_val = USER_readWord(base_addr + SPI_CTRL);
        if (read_val != test_val) {
            ManagmentGpio_write(0xFF); // Error indicator
            return;
        }
        
        // Test 2: Configure SPI for operation using proper functions
        CF_SPI_configure(base_addr, 0x0);        // SPI mode 0 (CPOL=0, CPHA=0)
        CF_SPI_setPrescale(base_addr, 0x2);      // Set prescale
        CF_SPI_enable(base_addr);                 // Enable SPI, RX, and SS
        CF_SPI_setTxFIFOThreshold(base_addr, 3); // Set TX threshold
        CF_SPI_enableTx(base_addr);               // Enable TX
        
        // Test 3: Verify configuration
        read_val = USER_readWord(base_addr + SPI_CFG);
        if (read_val != 0x0) {
            ManagmentGpio_write(0xFF); // Error indicator
            return;
        }
        
        // Test 4: Test TX FIFO operations using proper functions
        CF_SPI_flushTxFIFO(base_addr);
        
        // Test 5: Test RX FIFO operations using proper functions
        CF_SPI_flushRxFIFO(base_addr);
        
        // Set GPIO to indicate SPI test completion
        ManagmentGpio_write(spi + 9);
    }
    
    // Phase 3: Test Address Decoding (verify each peripheral responds to correct address)
    // Test UART address ranges
    for (int uart = 0; uart < 7; uart++) {
        uint32_t base_addr = UART0_BASE + (uart * 0x1000);
        
        // Write to each UART's control register
        USER_writeWord(base_addr + UART_CTRL, 0x7 + uart);
        
        // Read back and verify
        uint32_t read_val = USER_readWord(base_addr + UART_CTRL);
        if (read_val != (0x7 + uart)) {
            ManagmentGpio_write(0xFF); // Error indicator
            return;
        }
    }
    
    // Test SPI address ranges
    for (int spi = 0; spi < 6; spi++) {
        uint32_t base_addr = SPI0_BASE + (spi * 0x1000);
        
        // Write to each SPI's control register
        USER_writeWord(base_addr + SPI_CTRL, 0x7 + spi);
        
        // Read back and verify
        uint32_t read_val = USER_readWord(base_addr + SPI_CTRL);
        if (read_val != (0x7 + spi)) {
            ManagmentGpio_write(0xFF); // Error indicator
            return;
        }
    }
    
    // Phase 4: Test FIFO Level Registers using proper functions
    for (int uart = 0; uart < 7; uart++) {
        uint32_t base_addr = UART0_BASE + (uart * 0x1000);
        
        // Read FIFO levels (should be 0 initially)
        uint32_t tx_level = CF_UART_getTxFIFOLevel(base_addr);
        uint32_t rx_level = CF_UART_getRxFIFOLevel(base_addr);
        
        // These should be 0 for empty FIFOs
        if (tx_level != 0 || rx_level != 0) {
            ManagmentGpio_write(0xFF); // Error indicator
            return;
        }
    }
    
    for (int spi = 0; spi < 6; spi++) {
        uint32_t base_addr = SPI0_BASE + (spi * 0x1000);
        
        // Read FIFO levels (should be 0 initially)
        uint32_t tx_level = CF_SPI_getTxFIFOLevel(base_addr);
        uint32_t rx_level = CF_SPI_getRxFIFOLevel(base_addr);
        
        // These should be 0 for empty FIFOs
        if (tx_level != 0 || rx_level != 0) {
            ManagmentGpio_write(0xFF); // Error indicator
            return;
        }
    }
    
    // Phase 5: Test Invalid Address Access (should not respond)
    // Try to access invalid addresses and verify no response
    uint32_t invalid_addr = 0x3000D000; // Address beyond our peripheral range
    USER_writeWord(invalid_addr, 0x12345678);
    uint32_t read_val = USER_readWord(invalid_addr);
    // Note: We can't easily verify no response in this simple test, but the write/read should not crash
    
    ManagmentGpio_write(0); // all tests completed successfully
    
    return;
} 