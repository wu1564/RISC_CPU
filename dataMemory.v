module dataMemory #(    // 256x16
    parameter integer LENGTH         = 16,
    parameter integer DATA_MEM_DEPTH = 256
)(
    input  clk,
    input  reset_n,
    // Testbench
    input  test_normal,
    input  ext_DM_we,
    input  [LENGTH-1:0] ext_data,
    input  [log2(DATA_MEM_DEPTH)-1:0] ext_addr,
    //
    input  writeMem,
    input  [LENGTH-1:0] writeData,
    input  [log2(DATA_MEM_DEPTH)-1:0] dataAddr,
    output [LENGTH-1:0] mem_data_out
);

integer i;
reg [LENGTH-1:0] memory[0:DATA_MEM_DEPTH-1];

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        for(i = 0; i < DATA_MEM_DEPTH; i = i + 1) begin
            memory[i] <= {LENGTH{1'b0}};
        end
    end else begin
        if(writeMem) begin
            memory[dataAddr] <= writeData;
        end else if(test_normal && ext_DM_we) begin
            memory[ext_addr] <= ext_data;
        end
    end
end

assign mem_data_out = (~writeMem) ? memory[dataAddr] : {LENGTH{1'b0}};

// log2
function integer log2;
input integer value;
begin
    value = value - 1;
    for(log2 = 0; value > 0; log2 = log2 + 1) begin
        value = value >> 1;
    end  
end  
endfunction

endmodule
