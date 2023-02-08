module controller#(
    parameter integer LENGTH = 16
)(
    input  [1:0] branchFunc,
    input  [1:0] functionCode,
    input  [3:0] NZCV,
    input  [4:0] opcode,
    // control signal
    output reg [1:0] pcSel,             // PC sel 
    output reg outR,                    // out register
    output reg hlt,                     // done Register
    output reg regWrite,                // register file
    output reg writeMem,                // data memory
    output reg jal,                     // jal : Rd <- PC
    output reg mem2Reg,                 // memory out Mux
    output reg aluSrcB,                 // ALU input select Mux
    output reg [2:0] aluOpcode
);

// ALU operation select MUX
localparam LHI = 3'd0;
localparam LLI = 3'd1;
localparam ADD = 3'd2;
localparam ADC = 3'd3;
localparam SUB = 3'd4;
localparam SBB = 3'd5;
localparam MOV = 3'd6;
// PC select MUX
localparam PC_PLUS   = 2'd0;
localparam PC_BRANCH = 2'd1;
localparam PC_LABEL  = 2'd2;
localparam PC_RM     = 2'd3;

always @(*) begin
    aluSrcB  = 1'b0;
    regWrite = 1'b0;
    writeMem = 1'b0;
    mem2Reg  = 1'b0;
    jal   = 1'b0;
    outR  = 1'b0;
    hlt   = 1'b0;
    pcSel = 2'd0;
    aluOpcode = 3'd0;
    case(opcode)
        5'b00001: begin // LHI
            aluSrcB   = 1'b1;
            regWrite  = 1'b1;
            aluOpcode = LHI;
        end
        5'b00010: begin // LLI
            aluSrcB   = 1'b1;
            regWrite  = 1'b1;
            aluOpcode = LLI;
        end
        5'b00011: begin // LDR
            aluSrcB   = 1'b1;
            regWrite  = 1'b1;
            mem2Reg   = 1'b1;
            aluOpcode = ADD;
        end
        5'b00101: begin // STR
            aluSrcB   = 1'b1;
            writeMem  = 1'b1;
            aluOpcode = ADD;
        end
        5'b00000: begin // arithmetic
            case(functionCode)
                2'd0: begin // ADD
                    regWrite = 1'b1;
                    aluOpcode = ADD;
                end
                2'd1: begin // ADC
                    regWrite = 1'b1;
                    aluOpcode = ADC;
                end
                2'd2: begin // SUB
                    regWrite = 1'b1;
                    aluOpcode = SUB;
                end
                2'd3: begin // SBB
                    regWrite = 1'b1;
                    aluOpcode = SBB;
                end
            endcase
        end
        5'b00110: begin // CMP
            aluOpcode = SUB;
        end
        5'b00111: begin // ADDI
            aluSrcB   = 1'b1;
            regWrite  = 1'b1;
            aluOpcode = ADD;
        end
        5'b01000: begin // SUBI
            aluSrcB   = 1'b1;
            regWrite  = 1'b1;
            aluOpcode = SUB;
        end
        5'b01011: begin // MOV
            regWrite  = 1'b1;
            aluOpcode = MOV;
        end
        5'b11000: begin // conditional branch
            aluSrcB  = 1'b1;
            case(branchFunc)
                2'b11: begin  // BCC
                    pcSel = (NZCV[1]) ? PC_PLUS : PC_BRANCH;
                end
                2'b10: begin  // BCS
                    pcSel = (NZCV[1]) ? PC_BRANCH : PC_PLUS;
                end
                2'b01: begin  // BNE
                    pcSel = (NZCV[2]) ? PC_PLUS : PC_BRANCH;
                end
                2'b00: begin  // BEQ
                    pcSel = (NZCV[2]) ? PC_BRANCH : PC_PLUS;
                end
            endcase
        end
        5'b11001: begin // B[AL]
            aluSrcB  = 1'b1;
            pcSel = PC_BRANCH;
        end
        5'b10000: begin // JMP
            pcSel = PC_LABEL;
        end
        5'b10001: begin // JAL label
            jal = 1'b1;
            regWrite = 1'b1;
            aluSrcB  = 1'b1;
            pcSel = PC_BRANCH;
        end
        5'b10010: begin // JAL Rd Rm
            jal = 1'b1;
            regWrite = 1'b1;
            pcSel = PC_RM;
        end
        5'b10011: begin // JR Rd
            pcSel = PC_RM;
        end
        5'b11100: begin
            if(functionCode == 2'b00) begin // OutR
                outR = 1'b1;
            end else begin                  // HLT
                hlt = 1'b1;
            end
        end
    endcase 
end

endmodule
