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

#ifndef CF_UART_API_H
#define CF_UART_API_H

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

// UART base addresses
#define UART0_BASE   0x30000000
#define UART1_BASE   0x30001000
#define UART2_BASE   0x30002000
#define UART3_BASE   0x30003000
#define UART4_BASE   0x30004000
#define UART5_BASE   0x30005000
#define UART6_BASE   0x30006000

// CF_UART functions for user UART peripherals

/**
 * Enable UART peripheral
 * @param uart_base Base address of the UART peripheral
 */
void CF_UART_enable(uint32_t uart_base) {
    // Enable UART, TX, and RX
    USER_writeWord(uart_base + UART_CTRL, 0x7);
}

/**
 * Set TX FIFO threshold
 * @param uart_base Base address of the UART peripheral
 * @param threshold Threshold value (0-15)
 */
void CF_UART_setTxFIFOThreshold(uint32_t uart_base, uint32_t threshold) {
    USER_writeWord(uart_base + UART_TX_FIFO_THRESHOLD, threshold);
}

/**
 * Enable UART TX
 * @param uart_base Base address of the UART peripheral
 */
void CF_UART_enableTx(uint32_t uart_base) {
    // Read current control register
    uint32_t ctrl = USER_readWord(uart_base + UART_CTRL);
    // Set TX enable bit (bit 0)
    ctrl |= 0x1;
    USER_writeWord(uart_base + UART_CTRL, ctrl);
}

/**
 * Enable UART RX
 * @param uart_base Base address of the UART peripheral
 */
void CF_UART_enableRx(uint32_t uart_base) {
    // Read current control register
    uint32_t ctrl = USER_readWord(uart_base + UART_CTRL);
    // Set RX enable bit (bit 1)
    ctrl |= 0x2;
    USER_writeWord(uart_base + UART_CTRL, ctrl);
}

/**
 * Configure UART
 * @param uart_base Base address of the UART peripheral
 * @param config Configuration value
 */
void CF_UART_configure(uint32_t uart_base, uint32_t config) {
    USER_writeWord(uart_base + UART_CFG, config);
}

/**
 * Set UART prescale
 * @param uart_base Base address of the UART peripheral
 * @param prescale Prescale value
 */
void CF_UART_setPrescale(uint32_t uart_base, uint32_t prescale) {
    USER_writeWord(uart_base + UART_PR, prescale);
}

/**
 * Send character through UART
 * @param uart_base Base address of the UART peripheral
 * @param c Character to send
 */
void CF_UART_sendChar(uint32_t uart_base, char c) {
    USER_writeWord(uart_base + UART_TXDATA, c);
}

/**
 * Read character from UART
 * @param uart_base Base address of the UART peripheral
 * @return Character read
 */
char CF_UART_readChar(uint32_t uart_base) {
    return (char)USER_readWord(uart_base + UART_RXDATA);
}

/**
 * Flush TX FIFO
 * @param uart_base Base address of the UART peripheral
 */
void CF_UART_flushTxFIFO(uint32_t uart_base) {
    USER_writeWord(uart_base + UART_TX_FIFO_FLUSH, 0x1);
}

/**
 * Flush RX FIFO
 * @param uart_base Base address of the UART peripheral
 */
void CF_UART_flushRxFIFO(uint32_t uart_base) {
    USER_writeWord(uart_base + UART_RX_FIFO_FLUSH, 0x1);
}

/**
 * Get TX FIFO level
 * @param uart_base Base address of the UART peripheral
 * @return TX FIFO level
 */
uint32_t CF_UART_getTxFIFOLevel(uint32_t uart_base) {
    return USER_readWord(uart_base + UART_TX_FIFO_LEVEL);
}

/**
 * Get RX FIFO level
 * @param uart_base Base address of the UART peripheral
 * @return RX FIFO level
 */
uint32_t CF_UART_getRxFIFOLevel(uint32_t uart_base) {
    return USER_readWord(uart_base + UART_RX_FIFO_LEVEL);
}

#endif // CF_UART_API_H 