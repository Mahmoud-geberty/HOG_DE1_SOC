`timescale 1ns/1ns
module tb_bus_switch(); 
    parameter BUS_WIDTH = 128;
    parameter LEVELS = 7;
    parameter INPUT_WIDTH = BUS_WIDTH * LEVELS;

    reg                   clk, rst;
    reg [LEVELS-1:0]      in_valid; 
    reg                   out_ready;
    reg [INPUT_WIDTH-1:0] in_stream;
    wire                  out_valid;
    wire [LEVELS-1:0]     in_ready; 
    wire [BUS_WIDTH-1:0]  out_stream;

bus_switch#(
    .BUS_WIDTH ( BUS_WIDTH ),
    .LEVELS    ( LEVELS )
)u_bus_switch(
    .clk       ( clk       ),
    .rst       ( rst       ),
    .in_valid  ( in_valid  ),
    .out_ready ( out_ready ),
    .in_stream ( in_stream ),
    .out_valid ( out_valid ),
    .in_ready  ( in_ready  ),
    .out_stream  ( out_stream  )
);

always #5 clk = ~clk; 

initial begin 
    clk = 0; 
    rst = 1; 
    in_valid = 0; 
    out_ready = 0;
    in_stream = 0; 

    in_valid = $random; 
    repeat (20) begin 
        @(posedge clk); 
        rst = 0; 
        in_stream = {20{$random}}; 
    end
    in_valid = $random; 
    out_ready = 1; 
    repeat (20) begin 
        @(posedge clk); 
        rst = 0; 
        in_stream = {20{$random}}; 
    end
    in_valid = $random; 
    repeat (20) begin 
        @(posedge clk); 
        rst = 0; 
        in_stream = {20{$random}}; 
    end
    in_valid = $random; 
    repeat (20) begin 
        @(posedge clk); 
        rst = 0; 
        in_stream = {20{$random}}; 
    end

    $stop; 
end

endmodule 