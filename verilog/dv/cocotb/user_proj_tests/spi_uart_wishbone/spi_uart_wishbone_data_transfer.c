// SPDX-FileCopyrightText: 2023 Efabless Corporation

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

void main(){
    // Enable management gpio as output to use as indicator for finishing configuration  
    ManagmentGpio_outputEnable();
    ManagmentGpio_write(0);
    enableHkSpi(0); // disable housekeeping spi
    
    // Configure GPIOs for SPI/UART integration test
    // GPIO 5-14 are used for SPI/UART functionality
    // GPIO 5: SPI_MOSI (output)
    // GPIO 6: SPI_MISO (input) 
    // GPIO 7: SPI_SCLK (output)
    // GPIO 8: SPI_CSB (output)
    // GPIO 9: UART_TX (output)
    // GPIO 10: UART_RX (input)
    // GPIO 11: SPI_LED (output)
    // GPIO 12: UART_LED (output)
    // GPIO 13: SPI_EN (input)
    // GPIO 14: UART_EN (input)
    
    // Configure all GPIOs as user out for monitoring
    GPIOs_configureAll(GPIO_MODE_USER_STD_OUT_MONITORED);
    
    // Configure specific GPIOs for SPI/UART
    GPIOs_configure(5, GPIO_MODE_USER_STD_OUT_MONITORED);  // SPI_MOSI
    GPIOs_configure(6, GPIO_MODE_USER_STD_INPUT_NOPULL);      // SPI_MISO (input)
    GPIOs_configure(7, GPIO_MODE_USER_STD_OUT_MONITORED);  // SPI_SCLK
    GPIOs_configure(8, GPIO_MODE_USER_STD_OUT_MONITORED);  // SPI_CSB
    GPIOs_configure(9, GPIO_MODE_USER_STD_OUT_MONITORED);  // UART_TX
    GPIOs_configure(10, GPIO_MODE_USER_STD_INPUT_NOPULL);     // UART_RX (input)
    GPIOs_configure(11, GPIO_MODE_USER_STD_OUT_MONITORED); // SPI_LED
    GPIOs_configure(12, GPIO_MODE_USER_STD_OUT_MONITORED); // UART_LED
    GPIOs_configure(13, GPIO_MODE_USER_STD_INPUT_NOPULL);     // SPI_EN (input)
    GPIOs_configure(14, GPIO_MODE_USER_STD_INPUT_NOPULL);     // UART_EN (input)
    
    // Configure additional GPIOs for monitoring (32-37)
    GPIOs_configure(32, GPIO_MODE_USER_STD_OUT_MONITORED);
    GPIOs_configure(33, GPIO_MODE_USER_STD_OUT_MONITORED);
    GPIOs_configure(34, GPIO_MODE_USER_STD_OUT_MONITORED);
    GPIOs_configure(35, GPIO_MODE_USER_STD_OUT_MONITORED);
    GPIOs_configure(36, GPIO_MODE_USER_STD_OUT_MONITORED);
    GPIOs_configure(37, GPIO_MODE_USER_STD_OUT_MONITORED);
    
    GPIOs_loadConfigs(); // load the configuration 
    ManagmentGpio_write(1); // configuration finished 
    
    // Set initial GPIO states for testing
    // Enable SPI and UART by setting GPIO 13 and 14 high
    
    // Wait a bit for configuration to settle
    for(int i = 0; i < 1000; i++) {
        asm volatile("nop");
    }
    
    ManagmentGpio_write(0); // test configuration finished 
    
    return;
} 