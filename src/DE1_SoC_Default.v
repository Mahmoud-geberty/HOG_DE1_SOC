// ============================================================================
// Copyright (c) 2013 by Terasic Technologies Inc.
// ============================================================================
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.

module DE1_SoC_Default(

      ///////// ADC /////////
      output             ADC_CONVST,
      output             ADC_DIN,
      input              ADC_DOUT,
      output             ADC_SCLK,

      ///////// AUD /////////
      input              AUD_ADCDAT,
      inout              AUD_ADCLRCK,
      inout              AUD_BCLK,
      output             AUD_DACDAT,
      inout              AUD_DACLRCK,
      output             AUD_XCK,

      ///////// CLOCK2 /////////
      input              CLOCK2_50,

      ///////// CLOCK3 /////////
      input              CLOCK3_50,

      ///////// CLOCK4 /////////
      input              CLOCK4_50,

      ///////// CLOCK /////////
      input              CLOCK_50,

      ///////// DRAM /////////
      output      [12:0] DRAM_ADDR,
      output      [1:0]  DRAM_BA,
      output             DRAM_CAS_N,
      output             DRAM_CKE,
      output             DRAM_CLK,
      output             DRAM_CS_N,
      inout       [15:0] DRAM_DQ,
      output             DRAM_LDQM,
      output             DRAM_RAS_N,
      output             DRAM_UDQM,
      output             DRAM_WE_N,

      ///////// FAN /////////
      output             FAN_CTRL,

      ///////// FPGA /////////
      output             FPGA_I2C_SCLK,
      inout              FPGA_I2C_SDAT,

      ///////// GPIO /////////
      inout     [35:0]         GPIO_0,
      inout     [35:0]         GPIO_1,
 

      ///////// HEX0 /////////
      output      [6:0]  HEX0,

      ///////// HEX1 /////////
      output      [6:0]  HEX1,

      ///////// HEX2 /////////
      output      [6:0]  HEX2,

      ///////// HEX3 /////////
      output      [6:0]  HEX3,

      ///////// HEX4 /////////
      output      [6:0]  HEX4,

      ///////// HEX5 /////////
      output      [6:0]  HEX5,

      ///////// IRDA /////////
      input              IRDA_RXD,
      output             IRDA_TXD,

      ///////// KEY /////////
      input       [3:0]  KEY,

      ///////// LEDR /////////
      output      [9:0]  LEDR,

      ///////// PS2 /////////
      inout              PS2_CLK,
      inout              PS2_CLK2,
      inout              PS2_DAT,
      inout              PS2_DAT2,

      ///////// SW /////////
      input       [9:0]  SW,

      ///////// TD /////////
      input              TD_CLK27,
      input      [7:0]  TD_DATA,
      input             TD_HS,
      output             TD_RESET_N,
      input             TD_VS,

      ///////// VGA /////////
      output      [7:0]  VGA_B,
      output             VGA_BLANK_N,
      output             VGA_CLK,
      output      [7:0]  VGA_G,
      output             VGA_HS,
      output      [7:0]  VGA_R,
      output             VGA_SYNC_N,
      output             VGA_VS
);

//=======================================================
//  REG/WIRE declarations
//=======================================================
`include "de1_soc.vh"

//=======================================================
//  Structural coding
//=======================================================


PLL_IP u_PLL_IP(
    .refclk   ( CLOCK_50   ),
    .rst      ( rst      ),
    .outclk_0 ( clk_140 ),
    .outclk_1 ( clk_10 ),
    .locked   ( locked   )
);

localparam DATA_WIDTH = 8;
localparam IMAGE_WIDTH = 640; 
localparam IMAGE_HEIGHT = 480; 
localparam WINDOW_WIDTH = 1152; 
localparam BUS_WIDTH    = 128; 
localparam SCALE        = 9; 
localparam LEVELS       = 15; // depends on SCALE
localparam HOG_WIDTH    = WINDOW_WIDTH * LEVELS; 

localparam [LEVELS*4 - 1: 0] METADATA = {
    4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 
    4'd5, 4'd6, 4'd7, 4'd8, 4'd9, 
    4'd10, 4'd11, 4'd12, 4'd13, 4'd14, 4'd15
}; 

wire rst; 
wire [LEVELS-1:0] window_valid;
wire [LEVELS-1:0] window_ready; 
wire [LEVELS-1:0] window_fast_valid;
wire [LEVELS-1:0] window_fast_ready; 
wire [HOG_WIDTH-1:0] all_windows; 
wire [WINDOW_WIDTH-1:0] window_slow [0:LEVELS-1]; 
wire [WINDOW_WIDTH-1:0] window_fast [0:LEVELS-1]; 
wire [BUS_WIDTH-1:0] stream [0:LEVELS-1]; 
wire [LEVELS-1:0] stream_valid[i]; 
wire [LEVELS-1:0] stream_ready[i]; 

integer j; 
for (j = 0; j < LEVELS; j = j + 1) begin 
    assign window_slow[i] = all_windows[i*WINDOW_WIDTH +: WINDOW_WIDTH]; 
end

assign rst = ~KEY[0];

top#(
    .DATA_WIDTH       ( DATA_WIDTH ),
    .IMAGE_WIDTH      ( IMAGE_WIDTH ),
    .IMAGE_HEIGHT     ( IMAGE_HEIGHT ),
    .WINDOW_WIDTH     ( WINDOW_WIDTH ),
    .SCALE            ( SCALE )
) hog_top (
    .clk              ( clk_10           ),
    .rst              ( rst              ),
    // use the switches for now
    .pixel_in         ( SW[7:0]          ),
    .pixel_valid      ( KEY[1]           ),
    .window_ready     ( window_ready     ),
    .pixel_ready      ( pixel_ready      ),
    .detection_window ( all_windows      ),
    .window_valid     ( window_valid     )
);

genvar i; 

generate 
    for (i = 0; i < LEVELS; i = i + 1) begin: HOG_SERIALIZER 
        async_fifo (
            .DSIZE  ( WINDOW_WIDTH ),
            .ASIZE  ( 3 ), // upto 8 windows
            .FALLTHROUGH ( "TRUE" )
        )u_async_fifo(
            .wclk   ( clk_10 ),
            .wrst_n ( ~rst   ),
            .winc   ( window_valid[i] ),
            .wdata  ( window_slow[i]  ),
            .wfull  ( ~window_ready[i]  ),
            // .awfull ( awfull ),
            .rclk   ( clk_140 ),
            .rrst_n ( ~rst    ),
            .rinc   ( window_fast_ready   ),
            .rdata  ( window_fast[i]  ),
            .rempty ( ~window_fast_valid[i] ),
            .arempty  ( arempty  )
        );

        window_serializer#(
            .WINDOW_WIDTH ( WINDOW_WIDTH ),
            .BUS_WIDTH    ( BUS_WIDTH ),
            .META_WIDTH   ( 4 )
        )u_window_serializer(
            .clk          ( clk                  ),
            .rst          ( rst                  ),
            .window_valid ( window_fast_valid[i] ),
            .stream_ready ( stream_ready[i]      ),
            .metadata     ( METADATA[i]          ),
            .window       ( window_fast[i]       ),
            .window_ready ( window_fast_ready[i] ),
            .stream_valid ( stream_valid[i]      ),
            .stream       ( stream[i]            )
        );

        // TODO: each stream goes into a bus master

    end
endgenerate

endmodule
