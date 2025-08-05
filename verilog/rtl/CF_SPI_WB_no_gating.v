/*
 * Copyright 2025 ChipFoundry, a DBA of Umbralogic Technologies LLC
 * Copyright 2025 Efabless Corp.
 *
 * Author: Efabless Corp. (ip_admin@efabless.com)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* THIS FILE IS MODIFIED TO REMOVE CLOCK GATING */

`timescale 1ns / 1ps
`default_nettype none

module CF_SPI_WB_no_gating #(
    parameter CDW = 8,
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
    input  wire [1-1:0] miso,
    output wire [1-1:0] mosi,
    output wire [1-1:0] csb,
    output wire [1-1:0] sclk
);

  localparam RXDATA_REG_OFFSET = 16'h0000;
  localparam TXDATA_REG_OFFSET = 16'h0004;
  localparam CFG_REG_OFFSET = 16'h0008;
  localparam CTRL_REG_OFFSET = 16'h000C;
  localparam PR_REG_OFFSET = 16'h0010;
  localparam STATUS_REG_OFFSET = 16'h0014;
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

  wire [  1-1:0] CPOL;
  wire [  1-1:0] CPHA;
  wire [CDW-1:0] clk_divider;
  wire [  1-1:0] wr;
  wire [  1-1:0] rd;
  wire [  8-1:0] datai;
  wire [  8-1:0] datao;
  wire [  1-1:0] rx_en;
  wire [  1-1:0] rx_flush;
  wire [FAW-1:0] rx_threshold;
  wire [  1-1:0] rx_empty;
  wire [  1-1:0] rx_full;
  wire [  1-1:0] rx_level_above;
  wire [FAW-1:0] rx_level;
  wire [  1-1:0] tx_flush;
  wire [FAW-1:0] tx_threshold;
  wire [  1-1:0] tx_empty;
  wire [  1-1:0] tx_full;
  wire [  1-1:0] tx_level_below;
  wire [FAW-1:0] tx_level;
  wire [  1-1:0] busy;
  wire [  1-1:0] done;
  wire [  1-1:0] ss;

  // Register file and control logic
  always @(posedge clk or posedge rst_i) begin
    if (rst_i) begin
      ack_o <= 1'b0;
      CPOL <= 1'b0;
      CPHA <= 1'b0;
      clk_divider <= {CDW{1'b0}};
      rx_en <= 1'b0;
      rx_flush <= 1'b0;
      rx_threshold <= {FAW{1'b0}};
      tx_flush <= 1'b0;
      tx_threshold <= {FAW{1'b0}};
    end else begin
      ack_o <= wb_valid;
      
      if (wb_we) begin
        case (adr_i[15:0])
          CFG_REG_OFFSET: begin
            CPOL <= dat_i[0];
            CPHA <= dat_i[1];
            clk_divider <= dat_i[CDW+1:2];
          end
          CTRL_REG_OFFSET: begin
            rx_en <= dat_i[0];
            rx_flush <= dat_i[1];
            tx_flush <= dat_i[2];
          end
          PR_REG_OFFSET: begin
            rx_threshold <= dat_i[FAW-1:0];
            tx_threshold <= dat_i[FAW+15:16];
          end
        endcase
      end
    end
  end

  // Read data multiplexing
  assign dat_o = 
    (adr_i[15:0] == RXDATA_REG_OFFSET) ? {24'h0, datao} :
    (adr_i[15:0] == TXDATA_REG_OFFSET) ? {24'h0, datai} :
    (adr_i[15:0] == CFG_REG_OFFSET) ? {32-CDW-2{1'b0}, clk_divider, CPHA, CPOL} :
    (adr_i[15:0] == CTRL_REG_OFFSET) ? {29'h0, tx_flush, rx_flush, rx_en} :
    (adr_i[15:0] == PR_REG_OFFSET) ? {16'h0, tx_threshold, rx_threshold} :
    (adr_i[15:0] == STATUS_REG_OFFSET) ? {30'h0, busy, done} :
    (adr_i[15:0] == RX_FIFO_LEVEL_REG_OFFSET) ? {28'h0, rx_level} :
    (adr_i[15:0] == TX_FIFO_LEVEL_REG_OFFSET) ? {28'h0, tx_level} :
    (adr_i[15:0] == IM_REG_OFFSET) ? 32'h0 :
    (adr_i[15:0] == MIS_REG_OFFSET) ? {31'h0, IRQ} :
    (adr_i[15:0] == RIS_REG_OFFSET) ? {31'h0, IRQ} :
    32'h0;

  // SPI core instance
  CF_SPI #(
    .CDW(CDW),
    .FAW(FAW)
  ) spi_core (
    .clk(clk),
    .rst_n(rst_n),
    .CPOL(CPOL),
    .CPHA(CPHA),
    .clk_divider(clk_divider),
    .wr(wr),
    .rd(rd),
    .datai(datai),
    .datao(datao),
    .enable(1'b1),
    .rx_en(rx_en),
    .rx_flush(rx_flush),
    .rx_threshold(rx_threshold),
    .rx_empty(rx_empty),
    .rx_full(rx_full),
    .rx_level_above(rx_level_above),
    .rx_level(rx_level),
    .tx_flush(tx_flush),
    .tx_threshold(tx_threshold),
    .tx_empty(tx_empty),
    .tx_full(tx_full),
    .tx_level_below(tx_level_below),
    .tx_level(tx_level),
    .busy(busy),
    .done(done),
    .miso(miso),
    .mosi(mosi),
    .csb(csb),
    .ss(ss),
    .sclk(sclk)
  );

  // Control signals
  assign wr = wb_we && (adr_i[15:0] == TXDATA_REG_OFFSET);
  assign rd = wb_re && (adr_i[15:0] == RXDATA_REG_OFFSET);
  assign datai = dat_i[7:0];
  assign ss = 1'b1; // Always selected
  assign IRQ = rx_level_above || tx_level_below || done;

endmodule 