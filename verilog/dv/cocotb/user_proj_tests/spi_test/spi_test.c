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
#include "../cf_spi_api.h"

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
    
    // Test all 6 SPI peripherals using proper CF_SPI functions
    for (int spi = 0; spi < 6; spi++) {
        uint32_t base_addr = SPI0_BASE + (spi * 0x1000);
        
        // Step 1: Configure SPI using proper functions
        CF_SPI_configure(base_addr, 0x0);        // SPI mode 0 (CPOL=0, CPHA=0)
        CF_SPI_setPrescale(base_addr, 0x2);      // Set prescale
        
        // Step 2: Enable SPI using proper functions
        CF_SPI_enable(base_addr);
        CF_SPI_setTxFIFOThreshold(base_addr, 3);
        CF_SPI_enableTx(base_addr);
        
        // Step 3: Flush FIFOs
        CF_SPI_flushTxFIFO(base_addr);
        CF_SPI_flushRxFIFO(base_addr);
        
        // Step 4: Verify configuration
        uint32_t ctrl_val = USER_readWord(base_addr + SPI_CTRL);
        uint32_t cfg_val = USER_readWord(base_addr + SPI_CFG);
        
        if (ctrl_val != 0x7 || cfg_val != 0x0) {
            ManagmentGpio_write(0xFF); // Error indicator
            return;
        }
        
        // Step 5: Test TX data register using proper function
        CF_SPI_sendData(base_addr, 0x41 + spi); // Send character 'A' + spi number
        
        // Step 6: Check TX FIFO level using proper function
        uint32_t tx_level = CF_SPI_getTxFIFOLevel(base_addr);
        if (tx_level != 1) {
            ManagmentGpio_write(0xFF); // Error indicator
            return;
        }
        
        // Step 7: Check status register using proper function
        uint32_t status = CF_SPI_getStatus(base_addr);
        // Status should show TX FIFO not empty (bit 1)
        if ((status & 0x2) == 0) {
            ManagmentGpio_write(0xFF); // Error indicator
            return;
        }
        
        // Set GPIO to indicate SPI test completion
        ManagmentGpio_write(spi + 9);
    }
    
    ManagmentGpio_write(0); // all tests completed successfully
    
    return;
} 