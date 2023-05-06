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
localparam ADDR_WIDTH = 5;
localparam IMAGE_WIDTH = 640; 
localparam IMAGE_HEIGHT = 480; 
localparam WINDOW_WIDTH = 1152; 
localparam BUS_WIDTH    = 128; 
localparam BUS_BYTES    = BUS_WIDTH/8; 
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
wire [LEVELS-1:0] window_slow_ready; 
wire [LEVELS-1:0] window_fast_valid;
wire [LEVELS-1:0] window_fast_valid_n;
wire [LEVELS-1:0] window_fast_ready; 
wire [HOG_WIDTH-1:0] all_windows; 
wire [WINDOW_WIDTH-1:0] window_slow [0:LEVELS-1]; 
wire [WINDOW_WIDTH-1:0] window_fast [0:LEVELS-1]; 
wire [BUS_WIDTH-1:0] stream [0:LEVELS-1]; 
wire [LEVELS-1:0] stream_valid; 
wire [LEVELS-1:0] stream_ready; 

// ext_bus to hps_block interface wires
wire [ADDR_WIDTH-1:0] addr        [0:LEVELS-1]; 
wire                  ack         [0:LEVELS-1]; 
wire [LEVELS-1:0]     bus_enable; 
wire [LEVELS-1:0]     r_wbar; 
wire [BUS_WIDTH-1:0]  read_data   [0:LEVELS-1];
wire [BUS_WIDTH-1:0]  write_data  [0:LEVELS-1];
wire [BUS_BYTES-1:0]  byte_enable [0:LEVELS-1]; 
wire                  irq         [0:LEVELS-1]; 

genvar j; 
generate
    for (j = 0; j < LEVELS; j = j + 1) begin : SLOW_WINDOW
        assign window_slow[j] = all_windows[j*WINDOW_WIDTH +: WINDOW_WIDTH]; 
    end
endgenerate

assign window_ready = ~window_slow_ready; 
assign window_fast_valid = ~window_fast_valid_n;

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
        async_fifo #(
            .DSIZE  ( WINDOW_WIDTH ),
            .ASIZE  ( 3 ), // upto 8 windows
            .FALLTHROUGH ( "TRUE" )
        )u_async_fifo(
            .wclk   ( clk_10 ),
            .wrst_n ( ~rst   ),
            .winc   ( window_valid[i] ),
            .wdata  ( window_slow[i]  ),
            .wfull  ( window_ready[i]  ),
            // .awfull ( awfull ),
            .rclk   ( clk_140 ),
            .rrst_n ( ~rst    ),
            .rinc   ( window_fast_ready   ),
            .rdata  ( window_fast[i]  ),
            .rempty ( window_fast_valid_n[i] ),
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

        ext_bus#(
            .DATA_WIDTH   ( BUS_WIDTH ),
            .ADDR_WIDTH   ( ADDR_WIDTH )
        )u_ext_bus(
            .clk          ( clk_140         ),
            .rst          ( rst             ),
            .stream       ( stream[i]       ),
            .stream_valid ( stream_valid[i] ),
            .stream_ready ( stream_ready[i] ),
            .addr         ( addr[i]         ),
            .bus_enable   ( bus_enable[i]   ),
            .r_wbar       ( r_wbar[i]       ),
            .write_data   ( write_data[i]   ),
            .ack          ( ack[i]          ),
            .read_data    ( read_data[i]    ),
            .byte_enable  ( byte_enable[i]  ),
            .irq          ( irq[i]          )
    );

    end
endgenerate

hps0 hps_block (
		.clk_clk               (clk_140),               //       clk.clk
        // memory unused for now
		.memory_mem_a          (),          //    memory.mem_a
		.memory_mem_ba         (),         //          .mem_ba
		.memory_mem_ck         (),         //          .mem_ck
		.memory_mem_ck_n       (),       //          .mem_ck_n
		.memory_mem_cke        (),        //          .mem_cke
		.memory_mem_cs_n       (),       //          .mem_cs_n
		.memory_mem_ras_n      (),      //          .mem_ras_n
		.memory_mem_cas_n      (),      //          .mem_cas_n
		.memory_mem_we_n       (),       //          .mem_we_n
		.memory_mem_reset_n    (),    //          .mem_reset_n
		.memory_mem_dq         (),         //          .mem_dq
		.memory_mem_dqs        (),        //          .mem_dqs
		.memory_mem_dqs_n      (),      //          .mem_dqs_n
		.memory_mem_odt        (),        //          .mem_odt
		.memory_mem_dm         (),         //          .mem_dm
		.memory_oct_rzqin      (),      //          .oct_rzqin
		.reset_reset_n         (~rst            ),  //     reset.reset_n
		.bridge_0_acknowledge  ( ack[0]         ),  //  bridge_0.acknowledge
		.bridge_0_irq          ( irq[0]         ),  //          .irq
		.bridge_0_address      ( addr[0]        ),  //          .address
		.bridge_0_bus_enable   ( bus_enable[0]  ),  //          .bus_enable
		.bridge_0_byte_enable  ( byte_enable[0] ),  //          .byte_enable
		.bridge_0_rw           ( r_wbar[0]      ),  //          .rw
		.bridge_0_write_data   ( write_data[0]  ),  //          .write_data
		.bridge_0_read_data    ( read_data[0]   ),  //          .read_data
		.bridge_1_acknowledge  ( ack[1]         ),  //  bridge_1.acknowledge
		.bridge_1_irq          ( irq[1]         ),  //          .irq
		.bridge_1_address      ( addr[1]        ),  //          .address
		.bridge_1_bus_enable   ( bus_enable[1]  ),  //          .bus_enable
		.bridge_1_byte_enable  ( byte_enable[1] ),  //          .byte_enable
		.bridge_1_rw           ( r_wbar[1]      ),  //          .rw
		.bridge_1_write_data   ( write_data[1]  ),  //          .write_data
		.bridge_1_read_data    ( read_data[1]   ),  //          .read_data
		.bridge_3_acknowledge  ( ack[3]         ),  //  bridge_3.acknowledge
		.bridge_3_irq          ( irq[3]         ),  //          .irq
		.bridge_3_address      ( addr[3]        ),  //          .address
		.bridge_3_bus_enable   ( bus_enable[3]  ),  //          .bus_enable
		.bridge_3_byte_enable  ( byte_enable[3] ),  //          .byte_enable
		.bridge_3_rw           ( r_wbar[3]      ),  //          .rw
		.bridge_3_write_data   ( write_data[3]  ),  //          .write_data
		.bridge_3_read_data    ( read_data[3]   ),  //          .read_data
		.bridge_2_acknowledge  ( ack[2]         ),  //  bridge_2.acknowledge
		.bridge_2_irq          ( irq[2]         ),  //          .irq
		.bridge_2_address      ( addr[2]        ),  //          .address
		.bridge_2_bus_enable   ( bus_enable[2]  ),  //          .bus_enable
		.bridge_2_byte_enable  ( byte_enable[2] ),  //          .byte_enable
		.bridge_2_rw           ( r_wbar[2]      ),  //          .rw
		.bridge_2_write_data   ( write_data[2]  ),  //          .write_data
		.bridge_2_read_data    ( read_data[2]   ),  //          .read_data
		.bridge_4_acknowledge  ( ack[4]         ),  //  bridge_4.acknowledge
		.bridge_4_irq          ( irq[4]         ),  //          .irq
		.bridge_4_address      ( addr[4]        ),  //          .address
		.bridge_4_bus_enable   ( bus_enable[4]  ),  //          .bus_enable
		.bridge_4_byte_enable  ( byte_enable[4] ),  //          .byte_enable
		.bridge_4_rw           ( r_wbar[4]      ),  //          .rw
		.bridge_4_write_data   ( write_data[4]  ),  //          .write_data
		.bridge_4_read_data    ( read_data[4]   ),  //          .read_data
		.bridge_5_acknowledge  ( ack[5]         ),  //  bridge_5.acknowledge
		.bridge_5_irq          ( irq[5]         ),  //          .irq
		.bridge_5_address      ( addr[5]        ),  //          .address
		.bridge_5_bus_enable   ( bus_enable[5]  ),  //          .bus_enable
		.bridge_5_byte_enable  ( byte_enable[5] ),  //          .byte_enable
		.bridge_5_rw           ( r_wbar[5]      ),  //          .rw
		.bridge_5_write_data   ( write_data[5]  ),  //          .write_data
		.bridge_5_read_data    ( read_data[5]   ),  //          .read_data
		.bridge_6_acknowledge  ( ack[6]         ),  //  bridge_6.acknowledge
		.bridge_6_irq          ( irq[6]         ),  //          .irq
		.bridge_6_address      ( addr[6]        ),  //          .address
		.bridge_6_bus_enable   ( bus_enable[6]  ),  //          .bus_enable
		.bridge_6_byte_enable  ( byte_enable[6] ),  //          .byte_enable
		.bridge_6_rw           ( r_wbar[6]      ),  //          .rw
		.bridge_6_write_data   ( write_data[6]  ),  //          .write_data
		.bridge_6_read_data    ( read_data[6]   ),  //          .read_data
		.bridge_7_acknowledge  ( ack[7]         ),  //  bridge_7.acknowledge
		.bridge_7_irq          ( irq[7]         ),  //          .irq
		.bridge_7_address      ( addr[7]        ),  //          .address
		.bridge_7_bus_enable   ( bus_enable[7]  ),  //          .bus_enable
		.bridge_7_byte_enable  ( byte_enable[7] ),  //          .byte_enable
		.bridge_7_rw           ( r_wbar[7]      ),  //          .rw
		.bridge_7_write_data   ( write_data[7]  ),  //          .write_data
		.bridge_7_read_data    ( read_data[7]   ),  //          .read_data
		.bridge_8_acknowledge  ( ack[8]         ),  //  bridge_8.acknowledge
		.bridge_8_irq          ( irq[8]         ),  //          .irq
		.bridge_8_address      ( addr[8]        ),  //          .address
		.bridge_8_bus_enable   ( bus_enable[8]  ),  //          .bus_enable
		.bridge_8_byte_enable  ( byte_enable[8] ),  //          .byte_enable
		.bridge_8_rw           ( r_wbar[8]      ),  //          .rw
		.bridge_8_write_data   ( write_data[8]  ),  //          .write_data
		.bridge_8_read_data    ( read_data[8]   ),  //          .read_data
		.bridge_9_acknowledge  ( ack[9]         ),  //  bridge_9.acknowledge
		.bridge_9_irq          ( irq[9]         ),  //          .irq
		.bridge_9_address      ( addr[9]        ),  //          .address
		.bridge_9_bus_enable   ( bus_enable[9]  ),  //          .bus_enable
		.bridge_9_byte_enable  ( byte_enable[9] ),  //          .byte_enable
		.bridge_9_rw           ( r_wbar[9]      ),  //          .rw
		.bridge_9_write_data   ( write_data[9]  ),  //          .write_data
		.bridge_9_read_data    ( read_data[9]   ),  //          .read_data
		.bridge_10_acknowledge ( ack[10]        ),  // bridge_10.acknowledge
		.bridge_10_irq         ( irq[10]        ),  //          .irq
		.bridge_10_address     ( addr[10]       ),  //          .address
		.bridge_10_bus_enable  ( bus_enable[10] ),  //          .bus_enable
		.bridge_10_byte_enable ( byte_enable[10]),  //          .byte_enable
		.bridge_10_rw          ( r_wbar[10]     ),  //          .rw
		.bridge_10_write_data  ( write_data[10] ),  //          .write_data
		.bridge_10_read_data   ( read_data[10]  ),  //          .read_data
		.bridge_11_acknowledge ( ack[11]        ),  // bridge_11.acknowledge
		.bridge_11_irq         ( irq[11]        ),  //          .irq
		.bridge_11_address     ( addr[11]       ),  //          .address
		.bridge_11_bus_enable  ( bus_enable[11] ),  //          .bus_enable
		.bridge_11_byte_enable ( byte_enable[11]),  //          .byte_enable
		.bridge_11_rw          ( r_wbar[11]     ),  //          .rw
		.bridge_11_write_data  ( write_data[11] ),  //          .write_data
		.bridge_11_read_data   ( read_data[11]  ),  //          .read_data
		.bridge_12_acknowledge ( ack[12]        ),  // bridge_12.acknowledge
		.bridge_12_irq         ( irq[12]        ),  //          .irq
		.bridge_12_address     ( addr[12]       ),  //          .address
		.bridge_12_bus_enable  ( bus_enable[12] ),  //          .bus_enable
		.bridge_12_byte_enable ( byte_enable[12]),  //          .byte_enable
		.bridge_12_rw          ( r_wbar[12]     ),  //          .rw
		.bridge_12_write_data  ( write_data[12] ),  //          .write_data
		.bridge_12_read_data   ( read_data[12]  ),  //          .read_data
		.bridge_13_acknowledge ( ack[13]        ),  // bridge_13.acknowledge
		.bridge_13_irq         ( irq[13]        ),  //          .irq
		.bridge_13_address     ( addr[13]       ),  //          .address
		.bridge_13_bus_enable  ( bus_enable[13] ),  //          .bus_enable
		.bridge_13_byte_enable ( byte_enable[13]),  //          .byte_enable
		.bridge_13_rw          ( r_wbar[13]     ),  //          .rw
		.bridge_13_write_data  ( write_data[13] ),  //          .write_data
		.bridge_13_read_data   ( read_data[13]  ),  //          .read_data
		.bridge_14_acknowledge ( ack[14]        ),  // bridge_14.acknowledge
		.bridge_14_irq         ( irq[14]        ),  //          .irq
		.bridge_14_address     ( addr[14]       ),  //          .address
		.bridge_14_bus_enable  ( bus_enable[14] ),  //          .bus_enable
		.bridge_14_byte_enable ( byte_enable[14]),  //          .byte_enable
		.bridge_14_rw          ( r_wbar[14]     ),  //          .rw
		.bridge_14_write_data  ( write_data[14] ),  //          .write_data
		.bridge_14_read_data   ( read_data[14]  ),  //          .read_data
	);

endmodule
