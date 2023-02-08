module instr_decoder #(
    parameter integer LENGTH     = 16,
    parameter integer IMM_LENGTH = 11,
    parameter integer OP_LENGTH  =  5
)(
    input  [LENGTH-1:0] instruction,
    output reg [2:0] dataAddr0,
    output reg [2:0] dataAddr1,
    output reg [2:0] Rd,
    output reg [IMM_LENGTH-1:0] immediate,
    output [OP_LENGTH-1:0]  opcode,
    output [1:0] functionCode,
    output [1:0] branchFunc
);

assign opcode = instruction[15-:5];
assign functionCode = instruction[1:0];
assign branchFunc   = instruction[9:8];

always @(*) begin
    case(instruction[(LENGTH-1)-:5])
        5'b00001: begin // LHI
            dataAddr0 = instruction[10:8];
            dataAddr1 = 3'd0;
            Rd = instruction[10:8];
            immediate = {3'd0,instruction[0+:8]}; // unsigned
        end
        5'b00010: begin // LLI
            dataAddr0 = 3'd0;
            dataAddr1 = 3'd0;
            Rd = instruction[10:8];
            immediate = {3'd0,instruction[0+:8]}; // unsigned
        end
        5'b00011: begin // LDR
            dataAddr0 = instruction[7:5];
            dataAddr1 = 3'd0;
            Rd = instruction[10:8];
            immediate = {6'd0,instruction[0+:5]}; // unsigned
        end
        5'b00101: begin // STR
            dataAddr0 = instruction[7:5];
            dataAddr1 = instruction[10:8];
            Rd = instruction[10:8];
            immediate = {6'd0,instruction[0+:5]}; // unsigned
        end
        5'b00000,       // arithmetic +/-
        5'b00110: begin // CMP
            dataAddr0 = instruction[7:5];
            dataAddr1 = instruction[4:2];
            Rd = instruction[10:8];
            immediate = 11'd0;
        end
        5'b00111: begin // ADDI
            dataAddr0 = instruction[7:5];
            dataAddr1 = 3'd0;
            Rd = instruction[10:8];
            immediate = {6'd0,instruction[0+:5]}; // unsigned
        end
        5'b01000: begin // SUBI
            dataAddr0 = instruction[7:5];
            dataAddr1 = 3'd0;
            Rd = instruction[10:8];
            immediate = {6'd0,instruction[0+:5]}; // unsigned
        end
        5'b01011: begin // MOV
            dataAddr0 = instruction[7:5];
            dataAddr1 = 3'd0;
            Rd = instruction[10:8];
            immediate = 11'd0;     
        end
        5'b11000,       // conditional branch
        5'b11001: begin // B[AL]
            dataAddr0 = 3'd0;
            dataAddr1 = 3'd0;
            Rd = 3'd0;
            immediate = {{3{instruction[7]}},instruction[0+:8]}; // signed
        end
        5'b10000: begin // JMP
            dataAddr0 = 3'd0;
            dataAddr1 = 3'd0;
            Rd = 3'd0;
            immediate = instruction[0+:11]; // signed
        end
        5'b10001: begin // JAL label
            dataAddr0 = 3'd0;
            dataAddr1 = 3'd0;
            Rd = instruction[10:8];
            immediate = {{3{instruction[7]}},instruction[0+:8]}; // signed
        end
        5'b10010: begin // JAL Rd Rm
            dataAddr0 = 3'd0;
            dataAddr1 = 3'd0;
            Rd = instruction[10:8];
            immediate = 11'd0;        
        end
        5'b10011: begin // JR Rd
            dataAddr0 = 3'd0;
            dataAddr1 = 3'd0;
            Rd = 3'd0;
            immediate = 11'd0;
        end
        5'b11100: begin
            if(instruction[0+:2] == 2'b00) begin // OutR
                dataAddr0 = instruction[7:5];
                dataAddr1 = 3'd0;
                Rd = 3'd0;
                immediate = 11'd0;
            end else begin                       // HLT
                dataAddr0 = 3'd0;
                dataAddr1 = 3'd0;
                Rd = 3'd0;
                immediate = 11'd0;
            end
        end
        default: begin
            dataAddr0 = 3'd0;
            dataAddr1 = 3'd0;
            Rd = 3'd0;
            immediate = 11'd0;
        end
    endcase 
end

endmodule
