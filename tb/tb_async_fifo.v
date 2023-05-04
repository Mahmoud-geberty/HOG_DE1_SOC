`timescale 1ns/1ns
module tb_async_fifo(); 
        parameter DSIZE = 8;
        parameter ASIZE = 3;
        parameter FALLTHROUGH = "TRUE"; // First word fall-through without latency

        reg               wclk;
        reg               wrst_n;
        reg               winc;
        reg   [DSIZE-1:0] wdata;
        wire              wfull;
        wire              awfull;
        reg               rclk;
        reg               rrst_n;
        reg               rinc;
        wire  [DSIZE-1:0] rdata;
        wire              rempty;
        wire              arempty;

async_fifo#(
    .DSIZE  ( DSIZE ),
    .ASIZE  ( ASIZE ),
    .FALLTHROUGH ( FALLTHROUGH )
)u_async_fifo(
    .wclk   ( wclk   ),
    .wrst_n ( wrst_n ),
    .winc   ( winc   ),
    .wdata  ( wdata  ),
    .wfull  ( wfull  ),
    .awfull ( awfull ),
    .rclk   ( rclk   ),
    .rrst_n ( rrst_n ),
    .rinc   ( rinc   ),
    .rdata  ( rdata  ),
    .rempty ( rempty ),
    .arempty  ( arempty  )
);

always #1 rclk = ~rclk; 
always #15 wclk = ~wclk; 

initial begin 
    rclk = 0; 
    wclk = 0; 
    rrst_n = 0; 
    wrst_n = 0; 
    winc = 0; 
    wdata = 0; 
    rinc = 0; 

    @(posedge wclk);
    wrst_n = 1; 
    winc = 1; 
    wdata = $random; 

    repeat (5) begin 
        wdata = $random; 
    end

    winc = 0; 
    repeat (2) begin 
        @(posedge rclk);
        rinc = 1; 
        rrst_n = 1;  
    end
    winc = 1; 
    
    repeat (10) begin 
        @(posedge wclk);
        wdata = $random; 
    end

    rinc = 0; 
    repeat (10) begin 
        @(posedge wclk);
        wdata = $random; 
    end
    
    $stop; 
end


endmodule