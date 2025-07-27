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
    
    // Configure GPIOs for SPI/UART interrupt test
    GPIOs_configureAll(GPIO_MODE_USER_STD_OUT_MONITORED);
    GPIOs_configure(5, GPIO_MODE_USER_STD_OUT_MONITORED);  // SPI_MOSI
    GPIOs_configure(6, GPIO_MODE_USER_STD_IN_NOPULL);      // SPI_MISO
    GPIOs_configure(7, GPIO_MODE_USER_STD_OUT_MONITORED);  // SPI_SCLK
    GPIOs_configure(8, GPIO_MODE_USER_STD_OUT_MONITORED);  // SPI_CSB
    GPIOs_configure(9, GPIO_MODE_USER_STD_OUT_MONITORED);  // UART_TX
    GPIOs_configure(10, GPIO_MODE_USER_STD_IN_NOPULL);     // UART_RX
    GPIOs_configure(11, GPIO_MODE_USER_STD_OUT_MONITORED); // SPI_LED
    GPIOs_configure(12, GPIO_MODE_USER_STD_OUT_MONITORED); // UART_LED
    GPIOs_configure(13, GPIO_MODE_USER_STD_IN_NOPULL);     // SPI_EN
    GPIOs_configure(14, GPIO_MODE_USER_STD_IN_NOPULL);     // UART_EN
    
    GPIOs_loadConfigs(); // load the configuration 
    ManagmentGpio_write(1); // configuration finished 
    
    // Enable SPI and UART
    GPIOs_writeLow(13, 1); // SPI_EN = 1
    GPIOs_writeLow(14, 1); // UART_EN = 1
    
    ManagmentGpio_write(0); // test configuration finished 
    
    return;
} 