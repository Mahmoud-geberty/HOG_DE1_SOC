// Recieve the stream and wraps it with proper signals 
// for the Avalon to External Bus Bridge. 

module ext_bus #(
    parameter DATA_WIDTH = 128, 
    parameter ADDR_WIDTH = 5,
    parameter DATA_BYTES = DATA_WIDTH/8 
) (
    input                   clk, rst, 
    input [DATA_WIDTH-1:0]  stream, 
    input                   stream_valid, 
    output                  stream_ready,
    // external bus interface
    input [ADDR_WIDTH-1:0]  addr, 
    input                   bus_enable, 
    input                   r_wbar,      // read when high and write when low
    input [DATA_WIDTH-1:0]  write_data,  // unused for now, just acknowledge the write op
    output                  ack, 
    output [DATA_WIDTH-1:0] read_data, 
    input [DATA_BYTES-1:0]  byte_enable, // ignored 
    output                  irq          // unused
);

localparam S_WAIT = 0; 
localparam S_READ = 1; 
localparam S_WRITE = 2; 

reg [1:0] current_state, next_state; 

// state machine transitions
always @(*) begin 
    next_state = current_state; // default next_state

    case (current_state)
        S_WAIT: begin 
            if (bus_enable && r_wbar && stream_valid) begin 
                next_state = S_READ; 
            end
            else if (bus_enable && !r_wbar) begin 
                next_state = S_WRITE; 
            end
        end
        S_READ: begin 
            // output the data and acknowledge
            next_state = S_WAIT;
        end
        S_WRITE: begin 
            // acknowledge and go back to S_WAIT
            next_state = S_WAIT; 
        end
        default: next_state = S_WAIT; 
    endcase
end

// state register 
always @(posedge clk, posedge rst) begin 
    if (rst) begin 
        current_state <= S_WAIT; 
    end
    else begin 
        // decided to keep the register fixed for faster operation. 
        current_state <= S_WAIT; 
    end
end

// output logic 
assign stream_ready = (current_state == S_WAIT && next_state == S_READ);
assign read_data    = (stream_ready)? stream: 'd0; 
assign ack          = stream_ready || (current_state == S_WAIT && next_state == S_WRITE); 
assign irq          = 'd0; 

endmodule