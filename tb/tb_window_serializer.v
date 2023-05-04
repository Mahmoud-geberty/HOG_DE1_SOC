`timescale 1ns/1ns
module tb_window_serializer(); 
    parameter WINDOW_WIDTH = 1152;
    parameter BUS_WIDTH = 128;
    parameter META_WIDTH = 4; // for now only contains the pyramid level

    reg                      clk, rst; 
    reg                      window_valid; 
    reg                      stream_ready; 
    reg [META_WIDTH-1:0]     metadata;
    reg [WINDOW_WIDTH-1:0]   window; 
    wire                     window_ready;
    wire                     stream_valid;
    wire     [BUS_WIDTH-1:0] stream; 

localparam STREAM_DATA_PORTION = BUS_WIDTH - META_WIDTH; 
// the last serial output will have about 36 bits of data only
localparam STREAM_DATA_REMAIN  = WINDOW_WIDTH % STREAM_DATA_PORTION; 
localparam STREAM_EMPTY_PORTION = STREAM_DATA_PORTION - STREAM_DATA_REMAIN; 

// "+1" as long as there is a meta portion added to each serial output
localparam SERIAL_COUNTER_MAX = (WINDOW_WIDTH / STREAM_DATA_PORTION) + 1; 
localparam SERIAL_COUNTER_WIDTH = $clog2(SERIAL_COUNTER_MAX-1); 

    wire [123:0] serial_window [0:8]; 
    wire [35:0] last_serial; 

    assign last_serial = window[9*STREAM_DATA_PORTION +: STREAM_DATA_REMAIN]; 

    genvar i; 

    for (i = 0; i < 9; i = i + 1) begin 
        assign serial_window[i] = window[i*STREAM_DATA_PORTION +: STREAM_DATA_PORTION]; 
    end

    window_serializer#(
        .WINDOW_WIDTH ( WINDOW_WIDTH ),
        .BUS_WIDTH    ( BUS_WIDTH ),
        .META_WIDTH   ( META_WIDTH )
    ) dut (
        .clk          ( clk          ),
        .rst          ( rst          ),
        .window_valid ( window_valid ),
        .stream_ready ( stream_ready ),
        .window       ( window       ),
        .metadata     (metadata      ),
        .window_ready ( window_ready ),
        .stream_valid ( stream_valid ),
        .stream       ( stream       )
    );

    always #5 clk = ~clk; 

    initial begin 
        clk = 0; 
        rst = 1; 
        window_valid = 0; 
        stream_ready = 0; 
        window = 0; 
        metadata = 0; 
        @(posedge clk); 
        rst = 0; 
        
        repeat(20) begin 
            @(posedge clk); 
            window_valid = 1; 
            stream_ready = 0; 
            if (window_valid && window_ready) begin 
                window = {50{$random}}; 
                metadata = $random; 
            end
        end
        repeat(15) begin 
            @(posedge clk); 
            window_valid = 0; 
            stream_ready = 1; 
            if (window_valid && window_ready) begin 
                window = {50{$random}}; 
                metadata = $random; 
            end
        end
        repeat(50) begin 
            @(posedge clk); 
            window_valid = 1; 
            stream_ready = 1; 
            if (window_valid && window_ready) begin 
                window = {50{$random}}; 
                metadata = $random; 
            end
        end

        $stop; 
    end


endmodule

