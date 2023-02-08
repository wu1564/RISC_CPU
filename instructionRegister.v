module instructionRegister #(
    parameter integer LENGTH   = 16,
    parameter integer IR_DEPTH = 32
)(
    input  clk,
    input  reset_n,
    input  [log2(IR_DEPTH)-1:0] pc,
    output [LENGTH-1:0] instruction,
    // for testbench
    input  ext_we,
    input  test_normal,
    input  [LENGTH-1:0] ext_data,
    input  [log2(IR_DEPTH)-1:0] ext_addr
);

integer i;

// memory
reg [LENGTH-1:0] memory [0:IR_DEPTH-1];

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        for(i = 0; i < IR_DEPTH; i = i + 1) begin
            memory[i] <= {LENGTH{1'b0}};
        end
    end else if(test_normal & ext_we) begin
        memory[ext_addr] <= ext_data;
    end
end

// output signal
assign instruction = memory[pc];

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
