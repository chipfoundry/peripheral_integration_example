/*
	Copyright 2024-2025 ChipFoundry, a DBA of Umbralogic Technologies LLC.

	Original Copyright 2025 Efabless Corp.
	Author: Efabless Corp. (ip_admin@efabless.com)

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	    www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.

*/

/* THIS FILE IS MODIFIED TO REMOVE CLOCK GATING */

`timescale 1ns / 1ps
`default_nettype none

module CF_UART_WB_no_gating #(
    parameter SC = 8,
    MDW = 9,
    GFLEN = 8,
    FAW = 4
) (

    input  wire         clk_i,
    input  wire         rst_i,
    input  wire [ 31:0] adr_i,
    input  wire [ 31:0] dat_i,
    output wire [ 31:0] dat_o,
    input  wire [  3:0] sel_i,
    input  wire         cyc_i,
    input  wire         stb_i,
    output reg          ack_o,
    input  wire         we_i,
    output wire         IRQ,
    input  wire [1-1:0] rx,
    output wire [1-1:0] tx
);

  localparam RXDATA_REG_OFFSET = 16'h0000;
  localparam TXDATA_REG_OFFSET = 16'h0004;
  localparam PR_REG_OFFSET = 16'h0008;
  localparam CTRL_REG_OFFSET = 16'h000C;
  localparam CFG_REG_OFFSET = 16'h0010;
  localparam MATCH_REG_OFFSET = 16'h001C;
  localparam RX_FIFO_LEVEL_REG_OFFSET = 16'hFE00;
  localparam RX_FIFO_THRESHOLD_REG_OFFSET = 16'hFE04;
  localparam RX_FIFO_FLUSH_REG_OFFSET = 16'hFE08;
  localparam TX_FIFO_LEVEL_REG_OFFSET = 16'hFE10;
  localparam TX_FIFO_THRESHOLD_REG_OFFSET = 16'hFE14;
  localparam TX_FIFO_FLUSH_REG_OFFSET = 16'hFE18;
  localparam IM_REG_OFFSET = 16'hFF00;
  localparam MIS_REG_OFFSET = 16'hFF04;
  localparam RIS_REG_OFFSET = 16'hFF08;
  localparam IC_REG_OFFSET = 16'hFF0C;

  // Remove clock gating - use clock directly
  wire clk = clk_i;
  wire rst_n = (~rst_i);

  wire           wb_valid = cyc_i & stb_i;
  wire           wb_we = we_i & wb_valid;
  wire           wb_re = ~we_i & wb_valid;
  wire [    3:0] wb_byte_sel = sel_i & {4{wb_we}};

  wire [ 16-1:0] prescaler;
  wire [  1-1:0] en;
  wire [  1-1:0] tx_en;
  wire [  1-1:0] rx_en;
  wire [MDW-1:0] wdata;
  wire [  6-1:0] timeout_bits;
  wire [  1-1:0] loopback_en;
  wire [  1-1:0] glitch_filter_en;
  wire [FAW-1:0] tx_level;
  wire [FAW-1:0] rx_level;
  wire [  1-1:0] rd;
  wire [  1-1:0] wr;
  wire [  1-1:0] tx_fifo_flush;
  wire [  1-1:0] rx_fifo_flush;
  wire [  4-1:0] data_size;
  wire [  1-1:0] stop_bits_count;
  wire [  2-1:0] parity_type;
  wire [  4-1:0] txfifotr;
  wire [  4-1:0] rxfifotr;
  wire [MDW-1:0] match_data;
  wire [  1-1:0] tx_empty;
  wire [  1-1:0] tx_full;
  wire [FAW-1:0] tx_level_out;
  wire [  1-1:0] tx_level_below;
  wire [MDW-1:0] rdata;
  wire [  1-1:0] rx_empty;
  wire [  1-1:0] rx_full;
  wire [FAW-1:0] rx_level_out;
  wire [  1-1:0] rx_level_above;
  wire [  1-1:0] break_flag;
  wire [  1-1:0] match_flag;
  wire [  1-1:0] frame_error_flag;
  wire [  1-1:0] parity_error_flag;
  wire [  1-1:0] overrun_flag;
  wire [  1-1:0] timeout_flag;

  // Register file and control logic
  always @(posedge clk or posedge rst_i) begin
    if (rst_i) begin
      ack_o <= 1'b0;
      prescaler <= 16'h0;
      en <= 1'b0;
      tx_en <= 1'b0;
      rx_en <= 1'b0;
      data_size <= 4'h8;
      stop_bits_count <= 1'b0;
      parity_type <= 2'h0;
      txfifotr <= 4'h0;
      rxfifotr <= 4'h0;
      match_data <= {MDW{1'b0}};
      timeout_bits <= 6'h0;
      loopback_en <= 1'b0;
      glitch_filter_en <= 1'b0;
      tx_fifo_flush <= 1'b0;
      rx_fifo_flush <= 1'b0;
    end else begin
      ack_o <= wb_valid;
      
      if (wb_we) begin
        case (adr_i[15:0])
          PR_REG_OFFSET: prescaler <= dat_i[15:0];
          CTRL_REG_OFFSET: begin
            en <= dat_i[0];
            tx_en <= dat_i[1];
            rx_en <= dat_i[2];
            tx_fifo_flush <= dat_i[3];
            rx_fifo_flush <= dat_i[4];
          end
          CFG_REG_OFFSET: begin
            data_size <= dat_i[3:0];
            stop_bits_count <= dat_i[4];
            parity_type <= dat_i[6:5];
            txfifotr <= dat_i[11:8];
            rxfifotr <= dat_i[15:12];
            timeout_bits <= dat_i[21:16];
            loopback_en <= dat_i[22];
            glitch_filter_en <= dat_i[23];
          end
          MATCH_REG_OFFSET: match_data <= dat_i[MDW-1:0];
        endcase
      end
    end
  end

  // Read data multiplexing
  assign dat_o = 
    (adr_i[15:0] == RXDATA_REG_OFFSET) ? {24'h0, rdata} :
    (adr_i[15:0] == TXDATA_REG_OFFSET) ? {24'h0, wdata} :
    (adr_i[15:0] == PR_REG_OFFSET) ? {16'h0, prescaler} :
    (adr_i[15:0] == CTRL_REG_OFFSET) ? {27'h0, rx_fifo_flush, tx_fifo_flush, rx_en, tx_en, en} :
    (adr_i[15:0] == CFG_REG_OFFSET) ? {8'h0, glitch_filter_en, loopback_en, timeout_bits, rxfifotr, txfifotr, parity_type, stop_bits_count, data_size} :
    (adr_i[15:0] == MATCH_REG_OFFSET) ? {{32-MDW{1'b0}}, match_data} :
    (adr_i[15:0] == RX_FIFO_LEVEL_REG_OFFSET) ? {28'h0, rx_level_out} :
    (adr_i[15:0] == TX_FIFO_LEVEL_REG_OFFSET) ? {28'h0, tx_level_out} :
    (adr_i[15:0] == IM_REG_OFFSET) ? 32'h0 :
    (adr_i[15:0] == MIS_REG_OFFSET) ? {31'h0, IRQ} :
    (adr_i[15:0] == RIS_REG_OFFSET) ? {31'h0, IRQ} :
    32'h0;

  // UART core instance
  CF_UART #(
    .MDW(MDW),
    .FAW(FAW),
    .SC(SC),
    .GFLEN(GFLEN)
  ) uart_core (
    .clk(clk),
    .rst_n(rst_n),
    .prescaler(prescaler),
    .en(en),
    .tx_en(tx_en),
    .rx_en(rx_en),
    .rd(rd),
    .wr(wr),
    .wdata(wdata),
    .data_size(data_size),
    .stop_bits_count(stop_bits_count),
    .parity_type(parity_type),
    .txfifotr(txfifotr),
    .rxfifotr(rxfifotr),
    .match_data(match_data),
    .timeout_bits(timeout_bits),
    .loopback_en(loopback_en),
    .glitch_filter_en(glitch_filter_en),
    .tx_fifo_flush(tx_fifo_flush),
    .rx_fifo_flush(rx_fifo_flush),
    .tx_empty(tx_empty),
    .tx_full(tx_full),
    .tx_level(tx_level_out),
    .tx_level_below(tx_level_below),
    .rdata(rdata),
    .rx_empty(rx_empty),
    .rx_full(rx_full),
    .rx_level(rx_level_out),
    .rx_level_above(rx_level_above),
    .break_flag(break_flag),
    .match_flag(match_flag),
    .frame_error_flag(frame_error_flag),
    .parity_error_flag(parity_error_flag),
    .overrun_flag(overrun_flag),
    .timeout_flag(timeout_flag),
    .rx(rx),
    .tx(tx)
  );

  // Control signals
  assign rd = wb_re && (adr_i[15:0] == RXDATA_REG_OFFSET);
  assign wr = wb_we && (adr_i[15:0] == TXDATA_REG_OFFSET);
  assign wdata = dat_i[MDW-1:0];
  assign IRQ = match_flag || frame_error_flag || parity_error_flag || overrun_flag || timeout_flag || 
               (rx_level_above && rx_en) || (tx_level_below && tx_en);

endmodule 