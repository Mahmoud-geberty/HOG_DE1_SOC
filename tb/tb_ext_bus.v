`timescale 1ns/1ns
module tb_ext_bus (); 

    parameter DATA_WIDTH = 128;
    parameter DATA_BYTES = DATA_WIDTH/8; 
    parameter ADDR_WIDTH = 5;

    reg                  clk, rst;
    reg [DATA_WIDTH-1:0] stream;
    reg                  stream_valid;
    wire                 stream_read;
    // external bus interface
    reg [ADDR_WIDTH-1:0] addr;
    reg                  bus_enable;
    reg                  r_wbar;      // read when high and write when low
    reg [DATA_WIDTH-1:0]     write_data;  // unused for now, just acknowledge the write op
    wire                 ack;
    wire [DATA_WIDTH-1:0]    read_data;
    reg  [DATA_BYTES-1:0]    byte_enable; // ignored 
    wire                 irq;         // unused

    ext_bus#(
        .DATA_WIDTH   ( DATA_WIDTH ),
        .ADDR_WIDTH   ( ADDR_WIDTH )
    )dut(
        .clk          ( clk          ),
        .rst          ( rst          ),
        .stream       ( stream       ),
        .stream_valid ( stream_valid ),
        .stream_ready ( stream_ready ),
        .addr         ( addr         ),
        .bus_enable   ( bus_enable   ),
        .r_wbar       ( r_wbar       ),
        .write_data   ( write_data   ),
        .ack          ( ack          ),
        .read_data    ( read_data    ),
        .byte_enable  ( byte_enable  ),
        .irq          ( irq          )
    );

    always #5 clk = ~clk; 

    initial begin 
        clk = 0; 
        rst = 1; 
        stream = 0; 
        stream_valid = 0; 
        addr = 0; 
        bus_enable = 0; 
        r_wbar = 0; 
        byte_enable = {16{1'b1}}; 
        write_data = 0; 

        repeat (20) begin 
            @(posedge clk);
            rst = 0; 
            stream_valid = 1; 
            bus_enable = 1; 
            r_wbar = 1; 
            stream = {10{$random}}; 
        end

        repeat (20) begin 
            @(posedge clk);
            rst = 0; 
            stream_valid = 0; 
            bus_enable = 1; 
            r_wbar = 0; 
        end

        repeat (6) begin 
            @(posedge clk);
            rst = 0; 
            stream_valid = 1; 
            bus_enable = 0; 
            r_wbar = 1; 
            stream = {10{$random}}; 
        end

        repeat (6) begin 
            @(posedge clk);
            rst = 0; 
            stream_valid = 1; 
            bus_enable = 0; 
            r_wbar = 1; 
            stream = {10{$random}}; 
        end

        repeat (20) begin 
            @(posedge clk);
            rst = 0; 
            stream_valid = 1; 
            bus_enable = 1; 
            r_wbar = 1; 
            stream = {10{$random}}; 
        end

        $stop; 
    end

endmodule 