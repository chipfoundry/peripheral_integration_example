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
 * user_proj_peripheral_example
 *
 * This is an example user project that demonstrates how to
 * integrate the caravel_peripheral_macro into a Caravel
 * user project.
 *
 * This example shows:
 * - How to instantiate the peripheral macro
 * - How to connect I/O pins to the peripherals
 * - How to handle the Wishbone interface
 * - How to manage interrupts
 *
 * I/O Pin Mapping:
 * - UART0: io_in[0] (RX), io_out[1] (TX)
 * - UART1: io_in[2] (RX), io_out[3] (TX)  
 * - SPI0:  io_in[4] (MISO), io_out[5] (MOSI), io_out[6] (SCLK), io_out[7] (CS)
 * - SPI1:  io_in[8] (MISO), io_out[9] (MOSI), io_out[10] (SCLK), io_out[11] (CS)
 *
 *-------------------------------------------------------------
 */

module user_proj_peripheral_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,



    // IOs - only the pins we need for peripherals (avoiding 0-4)
    input  [16:5] io_in,    // Pins 5-16 for peripheral I/O
    output [16:5] io_out,   // Pins 5-16 for peripheral I/O
    output [16:5] io_oeb,   // Pins 5-16 for peripheral I/O

    // IRQ
    output [2:0] irq
);

    // Wishbone interface signals for peripheral macro
    wire [31:0] peripheral_dat_o;
    wire peripheral_ack_o;
    wire peripheral_irq;
    
    // I/O enable signals for peripheral pins
    reg [16:5] io_oeb_reg;
    
    // Peripheral macro instance
    caravel_peripheral_macro peripheral_macro (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        
        // Wishbone interface
        .wbs_adr_i(wbs_adr_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_dat_o(peripheral_dat_o),
        .wbs_sel_i(wbs_sel_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_stb_i(wbs_stb_i),
        .wbs_ack_o(peripheral_ack_o),
        .wbs_we_i(wbs_we_i),
        
        // Interrupt
        .irq_o(peripheral_irq),
        
        // UART0 connections - using pins 5-6
        .uart0_rx(io_in[5]),
        .uart0_tx(io_out[6]),
        
        // UART1 connections - using pins 7-8
        .uart1_rx(io_in[7]),
        .uart1_tx(io_out[8]),
        
        // SPI0 connections - using pins 9-12
        .spi0_miso(io_in[9]),
        .spi0_mosi(io_out[10]),
        .spi0_sclk(io_out[11]),
        .spi0_csb(io_out[12]),
        
        // SPI1 connections - using pins 13-16
        .spi1_miso(io_in[13]),
        .spi1_mosi(io_out[14]),
        .spi1_sclk(io_out[15]),
        .spi1_csb(io_out[16])
    );
    
    // Wishbone interface connections
    assign wbs_dat_o = peripheral_dat_o;
    assign wbs_ack_o = peripheral_ack_o;
    
    // Interrupt connections
    assign irq[0] = peripheral_irq;
    assign irq[2:1] = 2'b00; // Unused interrupts
    
    // I/O enable configuration
    // Set output enable for TX pins (outputs) and disable for RX pins (inputs)
    always @(*) begin
        io_oeb_reg = 12'hFFF; // Default all pins as inputs
        
        // UART0 TX pin
        io_oeb_reg[6] = 1'b0; // Output enable for TX
        
        // UART1 TX pin  
        io_oeb_reg[8] = 1'b0; // Output enable for TX
        
        // SPI0 output pins
        io_oeb_reg[10] = 1'b0; // MOSI
        io_oeb_reg[11] = 1'b0; // SCLK
        io_oeb_reg[12] = 1'b0; // CS
        
        // SPI1 output pins
        io_oeb_reg[14] = 1'b0;  // MOSI
        io_oeb_reg[15] = 1'b0; // SCLK
        io_oeb_reg[16] = 1'b0; // CS
    end
    
    assign io_oeb = io_oeb_reg;
    


endmodule 