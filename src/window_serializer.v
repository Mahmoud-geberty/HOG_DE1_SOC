module window_serializer #(
    parameter WINDOW_WIDTH = 1152, 
    parameter BUS_WIDTH = 128, 
    parameter META_WIDTH = 4 // for now only contains the pyramid level
) (
    input                      clk, rst, 
    input                      window_valid, 
    input                      stream_ready, 
    input [META_WIDTH-1:0]     metadata,
    input [WINDOW_WIDTH-1:0]   window, 
    output                     window_ready, 
    output                     stream_valid, 
    output reg [BUS_WIDTH-1:0] stream
); 

// the portion of the output dedicated for the window itself
localparam STREAM_DATA_PORTION = BUS_WIDTH - META_WIDTH; 
// the last serial output will have about 36 bits of data only
localparam STREAM_DATA_REMAIN  = WINDOW_WIDTH % STREAM_DATA_PORTION; 
localparam STREAM_EMPTY_PORTION = STREAM_DATA_PORTION - STREAM_DATA_REMAIN; 

// "+1" as long as there is a meta portion added to each serial output
localparam SERIAL_COUNTER_MAX = (WINDOW_WIDTH / STREAM_DATA_PORTION) + 1; 
localparam SERIAL_COUNTER_WIDTH = $clog2(SERIAL_COUNTER_MAX-1); 

wire [STREAM_DATA_REMAIN-1:0]  window_last_slice; 
reg [STREAM_DATA_PORTION-1:0] window_slice; 

// indicate active serialization state
reg window_registered; 

// indicate last serial output (to handle the size difference)
wire last_serial; 

// serial output counter 
reg [SERIAL_COUNTER_WIDTH-1:0] serial_cnt; 

reg [WINDOW_WIDTH-1:0] window_reg; 
reg [META_WIDTH-1:0] metadata_reg; 

// ready until one window is registered
assign window_ready = ~window_registered; 
assign stream_valid = window_registered; 

// serial output procedure
always @(*) begin 
    stream = 'd0; 
    if (stream_valid) begin 
        if (last_serial) begin 
            stream = {
                metadata_reg, 
                {STREAM_EMPTY_PORTION{1'b0}}, 
                window_last_slice
            }; 
        end
        else begin 
            stream = {
                metadata_reg, 
                window_slice
            }; 
        end
    end
end

assign last_serial = (serial_cnt == SERIAL_COUNTER_MAX - 1); 

// window slicing procedure 
// handle 10 slices only for now, meaning window width is always 1152
// and meta width is always 4
always @(*) begin 
    case (serial_cnt)
        'd0: window_slice = window_reg[0 +: STREAM_DATA_PORTION]; 
        'd1: window_slice = window_reg[1*STREAM_DATA_PORTION +: STREAM_DATA_PORTION]; 
        'd2: window_slice = window_reg[2*STREAM_DATA_PORTION +: STREAM_DATA_PORTION];
        'd3: window_slice = window_reg[3*STREAM_DATA_PORTION +: STREAM_DATA_PORTION];
        'd4: window_slice = window_reg[4*STREAM_DATA_PORTION +: STREAM_DATA_PORTION];
        'd5: window_slice = window_reg[5*STREAM_DATA_PORTION +: STREAM_DATA_PORTION];
        'd6: window_slice = window_reg[6*STREAM_DATA_PORTION +: STREAM_DATA_PORTION];
        'd7: window_slice = window_reg[7*STREAM_DATA_PORTION +: STREAM_DATA_PORTION];
        'd8: window_slice = window_reg[8*STREAM_DATA_PORTION +: STREAM_DATA_PORTION];
        default: window_slice = 'd0;  
    endcase
end

assign window_last_slice = 
    window_reg[(SERIAL_COUNTER_MAX-1)*STREAM_DATA_PORTION +: STREAM_DATA_REMAIN];

always @(posedge clk, posedge rst) begin 
    if (rst) begin 
        window_registered <= 0; 
    end
    // serialization complete
    else if (serial_cnt == SERIAL_COUNTER_MAX-1) begin 
        window_registered <= 0; 
    end
    else if (window_valid && window_ready) begin 
        window_registered <= 1; 
    end
end

always @(posedge clk, posedge rst) begin 
    if (rst) begin 
        window_reg <= 0; 
    end
    else if (window_valid && window_ready) begin 
        window_reg <= window; 
    end
end

always @(posedge clk, posedge rst) begin 
    if (rst) begin 
        metadata_reg <= 0; 
    end
    else if (window_valid && window_ready) begin 
        metadata_reg <= metadata; 
    end
end

// the serial output counter 
always @(posedge clk, posedge rst) begin 
    if (rst) begin 
        serial_cnt <= 0; 
    end
    else if (serial_cnt == SERIAL_COUNTER_MAX-1) begin 
        serial_cnt <= 0; 
    end
    else if (stream_valid && stream_ready) begin 
        serial_cnt <= serial_cnt + 1'd1; 
    end
end

endmodule 