// SPDX-FileCopyrightText: 2024 ChipFoundry, a DBA of Umbralogic Technologies LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

/*
 *-------------------------------------------------------------
 *
 * caravel_peripheral_macro
 *
 * This module encapsulates multiple UART and SPI peripherals
 * with a Wishbone B4 interconnect for easy integration into
 * Caravel user projects.
 *
 * Features:
 * - 2x UART peripherals with Wishbone B4 slave interfaces
 * - 2x SPI peripherals with Wishbone B4 slave interfaces  
 * - Wishbone address decoder for peripheral selection
 * - Interrupt aggregation from all peripherals
 * - Direct I/O pin exposure for peripheral communication
 *
 * Wishbone Address Mapping (relative to macro base address):
 * - UART0: 0x0000_0000 - 0x0000_0FFF
 * - UART1: 0x0000_1000 - 0x0000_1FFF  
 * - SPI0:  0x0000_2000 - 0x0000_2FFF
 * - SPI1:  0x0000_3000 - 0x0000_3FFF
 *
 *-------------------------------------------------------------
 */

module caravel_peripheral_macro #(
    parameter UART_SC = 8,        // UART samples per bit
    parameter UART_MDW = 9,       // UART max data width
    parameter UART_GFLEN = 8,     // UART glitch filter length
    parameter UART_FAW = 4,       // UART FIFO address width
    parameter SPI_CDW = 8,        // SPI clock divider width
    parameter SPI_FAW = 4         // SPI FIFO address width
)(
    // Clock and Reset
    input wire wb_clk_i,
    input wire wb_rst_i,
    
    // Wishbone B4 Slave Interface
    input wire [31:0] wbs_adr_i,
    input wire [31:0] wbs_dat_i,
    output wire [31:0] wbs_dat_o,
    input wire [3:0] wbs_sel_i,
    input wire wbs_cyc_i,
    input wire wbs_stb_i,
    output wire wbs_ack_o,
    input wire wbs_we_i,
    
    // Interrupt Output
    output wire irq_o,
    
    // UART0 I/O
    input wire uart0_rx,
    output wire uart0_tx,
    
    // UART1 I/O  
    input wire uart1_rx,
    output wire uart1_tx,
    
    // SPI0 I/O
    input wire spi0_miso,
    output wire spi0_mosi,
    output wire spi0_sclk,
    output wire spi0_csb,
    
    // SPI1 I/O
    input wire spi1_miso,
    output wire spi1_mosi,
    output wire spi1_sclk,
    output wire spi1_csb
);

    // Internal signals for Wishbone interconnect
    wire [31:0] uart0_dat_o, uart1_dat_o, spi0_dat_o, spi1_dat_o;
    wire uart0_ack_o, uart1_ack_o, spi0_ack_o, spi1_ack_o;
    wire uart0_irq, uart1_irq, spi0_irq, spi1_irq;
    
    // Address decoder signals
    wire [3:0] peripheral_sel;
    wire [31:0] peripheral_adr;
    
    // Wishbone valid and read/write signals
    wire wb_valid = wbs_cyc_i && wbs_stb_i;
    wire wb_we = wbs_we_i && wb_valid;
    wire wb_re = ~wbs_we_i && wb_valid;
    
    // Address decoder logic
    // Extract peripheral address (lower 12 bits) and select peripheral
    assign peripheral_adr = {20'h0, wbs_adr_i[11:0]};
    assign peripheral_sel = wbs_adr_i[13:12]; // 2-bit peripheral select
    
    // Peripheral select signals
    wire uart0_sel = (peripheral_sel == 2'b00) && wb_valid;
    wire uart1_sel = (peripheral_sel == 2'b01) && wb_valid;
    wire spi0_sel = (peripheral_sel == 2'b10) && wb_valid;
    wire spi1_sel = (peripheral_sel == 2'b11) && wb_valid;
    
    // Wishbone data output multiplexer
    assign wbs_dat_o = uart0_sel ? uart0_dat_o :
                       uart1_sel ? uart1_dat_o :
                       spi0_sel ? spi0_dat_o :
                       spi1_sel ? spi1_dat_o :
                       32'h0;
    
    // Wishbone acknowledge output
    assign wbs_ack_o = uart0_ack_o || uart1_ack_o || spi0_ack_o || spi1_ack_o;
    
    // Interrupt aggregation (OR all peripheral interrupts)
    assign irq_o = uart0_irq || uart1_irq || spi0_irq || spi1_irq;
    
    // UART0 Instance
    CF_UART_WB #(
        .SC(UART_SC),
        .MDW(UART_MDW),
        .GFLEN(UART_GFLEN),
        .FAW(UART_FAW)
    ) uart0_inst (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(peripheral_adr),
        .dat_i(wbs_dat_i),
        .dat_o(uart0_dat_o),
        .sel_i(wbs_sel_i),
        .cyc_i(uart0_sel),
        .stb_i(uart0_sel),
        .ack_o(uart0_ack_o),
        .we_i(wbs_we_i),
        .IRQ(uart0_irq),
        .rx(uart0_rx),
        .tx(uart0_tx)
    );
    
    // UART1 Instance
    CF_UART_WB #(
        .SC(UART_SC),
        .MDW(UART_MDW),
        .GFLEN(UART_GFLEN),
        .FAW(UART_FAW)
    ) uart1_inst (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(peripheral_adr),
        .dat_i(wbs_dat_i),
        .dat_o(uart1_dat_o),
        .sel_i(wbs_sel_i),
        .cyc_i(uart1_sel),
        .stb_i(uart1_sel),
        .ack_o(uart1_ack_o),
        .we_i(wbs_we_i),
        .IRQ(uart1_irq),
        .rx(uart1_rx),
        .tx(uart1_tx)
    );
    
    // SPI0 Instance
    CF_SPI_WB #(
        .CDW(SPI_CDW),
        .FAW(SPI_FAW)
    ) spi0_inst (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(peripheral_adr),
        .dat_i(wbs_dat_i),
        .dat_o(spi0_dat_o),
        .sel_i(wbs_sel_i),
        .cyc_i(spi0_sel),
        .stb_i(spi0_sel),
        .ack_o(spi0_ack_o),
        .we_i(wbs_we_i),
        .IRQ(spi0_irq),
        .miso(spi0_miso),
        .mosi(spi0_mosi),
        .csb(spi0_csb),
        .sclk(spi0_sclk)
    );
    
    // SPI1 Instance
    CF_SPI_WB #(
        .CDW(SPI_CDW),
        .FAW(SPI_FAW)
    ) spi1_inst (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(peripheral_adr),
        .dat_i(wbs_dat_i),
        .dat_o(spi1_dat_o),
        .sel_i(wbs_sel_i),
        .cyc_i(spi1_sel),
        .stb_i(spi1_sel),
        .ack_o(spi1_ack_o),
        .we_i(wbs_we_i),
        .IRQ(spi1_irq),
        .miso(spi1_miso),
        .mosi(spi1_mosi),
        .csb(spi1_csb),
        .sclk(spi1_sclk)
    );

endmodule 