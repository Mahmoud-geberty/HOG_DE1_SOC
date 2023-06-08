// an arbitrator connecting many serializers to one avalon bus bridge
module bus_switch #(
    parameter BUS_WIDTH = 128,
    parameter LEVELS = 7,  
    parameter INPUT_WIDTH = BUS_WIDTH * LEVELS
) (
    input                   clk, rst, 
    input [LEVELS-1:0]      in_valid, 
    input                   out_ready,
    input [INPUT_WIDTH-1:0] in_stream,
    output                  out_valid, 
    output [LEVELS-1:0]     in_ready, 
    output [BUS_WIDTH-1:0]  out_stream 
); 

localparam SEEK_COUNTER_MAX = LEVELS-1; 
localparam SEEK_COUNTER_WIDTH = $clog2(SEEK_COUNTER_MAX); 
localparam GRANT_COUNTER_MAX = 9; 
localparam GRANT_COUNTER_WIDTH = $clog2(GRANT_COUNTER_MAX); 

localparam S_SEEK = 0; 
localparam S_GRANT = 1; 

reg current_state, next_state; 

reg request_mux; 
reg [LEVELS-1:0] grant_demux; 

reg [BUS_WIDTH-1:0] out_stream_buf; 

reg [SEEK_COUNTER_WIDTH-1:0] seek_count; 
reg [GRANT_COUNTER_WIDTH-1:0] grant_count; 

// output logic 
assign out_valid =  !(next_state == S_SEEK); 
assign in_ready  =  !(next_state == S_SEEK)? grant_demux & {LEVELS{out_ready}}  : 'd0; 
assign out_stream = !(next_state == S_SEEK)? out_stream_buf : 'd0;

always @(*) begin 
    request_mux = 0; 

    // need to manually change if LEVELS changes T_T
    case (seek_count) 
        'd0: request_mux = in_valid[0];  
        'd1: request_mux = in_valid[1]; 
        'd2: request_mux = in_valid[2]; 
        'd3: request_mux = in_valid[3]; 
        'd4: request_mux = in_valid[4]; 
        'd5: request_mux = in_valid[5]; 
        'd6: request_mux = in_valid[6]; 
        default: request_mux = 0; 
    endcase
end

always @(*) begin 
    grant_demux = 'd0; 
    out_stream_buf = 'd0; 

    case (seek_count) 
    'd0: begin 
        grant_demux[0] = 1'b1;
        out_stream_buf = in_stream[0*BUS_WIDTH +: BUS_WIDTH]; 
    end
    'd1: begin 
        grant_demux[1] = 1'b1;
        out_stream_buf = in_stream[1*BUS_WIDTH +: BUS_WIDTH]; 
    end
    'd2: begin 
        grant_demux[2] = 1'b1;
        out_stream_buf = in_stream[2*BUS_WIDTH +: BUS_WIDTH]; 
    end
    'd3: begin 
        grant_demux[3] = 1'b1;
        out_stream_buf = in_stream[3*BUS_WIDTH +: BUS_WIDTH]; 
    end
    'd4: begin 
        grant_demux[4] = 1'b1;
        out_stream_buf = in_stream[4*BUS_WIDTH +: BUS_WIDTH]; 
    end
    'd5: begin 
        grant_demux[5] = 1'b1;
        out_stream_buf = in_stream[5*BUS_WIDTH +: BUS_WIDTH]; 
    end
    'd6: begin 
        grant_demux[6] = 1'b1;
        out_stream_buf = in_stream[6*BUS_WIDTH +: BUS_WIDTH]; 
    end
    default: begin 
        grant_demux = 'd0; 
        out_stream_buf = 'd0; 
    end
    endcase
end

always @(posedge clk, posedge rst) begin 
    if (rst) begin 
        seek_count <= 'd0; 
    end
    else if (seek_count == SEEK_COUNTER_MAX) begin 
        seek_count <= 'd0; 
    end
    else if (next_state == S_SEEK) begin 
        seek_count <= seek_count + 'd1; 
    end
end

always @(posedge clk, posedge rst) begin 
    if (rst) begin 
        grant_count <= 0; 
    end
    else if (current_state == S_GRANT && next_state == S_SEEK) begin 
        grant_count <= 0; 
    end
    else if (current_state == S_GRANT) begin 
        grant_count <= grant_count + 'd1; 
    end
end

always @(*) begin 
    next_state = current_state; // default 

    case (current_state) 
        S_SEEK: begin 
            if (request_mux) begin 
                next_state = S_GRANT; 
            end
        end
        S_GRANT: begin 
            if (grant_count == GRANT_COUNTER_MAX-1 || !request_mux) begin 
                next_state = S_SEEK;
            end
        end
    endcase
end

always @(posedge clk, posedge rst) begin 
    if (rst) begin 
        current_state <= S_SEEK; 
    end
    else begin 
        current_state <= next_state; 
    end
end

endmodule 