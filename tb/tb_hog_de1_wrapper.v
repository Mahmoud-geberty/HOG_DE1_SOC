`timescale 1ns/1ns
module tb_hog_de1_wrapper(); 

localparam DATA_WIDTH = 8;
localparam ADDR_WIDTH = 5;
localparam BUS_WIDTH  = 128;
localparam BUS_BYTES  = BUS_WIDTH/8;

    reg clk_slow, clk_fast, rst;

    // input pixel and handshake
    reg [DATA_WIDTH-1:0] input_pixel;
    reg                  pixel_valid; 
    wire                 pixel_ready;

    // led indicator
    wire                 blinking_led;

    // ext_bus to hps_block interface wires
    reg [ADDR_WIDTH-1:0] addr; 
    wire                  ack; 
    reg                  bus_enable; 
    reg                  r_wbar; 
    wire [BUS_WIDTH-1:0]  read_data;
    reg [BUS_WIDTH-1:0]  write_data;
    reg [BUS_BYTES-1:0]  byte_enable; 
    wire                  irq; 

    // pio status wires
    wire [31:0] hog_in_pio;
    wire [31:0] hog_out_pio; 
    wire [31:0] switch_out_pio; 
    wire [31:0] input_pixels_pio;

    wire [2:0] meta_data; // the 3 msb bits of the data are meta

    assign meta_data = read_data[BUS_WIDTH-1 -: 3]; 

hog_de1_wrapper#(
    .DATA_WIDTH     ( DATA_WIDTH )
)u_hog_de1_wrapper(
    .clk_slow       ( clk_slow       ),
    .clk_fast       ( clk_fast       ),
    .rst            ( rst            ),
    .input_pixel    ( input_pixel    ),
    .pixel_valid    ( pixel_valid    ),
    .pixel_ready    ( pixel_ready    ),
    .blinking_led   ( blinking_led   ),
    .addr           ( addr           ),
    .ack            ( ack            ),
    .bus_enable     ( bus_enable     ),
    .r_wbar         ( r_wbar         ),
    .read_data      ( read_data      ),
    .write_data     ( write_data     ),
    .byte_enable    ( byte_enable    ),
    .irq            ( irq            ),
    .hog_in_pio     ( hog_in_pio     ),
    .hog_out_pio    ( hog_out_pio    ),
    .switch_out_pio ( switch_out_pio ),
    .input_pixels_pio  ( input_pixels_pio  )
);


always #15 clk_slow = ~clk_slow;
always #5  clk_fast = ~clk_fast; 

initial begin 
    clk_slow = 0; 
    clk_fast = 0; 
    rst = 1;
    pixel_valid = 0; 
    input_pixel = 0; 

    write_data  = 0; 
    bus_enable  = 0; 
    r_wbar      = 0; 
    byte_enable = 0; 
    addr        = 0; 

    repeat (800) begin 
        @(posedge clk_slow);
        rst = 0; 
        pixel_valid = 1; 
        input_pixel = $random; 
    end
    repeat (100000) begin 
        @(posedge clk_slow);
        rst = 0; 
        input_pixel = $random; 
        write_data  = $random; 
        // bus_enable = 1; 
        // r_wbar     = 1; 
        // byte_enable = -1;  
    end
    $stop;
end



endmodule 