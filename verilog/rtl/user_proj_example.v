// SPDX-FileCopyrightText: 2020 Efabless Corporation
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
 * user_proj_example
 *
 * This is a user project that integrates SPI and UART IPs
 * with the Wishbone bus and GPIO connections.
 *
 * Features:
 * - SPI master interface with GPIO connections
 * - UART interface with GPIO connections
 * - Wishbone bus control and status registers
 * - Logic analyzer integration for debugging
 * - Interrupt support for both SPI and UART
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 16
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

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs - only the pins we use (5-14)
    input  [14:5] io_in,
    output [14:5] io_out,
    output [14:5] io_oeb,

    // IRQ
    output [2:0] irq
);

    // Clock and reset
    wire clk = wb_clk_i;
    wire rst = wb_rst_i;

    // Wishbone interface signals
    wire wb_valid = wbs_cyc_i && wbs_stb_i;
    wire [3:0] wb_sel = wbs_sel_i;
    wire [31:0] wb_addr = wbs_adr_i;
    wire [31:0] wb_data_in = wbs_dat_i;
    wire [31:0] wb_data_out;
    wire wb_we = wbs_we_i;
    wire wb_ack;

    // Address decoding
    wire spi_sel = (wb_addr[15:12] == 4'h0);  // 0x0000-0x0FFF
    wire uart_sel = (wb_addr[15:12] == 4'h1); // 0x1000-0x1FFF
    wire ctrl_sel = (wb_addr[15:12] == 4'hF); // 0xF000-0xFFFF

    // SPI interface
    wire spi_ack;
    wire [31:0] spi_data_out;
    wire spi_irq;

    // UART interface
    wire uart_ack;
    wire [31:0] uart_data_out;
    wire uart_irq;

    // Control registers
    wire ctrl_ack;
    wire [31:0] ctrl_data_out;

    // GPIO assignments
    // SPI: io[5]=MOSI, io[6]=MISO, io[7]=SCLK, io[8]=CSB
    // UART: io[9]=TX, io[10]=RX
    // Status LEDs: io[11]=SPI_ACTIVE, io[12]=UART_ACTIVE
    // Control: io[13]=SPI_ENABLE, io[14]=UART_ENABLE

    // SPI signals
    wire spi_mosi, spi_miso, spi_sclk, spi_csb;
    wire spi_enable = io_in[13];

    // UART signals
    wire uart_tx, uart_rx;
    wire uart_enable = io_in[14];

    // Status signals - connect to actual signals from IPs
    wire spi_active = spi_enable && (spi_csb == 1'b0); // Active when CSB is low
    wire uart_active = uart_enable && (uart_tx != 1'b1); // Active when TX is not idle

    // Wishbone data output multiplexing
    assign wb_data_out = spi_sel ? spi_data_out :
                        uart_sel ? uart_data_out :
                        ctrl_sel ? ctrl_data_out : 32'h0;

    // Wishbone acknowledge
    assign wb_ack = (spi_sel && spi_ack) || 
                   (uart_sel && uart_ack) || 
                   (ctrl_sel && ctrl_ack);

    // Output assignments
    assign wbs_dat_o = wb_data_out;
    assign wbs_ack_o = wb_ack;

    // GPIO output assignments - only assign the pins we use
    assign io_out[5] = spi_enable ? spi_mosi : 1'b0;    // SPI MOSI
    assign io_out[7] = spi_enable ? spi_sclk : 1'b0;    // SPI SCLK
    assign io_out[8] = spi_enable ? spi_csb : 1'b1;     // SPI CSB (active low)
    assign io_out[9] = uart_enable ? uart_tx : 1'b1;    // UART TX (idle high)
    assign io_out[11] = spi_active;                     // SPI activity LED
    assign io_out[12] = uart_active;                    // UART activity LED

    // GPIO direction control - only control the pins we use
    assign io_oeb[5] = ~spi_enable;     // MOSI output when enabled
    assign io_oeb[6] = 1'b0;            // MISO always input
    assign io_oeb[7] = ~spi_enable;     // SCLK output when enabled
    assign io_oeb[8] = ~spi_enable;     // CSB output when enabled
    assign io_oeb[9] = ~uart_enable;    // TX output when enabled
    assign io_oeb[10] = 1'b0;           // RX always input
    assign io_oeb[11] = 1'b0;           // Status LED output
    assign io_oeb[12] = 1'b0;           // Status LED output
    assign io_oeb[13] = 1'b1;           // SPI enable input
    assign io_oeb[14] = 1'b1;           // UART enable input

    // Interrupt assignments
    assign irq[0] = spi_irq;
    assign irq[1] = uart_irq;
    assign irq[2] = 1'b0;

    // Logic analyzer outputs
    assign la_data_out[31:0] = wb_data_out;
    assign la_data_out[47:32] = wb_addr[15:0];
    assign la_data_out[63:48] = {spi_active, uart_active, spi_enable, uart_enable, 
                                 spi_mosi, io_in[6], spi_sclk, spi_csb, 
                                 uart_tx, io_in[10], 6'b0};
    assign la_data_out[95:64] = {spi_irq, uart_irq, 30'b0};
    assign la_data_out[127:96] = 32'b0;

    // SPI IP instantiation
    CF_SPI_WB #(
        .CDW(8),
        .FAW(4)
    ) spi_inst (
        .clk_i(clk),
        .rst_i(rst),
        .adr_i(wb_addr),
        .dat_i(wb_data_in),
        .dat_o(spi_data_out),
        .sel_i(wb_sel),
        .cyc_i(wb_valid && spi_sel),
        .stb_i(wb_valid && spi_sel),
        .ack_o(spi_ack),
        .we_i(wb_we),
        .IRQ(spi_irq),
        .miso(io_in[6]),        // MISO from GPIO
        .mosi(spi_mosi),
        .csb(spi_csb),
        .sclk(spi_sclk)
    );

    // UART IP instantiation
    CF_UART_WB #(
        .SC(8),
        .MDW(9),
        .GFLEN(8),
        .FAW(4)
    ) uart_inst (
        .clk_i(clk),
        .rst_i(rst),
        .adr_i(wb_addr),
        .dat_i(wb_data_in),
        .dat_o(uart_data_out),
        .sel_i(wb_sel),
        .cyc_i(wb_valid && uart_sel),
        .stb_i(wb_valid && uart_sel),
        .ack_o(uart_ack),
        .we_i(wb_we),
        .IRQ(uart_irq),
        .rx(io_in[10]),          // RX from GPIO
        .tx(uart_tx)
    );

    // Control and status registers
    control_registers ctrl_regs (
        .clk(clk),
        .rst(rst),
        .wb_valid(wb_valid && ctrl_sel),
        .wb_we(wb_we),
        .wb_addr(wb_addr[7:0]),
        .wb_data_in(wb_data_in),
        .wb_data_out(ctrl_data_out),
        .wb_ack(ctrl_ack),
        .spi_active(spi_active),
        .uart_active(uart_active),
        .spi_irq(spi_irq),
        .uart_irq(uart_irq)
    );

endmodule

// Control and status registers module
module control_registers (
    input clk,
    input rst,
    input wb_valid,
    input wb_we,
    input [7:0] wb_addr,
    input [31:0] wb_data_in,
    output reg [31:0] wb_data_out,
    output reg wb_ack,
    input spi_active,
    input uart_active,
    input spi_irq,
    input uart_irq
);

    // Register addresses
    localparam STATUS_REG = 8'h00;
    localparam CONTROL_REG = 8'h04;
    localparam VERSION_REG = 8'h08;

    // Control register bits
    reg [31:0] control_reg;
    reg [31:0] status_reg;
    reg [31:0] version_reg;

    // Version register (read-only)
    assign version_reg = 32'h01000000; // Version 1.0.0.0

    // Status register (read-only)
    always @(*) begin
        status_reg = {28'b0, uart_irq, spi_irq, uart_active, spi_active};
    end

    // Wishbone interface
    always @(posedge clk) begin
        if (rst) begin
            wb_ack <= 1'b0;
            control_reg <= 32'h0;
        end else begin
            wb_ack <= 1'b0;
            
            if (wb_valid && !wb_ack) begin
                wb_ack <= 1'b1;
                
                if (wb_we) begin
                    // Write operation
                    case (wb_addr)
                        CONTROL_REG: control_reg <= wb_data_in;
                        default: ; // Read-only registers
                    endcase
                end else begin
                    // Read operation
                    case (wb_addr)
                        STATUS_REG: wb_data_out <= status_reg;
                        CONTROL_REG: wb_data_out <= control_reg;
                        VERSION_REG: wb_data_out <= version_reg;
                        default: wb_data_out <= 32'h0;
                    endcase
                end
            end
        end
    end

endmodule

`default_nettype wire
