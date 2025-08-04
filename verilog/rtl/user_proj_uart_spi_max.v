// SPDX-FileCopyrightText: 2025 ChipFoundry, a DBA of Umbralogic Technologies LLC
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
 * user_proj_uart_spi_max
 *
 * This user project maximizes the number of UART and SPI IPs
 * that can fit in the available I/O pins.
 *
 * OPTIMAL CONFIGURATION: 7 UARTs + 6 SPIs = 13 total peripherals
 * 
 * I/O Pin Mapping (38 total pins used):
 * - UART0:  io_in[0] (RX), io_out[1] (TX)                    = 2 pins
 * - UART1:  io_in[2] (RX), io_out[3] (TX)                    = 2 pins
 * - UART2:  io_in[4] (RX), io_out[5] (TX)                    = 2 pins
 * - UART3:  io_in[6] (RX), io_out[7] (TX)                    = 2 pins
 * - UART4:  io_in[8] (RX), io_out[9] (TX)                    = 2 pins
 * - UART5:  io_in[10] (RX), io_out[11] (TX)                  = 2 pins
 * - UART6:  io_in[12] (RX), io_out[13] (TX)                  = 2 pins
 * - SPI0:   io_in[14] (MISO), io_out[15] (MOSI), io_out[16] (SCLK), io_out[17] (CS) = 4 pins
 * - SPI1:   io_in[18] (MISO), io_out[19] (MOSI), io_out[20] (SCLK), io_out[21] (CS) = 4 pins
 * - SPI2:   io_in[22] (MISO), io_out[23] (MOSI), io_out[24] (SCLK), io_out[25] (CS) = 4 pins
 * - SPI3:   io_in[26] (MISO), io_out[27] (MOSI), io_out[28] (SCLK), io_out[29] (CS) = 4 pins
 * - SPI4:   io_in[30] (MISO), io_out[31] (MOSI), io_out[32] (SCLK), io_out[33] (CS) = 4 pins
 * - SPI5:   io_in[34] (MISO), io_out[35] (MOSI), io_out[36] (SCLK), io_out[37] (CS) = 4 pins
 *
 * Total: 7 UARTs + 6 SPIs = 13 peripherals
 * Pins used: 38 pins (exact fit!)
 *
 *-------------------------------------------------------------
 */

module user_proj_uart_spi_max #(
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

    // IOs - using all available pins
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);

    // Wishbone interface signals for each peripheral
    wire [31:0] uart_dat_o [6:0];  // 7 UARTs
    wire [6:0] uart_ack_o;
    wire [6:0] uart_irq;
    
    wire [31:0] spi_dat_o [5:0];   // 6 SPIs
    wire [5:0] spi_ack_o;
    wire [5:0] spi_irq;
    
    // I/O enable signals
    reg [`MPRJ_IO_PADS-1:0] io_oeb_reg;
    
    // Address decoding for multiple peripherals
    wire [12:0] peripheral_sel;  // 13 peripherals total
    wire [31:0] peripheral_adr;
    
    // Address ranges for each peripheral (4KB each)
    // UART0: 0x3000_0000 - 0x3000_0FFF
    // UART1: 0x3000_1000 - 0x3000_1FFF
    // UART2: 0x3000_2000 - 0x3000_2FFF
    // UART3: 0x3000_3000 - 0x3000_3FFF
    // UART4: 0x3000_4000 - 0x3000_4FFF
    // UART5: 0x3000_5000 - 0x3000_5FFF
    // UART6: 0x3000_6000 - 0x3000_6FFF
    // SPI0:  0x3000_7000 - 0x3000_7FFF
    // SPI1:  0x3000_8000 - 0x3000_8FFF
    // SPI2:  0x3000_9000 - 0x3000_9FFF
    // SPI3:  0x3000_A000 - 0x3000_AFFF
    // SPI4:  0x3000_B000 - 0x3000_BFFF
    // SPI5:  0x3000_C000 - 0x3000_CFFF
    
    assign peripheral_adr = wbs_adr_i - 32'h3000_0000;
    assign peripheral_sel[0] = (wbs_adr_i >= 32'h3000_0000) && (wbs_adr_i < 32'h3000_1000); // UART0
    assign peripheral_sel[1] = (wbs_adr_i >= 32'h3000_1000) && (wbs_adr_i < 32'h3000_2000); // UART1
    assign peripheral_sel[2] = (wbs_adr_i >= 32'h3000_2000) && (wbs_adr_i < 32'h3000_3000); // UART2
    assign peripheral_sel[3] = (wbs_adr_i >= 32'h3000_3000) && (wbs_adr_i < 32'h3000_4000); // UART3
    assign peripheral_sel[4] = (wbs_adr_i >= 32'h3000_4000) && (wbs_adr_i < 32'h3000_5000); // UART4
    assign peripheral_sel[5] = (wbs_adr_i >= 32'h3000_5000) && (wbs_adr_i < 32'h3000_6000); // UART5
    assign peripheral_sel[6] = (wbs_adr_i >= 32'h3000_6000) && (wbs_adr_i < 32'h3000_7000); // UART6
    assign peripheral_sel[7] = (wbs_adr_i >= 32'h3000_7000) && (wbs_adr_i < 32'h3000_8000); // SPI0
    assign peripheral_sel[8] = (wbs_adr_i >= 32'h3000_8000) && (wbs_adr_i < 32'h3000_9000); // SPI1
    assign peripheral_sel[9] = (wbs_adr_i >= 32'h3000_9000) && (wbs_adr_i < 32'h3000_A000); // SPI2
    assign peripheral_sel[10] = (wbs_adr_i >= 32'h3000_A000) && (wbs_adr_i < 32'h3000_B000); // SPI3
    assign peripheral_sel[11] = (wbs_adr_i >= 32'h3000_B000) && (wbs_adr_i < 32'h3000_C000); // SPI4
    assign peripheral_sel[12] = (wbs_adr_i >= 32'h3000_C000) && (wbs_adr_i < 32'h3000_D000); // SPI5
    
    // Wishbone response multiplexing for UARTs
    wire [31:0] wbs_dat_o_uart = 
        (peripheral_sel[0]) ? uart_dat_o[0] :
        (peripheral_sel[1]) ? uart_dat_o[1] :
        (peripheral_sel[2]) ? uart_dat_o[2] :
        (peripheral_sel[3]) ? uart_dat_o[3] :
        (peripheral_sel[4]) ? uart_dat_o[4] :
        (peripheral_sel[5]) ? uart_dat_o[5] :
        (peripheral_sel[6]) ? uart_dat_o[6] : 32'h0;
        
    wire wbs_ack_o_uart = |(peripheral_sel[6:0] & uart_ack_o);
    
    // UART Instances (7 UARTs)
    generate
        genvar i;
        for (i = 0; i < 7; i = i + 1) begin : uart_gen
            CF_UART_WB #(
                .SC(8),
                .MDW(9),
                .GFLEN(8),
                .FAW(4)
            ) uart_inst (
                .clk_i(wb_clk_i),
                .rst_i(wb_rst_i),
                .adr_i(peripheral_adr),
                .dat_i(wbs_dat_i),
                .dat_o(uart_dat_o[i]),
                .sel_i(wbs_sel_i),
                .cyc_i(wbs_cyc_i & peripheral_sel[i]),
                .stb_i(wbs_stb_i & peripheral_sel[i]),
                .ack_o(uart_ack_o[i]),
                .we_i(wbs_we_i),
                .IRQ(uart_irq[i]),
                .rx(io_in[i*2]),
                .tx(io_out[i*2+1])
            );
        end
    endgenerate
    
    // SPI Instances (6 SPIs)
    generate
        for (i = 0; i < 6; i = i + 1) begin : spi_gen
            CF_SPI_WB #(
                .CDW(8),
                .FAW(4)
            ) spi_inst (
                .clk_i(wb_clk_i),
                .rst_i(wb_rst_i),
                .adr_i(peripheral_adr),
                .dat_i(wbs_dat_i),
                .dat_o(spi_dat_o[i]),
                .sel_i(wbs_sel_i),
                .cyc_i(wbs_cyc_i & peripheral_sel[i+7]),
                .stb_i(wbs_stb_i & peripheral_sel[i+7]),
                .ack_o(spi_ack_o[i]),
                .we_i(wbs_we_i),
                .IRQ(spi_irq[i]),
                .miso(io_in[14 + i*4]),
                .mosi(io_out[15 + i*4]),
                .sclk(io_out[16 + i*4]),
                .csb(io_out[17 + i*4])
            );
        end
    endgenerate
    
    // Wishbone response multiplexing for all peripherals
    wire [31:0] wbs_dat_o_spi = 
        (peripheral_sel[7]) ? spi_dat_o[0] :
        (peripheral_sel[8]) ? spi_dat_o[1] :
        (peripheral_sel[9]) ? spi_dat_o[2] :
        (peripheral_sel[10]) ? spi_dat_o[3] :
        (peripheral_sel[11]) ? spi_dat_o[4] :
        (peripheral_sel[12]) ? spi_dat_o[5] : 32'h0;
        
    wire wbs_ack_o_spi = |(peripheral_sel[12:7] & spi_ack_o);
    
    // Final Wishbone interface connections
    assign wbs_dat_o = wbs_dat_o_uart | wbs_dat_o_spi;
    assign wbs_ack_o = wbs_ack_o_uart | wbs_ack_o_spi;
    
    // Interrupt connections
    assign irq[0] = |uart_irq;  // Any UART interrupt
    assign irq[1] = |spi_irq;   // Any SPI interrupt
    assign irq[2] = 1'b0;       // Unused
    
    // I/O enable configuration
    always @(*) begin
        io_oeb_reg = {`MPRJ_IO_PADS{1'b1}}; // Default all pins as inputs
        
        // UART TX pins (outputs) - 7 UARTs
        io_oeb_reg[1] = 1'b0;   // UART0 TX
        io_oeb_reg[3] = 1'b0;   // UART1 TX
        io_oeb_reg[5] = 1'b0;   // UART2 TX
        io_oeb_reg[7] = 1'b0;   // UART3 TX
        io_oeb_reg[9] = 1'b0;   // UART4 TX
        io_oeb_reg[11] = 1'b0;  // UART5 TX
        io_oeb_reg[13] = 1'b0;  // UART6 TX
        
        // SPI output pins - 6 SPIs
        io_oeb_reg[15] = 1'b0;  // SPI0 MOSI
        io_oeb_reg[16] = 1'b0;  // SPI0 SCLK
        io_oeb_reg[17] = 1'b0;  // SPI0 CS
        io_oeb_reg[19] = 1'b0;  // SPI1 MOSI
        io_oeb_reg[20] = 1'b0;  // SPI1 SCLK
        io_oeb_reg[21] = 1'b0;  // SPI1 CS
        io_oeb_reg[23] = 1'b0;  // SPI2 MOSI
        io_oeb_reg[24] = 1'b0;  // SPI2 SCLK
        io_oeb_reg[25] = 1'b0;  // SPI2 CS
        io_oeb_reg[27] = 1'b0;  // SPI3 MOSI
        io_oeb_reg[28] = 1'b0;  // SPI3 SCLK
        io_oeb_reg[29] = 1'b0;  // SPI3 CS
        io_oeb_reg[31] = 1'b0;  // SPI4 MOSI
        io_oeb_reg[32] = 1'b0;  // SPI4 SCLK
        io_oeb_reg[33] = 1'b0;  // SPI4 CS
        io_oeb_reg[35] = 1'b0;  // SPI5 MOSI
        io_oeb_reg[36] = 1'b0;  // SPI5 SCLK
        io_oeb_reg[37] = 1'b0;  // SPI5 CS
    end
    
    assign io_oeb = io_oeb_reg;

endmodule 