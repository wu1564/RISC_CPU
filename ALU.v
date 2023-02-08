module ALU #(
    parameter integer LENGTH = 16
)(
    input  clk,
    input  reset_n,
    input  [2:0] aluOpcode,
    input  [LENGTH-1:0] data0,
    input  [LENGTH-1:0] data1,
    output [LENGTH-1:0] alu_o,
    output reg [3:0] NZCV
);

localparam LHI = 3'd0;
localparam LLI = 3'd1;
localparam ADD = 3'd2;
localparam ADC = 3'd3;
localparam SUB = 3'd4;
localparam SBB = 3'd5;
localparam MOV = 3'd6;

wire [LENGTH-1:0] data1_neg = ~data1 + 'b1;
reg  [LENGTH:0]   result;

assign alu_o = result[0+:LENGTH];

always @(*) begin
    case (aluOpcode)
        LHI: result = {1'b0,data1[7:0],data0[7:0]};
        LLI: result = {1'b0,8'd0,data1[7:0]};
        ADD: result = {{1{data0[LENGTH-1]}},data0}  + {{1{data1[LENGTH-1]}},data1};
        ADC: result = {{1{data0[LENGTH-1]}},data0}  + {{1{data1[LENGTH-1]}},data1} + {{LENGTH-1{1'b0}},NZCV[1]};
        SUB: result = {{1{data0[LENGTH-1]}},data0}  + {{1{data1_neg[LENGTH-1]}},data1_neg};
        SBB: result = ({{1{data0[LENGTH-1]}},data0} + {{1{data1_neg[LENGTH-1]}},data1_neg}) + ({{LENGTH-1{1'b0}},NZCV[1]} + 16'd1);
        MOV: result = {{1{data0[LENGTH-1]}},data0};
        default: begin
            result = 17'd0;
        end
    endcase
end

// NZCV flags
// NZCV[0] -> V
// NZCV[1] -> C
// NZCV[2] -> Z
// NZCV[3] -> N
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        NZCV <= 4'd0;
    end else begin
        NZCV[0] <= (data0[LENGTH-1] ^ result[LENGTH-1]) & (data1[LENGTH-1] ^ result[LENGTH-1]);
        NZCV[1] <= result[LENGTH];
        NZCV[2] <= ~(|result);       // Zero
        NZCV[3] <= result[LENGTH-1]; // Negative
    end
end

endmodule
