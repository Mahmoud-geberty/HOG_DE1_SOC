// The hog core with the necessary modules to connect it to the HPS
module hog_de1_wrapper #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5,
    parameter BUS_WIDTH    = 128,
    parameter BUS_BYTES    = BUS_WIDTH/8
) (
    input clk_slow, clk_fast, rst,

    // input pixel and handshake
    input [DATA_WIDTH-1:0] input_pixel,
    input                  pixel_valid, 
    output                 pixel_ready,

    // led indicator
    output                 blinking_led,

    // ext_bus to hps_block interface wires
    input [ADDR_WIDTH-1:0] addr, 
    output                  ack, 
    input                  bus_enable, 
    input                  r_wbar, 
    output [BUS_WIDTH-1:0]  read_data,
    input [BUS_WIDTH-1:0]  write_data,
    input [BUS_BYTES-1:0]  byte_enable, 
    output                  irq, 

    // pio status wires
    output [31:0] hog_in_pio,
    output [31:0] hog_out_pio, 
    output [31:0] switch_out_pio, 
    output [31:0] input_pixels_pio
); 

localparam IMAGE_WIDTH = 640; 
localparam IMAGE_HEIGHT = 480; 
localparam WINDOW_WIDTH = 1152; 
localparam SCALE        = 4; 
localparam LEVELS       = 7; // depends on SCALE
localparam HOG_WIDTH    = WINDOW_WIDTH * LEVELS; 

localparam [LEVELS*3 - 1: 0] METADATA = {
    3'd6, 3'd5, 3'd4, 3'd3,
    3'd2, 3'd1, 3'd0
}; 

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
wire [(BUS_WIDTH*LEVELS)-1:0] stream_concat; 
wire [LEVELS-1:0] stream_valid; 
wire [LEVELS-1:0] stream_ready; 
wire [BUS_WIDTH-1:0] switch_stream; // the output of the switch
wire                 switch_valid; 
wire                 switch_ready; 


genvar j; 
generate
    for (j = 0; j < LEVELS; j = j + 1) begin : SLOW_WINDOW
        assign window_slow[j] = all_windows[j*WINDOW_WIDTH +: WINDOW_WIDTH]; 
    end
    for (j = 0; j < LEVELS; j = j + 1) begin : STREAM_CONCATENATION
        assign stream_concat[j*BUS_WIDTH +: BUS_WIDTH] = stream[j]; 
    end
endgenerate

assign window_ready = ~window_slow_ready; 
assign window_fast_valid = ~window_fast_valid_n;


top#(
    .DATA_WIDTH       ( DATA_WIDTH ),
    .IMAGE_WIDTH      ( IMAGE_WIDTH ),
    .IMAGE_HEIGHT     ( IMAGE_HEIGHT ),
    .WINDOW_WIDTH     ( WINDOW_WIDTH ),
    .SCALE            ( SCALE )
) hog_top (
    .clk              ( clk_slow         ),
    .rst              ( rst              ),
    // use the switches for now
    .pixel_in         ( input_pixel      ),
    .pixel_valid      ( pixel_valid      ),
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
            .wclk   ( clk_slow               ),
            .wrst_n ( ~rst                   ),
            .winc   ( window_valid[i]        ),
            .wdata  ( window_slow[i]         ),
            .wfull  ( window_slow_ready[i]   ),
            // .awfull ( awfull ),
            .rclk   ( clk_fast               ),
            .rrst_n ( ~rst                   ),
            .rinc   ( window_fast_ready[i]   ),
            .rdata  ( window_fast[i]         ),
            .rempty ( window_fast_valid_n[i] ),
            .arempty  ( arempty              )
        );

        window_serializer#(
            .WINDOW_WIDTH ( WINDOW_WIDTH ),
            .BUS_WIDTH    ( BUS_WIDTH ),
            .META_WIDTH   ( 3 )
        )u_window_serializer(
            .clk          ( clk_fast             ),
            .rst          ( rst                  ),
            .window_valid ( window_fast_valid[i] ),
            .stream_ready ( stream_ready[i]      ),
            .metadata     ( METADATA[i*3 +: 3]   ),
            .window       ( window_fast[i]       ),
            .window_ready ( window_fast_ready[i] ),
            .stream_valid ( stream_valid[i]      ),
            .stream       ( stream[i]            )
        );
    end
endgenerate

bus_switch#(
    .BUS_WIDTH ( BUS_WIDTH ),
    .LEVELS    ( LEVELS )
)u_bus_switch(
    .clk       ( clk_fast  ),
    .rst       ( rst       ),
    .in_valid  ( stream_valid ),
    .out_ready ( switch_ready ),
    .in_stream ( stream_concat),
    .out_valid ( switch_valid ),
    .in_ready  ( stream_ready ),
    .out_stream  ( switch_stream  )
);

ext_bus#(
    .DATA_WIDTH   ( BUS_WIDTH ),
    .ADDR_WIDTH   ( ADDR_WIDTH )
)u_ext_bus(
    .clk          ( clk_fast      ),
    .rst          ( rst           ),
    .stream       ( switch_stream ),
    .stream_valid ( switch_valid  ),
    .stream_ready ( switch_ready  ),
    .addr         ( addr          ),
    .bus_enable   ( bus_enable    ),
    .r_wbar       ( r_wbar        ),
    .write_data   ( write_data    ),
    .ack          ( ack           ),
    .read_data    ( read_data     ),
    .byte_enable  ( byte_enable   ),
    .irq          ( irq           )
);

sys_status#(
    .CLOCK_FREQ (10_000_000),
    .LEVELS     ( LEVELS )
)u_sys_status( 
    .clk                     ( clk_slow                ),
    .rst                     ( rst                     ),
    .blinking_led            ( blinking_led            ),
    .hog_input_valid         ( pixel_valid             ),
    .hog_input_ready         ( pixel_ready             ),
    .hog_out_valid           ( window_valid            ),
    .hog_out_ready           ( window_ready            ),
    .switch_out_valid        ( switch_valid            ),
    .switch_out_ready        ( switch_ready            ),
    .input_pixels            ( input_pixel             ),
    .hog_in_pio              ( hog_in_pio              ),
    .hog_out_pio             ( hog_out_pio             ),
    .switch_out_pio          ( switch_out_pio          ),
    .input_pixels_pio        ( input_pixels_pio        )
);



endmodule