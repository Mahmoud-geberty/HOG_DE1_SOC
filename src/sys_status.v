/*
    -> blinks an LED to indicate design is uploaded successfully.
    -> connects to PIOs on the lw-bridge with some status signals like...
        -> one PIO to send the input valid-ready handshake to the hog core
        -> one PIO to send the valid-ready output handshake the hog core
        -> one PIO to send the bus-switch output handshakes
        -> one PIO to send the input pixels
*/

module sys_status #(
    parameter CLOCK_FREQ = 50_000_000,
    parameter LEVELS = 7 
) (
    input clk, rst, 
    output blinking_led,
    input hog_input_valid, hog_input_ready, 
    input [LEVELS-1:0] hog_out_valid, hog_out_ready, 
    input switch_out_valid, switch_out_ready,
    input [7:0] input_pixels,
    output [31:0] hog_in_pio, hog_out_pio, switch_out_pio, input_pixels_pio
); 

localparam BLINK_FREQ         = 1; // on and off in 1s
localparam CLOCK_PERIOD       = 1/CLOCK_FREQ; 
localparam BLINK_COUNTER_MAX  = CLOCK_PERIOD / BLINK_FREQ; 
localparam BLINK_COUNTER_SIZE = $clog2(BLINK_COUNTER_MAX); 

reg [BLINK_COUNTER_SIZE-1:0] blink_counter;

assign blinking_led     = blink_counter[BLINK_COUNTER_SIZE-1]; 
assign hog_in_pio       = {{30{1'b0}}, hog_input_valid, hog_input_ready}; 
assign hog_out_pio      = {{(32 - LEVELS*2){1'b0}}, hog_out_valid, hog_out_ready}; 
assign switch_out_pio   = {{30{1'b0}}, switch_out_valid, switch_out_ready}; 
assign input_pixels_pio = {{24{1'b0}}, input_pixels}; 

always @(posedge clk, posedge rst) begin 
    if (rst) begin 
    end
    else if (blink_counter == BLINK_COUNTER_MAX-1) begin 
        blink_counter <= 'd0;
    end
    else begin 
        blink_counter <= blink_counter + 'd1;
    end
end

endmodule