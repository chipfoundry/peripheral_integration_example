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

// UART base addresses for user project UARTs
#define UART0_BASE   0x30000000
#define UART1_BASE   0x30001000
#define UART2_BASE   0x30002000
#define UART3_BASE   0x30003000
#define UART4_BASE   0x30004000
#define UART5_BASE   0x30005000
#define UART6_BASE   0x30006000

void main() {
    // Enable management GPIO as output to use as indicator for finishing configuration
    ManagmentGpio_outputEnable();
    ManagmentGpio_write(0);
    
    enableHkSpi(0); // disable housekeeping spi
    
    // Configure GPIOs for user project UART monitoring
    // UART TX pins are connected to odd-numbered I/O pins: 1,3,5,7,9,11,13
    GPIOs_configure(1, GPIO_MODE_USER_STD_OUT_MONITORED);  // UART0 TX
    GPIOs_configure(3, GPIO_MODE_USER_STD_OUT_MONITORED);  // UART1 TX
    GPIOs_configure(5, GPIO_MODE_USER_STD_OUT_MONITORED);  // UART2 TX
    GPIOs_configure(7, GPIO_MODE_USER_STD_OUT_MONITORED);  // UART3 TX
    GPIOs_configure(9, GPIO_MODE_USER_STD_OUT_MONITORED);  // UART4 TX
    GPIOs_configure(11, GPIO_MODE_USER_STD_OUT_MONITORED); // UART5 TX
    GPIOs_configure(13, GPIO_MODE_USER_STD_OUT_MONITORED); // UART6 TX
    GPIOs_loadConfigs(); // load the configuration
    
    User_enableIF(); // enable interface for wishbone communication
    
    ManagmentGpio_write(1); // configuration finished
    
    // Test all 7 UART peripherals in the user project
    for (int uart = 0; uart < 7; uart++) {
        uint32_t base_addr = UART0_BASE + (uart * 0x1000);
        
        // Step 1: Configure UART using proper functions
        CF_UART_configure(base_addr, 0x70);      // 8-bit data, 1 stop bit, no parity
        CF_UART_setPrescale(base_addr, 0x1);     // Set prescale for baud rate
        
        // Step 2: Enable UART using proper functions
        CF_UART_enable(base_addr);
        CF_UART_setTxFIFOThreshold(base_addr, 3);
        CF_UART_enableTx(base_addr);
        
        // Step 3: Flush FIFOs
        CF_UART_flushTxFIFO(base_addr);
        CF_UART_flushRxFIFO(base_addr);
        
        // Step 4: Verify configuration
        uint32_t ctrl_val = USER_readWord(base_addr + UART_CTRL);
        uint32_t cfg_val = USER_readWord(base_addr + UART_CFG);
        
        if (ctrl_val != 0x7 || cfg_val != 0x70) {
            ManagmentGpio_write(0xFF); // Error indicator
            return;
        }
        
        // Step 5: Test TX data register using proper function
        CF_UART_sendChar(base_addr, 0x41 + uart); // Send character 'A' + uart number
        
        // Step 6: Check TX FIFO level using proper function
        uint32_t tx_level = CF_UART_getTxFIFOLevel(base_addr);
        if (tx_level != 1) {
            ManagmentGpio_write(0xFF); // Error indicator
            return;
        }
        
        // Step 7: Wait for transmission to complete (check TX FIFO becomes empty)
        int timeout = 0;
        while (CF_UART_getTxFIFOLevel(base_addr) > 0 && timeout < 10000) {
            for (volatile int i = 0; i < 100; i++); // Small delay
            timeout++;
        }
        
        if (timeout >= 10000) {
            ManagmentGpio_write(0xFF); // Error indicator - transmission timeout
            return;
        }
        
        // Step 8: Verify transmission completed
        if (CF_UART_getTxFIFOLevel(base_addr) != 0) {
            ManagmentGpio_write(0xFF); // Error indicator
            return;
        }
    }
    
    ManagmentGpio_write(1); // all tests completed successfully
    
    return;
} 