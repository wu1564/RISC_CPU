module registerFile #(
    parameter integer LENGTH          = 16,
    parameter integer REG_FILE_DEPTH  = 8
)(
    input clk,
    input reset_n,
    input [2:0] dataAddr0,
    input [2:0] dataAddr1,
    input [2:0] Rd,
    // write
    input  writeReg, // control signal from controller
    input  [LENGTH-1:0] writeData,
    output [LENGTH-1:0] readData0,
    output [LENGTH-1:0] readData1
);

integer i;
reg [LENGTH-1:0] register[0:REG_FILE_DEPTH-1];

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        for(i = 0; i < REG_FILE_DEPTH; i = i + 1) begin
            register[i] <= {LENGTH{1'b0}};
        end
    end else begin
        if(writeReg) begin
            register[Rd] <= writeData;
        end
    end 
end

assign readData0 = register[dataAddr0];
assign readData1 = register[dataAddr1];

endmodule
