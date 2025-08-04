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

#ifndef CF_SPI_API_H
#define CF_SPI_API_H

#include <firmware_apis.h>

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

// CF_SPI functions for user SPI peripherals

/**
 * Enable SPI peripheral
 * @param spi_base Base address of the SPI peripheral
 */
void CF_SPI_enable(uint32_t spi_base) {
    // Enable SPI, RX, and SS
    USER_writeWord(spi_base + SPI_CTRL, 0x7);
}

/**
 * Set TX FIFO threshold
 * @param spi_base Base address of the SPI peripheral
 * @param threshold Threshold value (0-15)
 */
void CF_SPI_setTxFIFOThreshold(uint32_t spi_base, uint32_t threshold) {
    USER_writeWord(spi_base + SPI_TX_FIFO_THRESHOLD, threshold);
}

/**
 * Enable SPI TX
 * @param spi_base Base address of the SPI peripheral
 */
void CF_SPI_enableTx(uint32_t spi_base) {
    // Read current control register
    uint32_t ctrl = USER_readWord(spi_base + SPI_CTRL);
    // Set TX enable bit (bit 1)
    ctrl |= 0x2;
    USER_writeWord(spi_base + SPI_CTRL, ctrl);
}

/**
 * Enable SPI RX
 * @param spi_base Base address of the SPI peripheral
 */
void CF_SPI_enableRx(uint32_t spi_base) {
    // Read current control register
    uint32_t ctrl = USER_readWord(spi_base + SPI_CTRL);
    // Set RX enable bit (bit 2)
    ctrl |= 0x4;
    USER_writeWord(spi_base + SPI_CTRL, ctrl);
}

/**
 * Configure SPI
 * @param spi_base Base address of the SPI peripheral
 * @param config Configuration value
 */
void CF_SPI_configure(uint32_t spi_base, uint32_t config) {
    USER_writeWord(spi_base + SPI_CFG, config);
}

/**
 * Set SPI prescale
 * @param spi_base Base address of the SPI peripheral
 * @param prescale Prescale value
 */
void CF_SPI_setPrescale(uint32_t spi_base, uint32_t prescale) {
    USER_writeWord(spi_base + SPI_PR, prescale);
}

/**
 * Send data through SPI
 * @param spi_base Base address of the SPI peripheral
 * @param data Data to send
 */
void CF_SPI_sendData(uint32_t spi_base, uint8_t data) {
    USER_writeWord(spi_base + SPI_TXDATA, data);
}

/**
 * Read data from SPI
 * @param spi_base Base address of the SPI peripheral
 * @return Data read
 */
uint8_t CF_SPI_readData(uint32_t spi_base) {
    return (uint8_t)USER_readWord(spi_base + SPI_RXDATA);
}

/**
 * Get SPI status
 * @param spi_base Base address of the SPI peripheral
 * @return Status register value
 */
uint32_t CF_SPI_getStatus(uint32_t spi_base) {
    return USER_readWord(spi_base + SPI_STATUS);
}

/**
 * Flush TX FIFO
 * @param spi_base Base address of the SPI peripheral
 */
void CF_SPI_flushTxFIFO(uint32_t spi_base) {
    USER_writeWord(spi_base + SPI_TX_FIFO_FLUSH, 0x1);
}

/**
 * Flush RX FIFO
 * @param spi_base Base address of the SPI peripheral
 */
void CF_SPI_flushRxFIFO(uint32_t spi_base) {
    USER_writeWord(spi_base + SPI_RX_FIFO_FLUSH, 0x1);
}

/**
 * Get TX FIFO level
 * @param spi_base Base address of the SPI peripheral
 * @return TX FIFO level
 */
uint32_t CF_SPI_getTxFIFOLevel(uint32_t spi_base) {
    return USER_readWord(spi_base + SPI_TX_FIFO_LEVEL);
}

/**
 * Get RX FIFO level
 * @param spi_base Base address of the SPI peripheral
 * @return RX FIFO level
 */
uint32_t CF_SPI_getRxFIFOLevel(uint32_t spi_base) {
    return USER_readWord(spi_base + SPI_RX_FIFO_LEVEL);
}

#endif // CF_SPI_API_H 