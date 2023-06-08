module sync_async_reset (
    input clk, rst_async, 
    output rst_sync
); 

// sync_async_reset u_sync_async_reset(
//     .clk       ( clk       ),
//     .rst_async ( rst_async ),
//     .rst_sync  ( rst_sync  )
// );


reg sync_reg0, sync_reg1; 

assign rst_sync = sync_reg1; 

always @(posedge clk, posedge rst_async) begin 
    if (rst_async) begin 
        sync_reg0 <= 1'b1; 
        sync_reg1 <= 1'b1; 
    end
    else begin 
        sync_reg0 <= 1'b0; 
        sync_reg1 <= sync_reg0; 
    end
end

endmodule 