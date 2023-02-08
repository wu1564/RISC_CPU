module RISC_complete(
    input  clk,
    input  reset_n, 
    input  cpu_reset_n,
    input  ext_IR_we,
    input  ext_DM_we,
    input  test_normal,     // test_normal : 0 -> normal, 1 -> testbench
    // memory 
    input  [15:0] ext_data,
    input  [ 7:0] ext_addr,
    output [15:0] mem_out, 
    output [15:0] outR,
    output done
);

//--------------------------------------------------------------------------------------------------------------//
//                                                                                                              //
//      ----------------------------------    Parameter BLOCK    -----------------------------------------      //
//                                                                                                              //
//--------------------------------------------------------------------------------------------------------------//
localparam integer LENGTH     = 16;
// Instruction Regiser
localparam integer IR_DEPTH   = 32;
// Instruction Decoder
localparam integer IMM_LENGTH = 11;
localparam integer OP_LENGTH  =  5;
// Register File
localparam integer REG_FILE_DEPTH = 8;
// Data Memory
localparam integer DATA_MEM_DEPTH = 256;    // fixed

//--------------------------------------------------------------------------------------------------------------//
//                                                                                                              //
//      --------------------------------  Wire & Reg Decleration BLOCK   --------------------------------       //
//                                                                                                              //
//--------------------------------------------------------------------------------------------------------------//

//***************************************************************************************************************
// Top Level 
reg [15:0] outRegiser;
reg doneFlag;

//***************************************************************************************************************
// Program Counter
wire [LENGTH-1:0] pc_reg_out;

//***************************************************************************************************************
// Instruction Register
wire [LENGTH-1:0] instruction;

//***************************************************************************************************************
// Instruction Decoder
wire [2:0] dataAddr0, dataAddr1, Rd;
// control signal
wire [1:0] functionCode;
wire [1:0] branchFunc;
wire [OP_LENGTH-1:0]  opcode;
// generater
wire [IMM_LENGTH-1:0] immediate;

//***************************************************************************************************************
// Register File
wire [LENGTH-1:0] writeRegData, readData0, readData1;
// control Signal
wire writeReg;

//***************************************************************************************************************
// Immediate Generater
wire [LENGTH-1:0] immediate_o;

//***************************************************************************************************************
// ALU
wire [LENGTH-1:0] alu_in0, alu_in1, alu_out;
// control signal
wire [2:0] aluOpcode;
wire [3:0] NZCV;

//***************************************************************************************************************
// Data Memory
wire [LENGTH-1:0] writeMemData, mem_data_out;
// control signal
wire writeMem;

//***************************************************************************************************************
// Contorller
wire [1:0] pcSel;
wire outR_signal;
wire hlt;
wire jal;
wire mem2Reg;
wire aluSrcB;

//***************************************************************************************************************
// PC Select Mux
wire [LENGTH-1:0] pc_branch;
wire [LENGTH-1:0] pc_plus;      // PC + 1 Adder
wire [LENGTH-1:0] pc_concate;   // JMP : pc[10:0] <= label 11 bits 
wire [LENGTH-1:0] pc_rd;        // JR 
// output 
wire [LENGTH-1:0] pc_sel_mux_out;
wire [LENGTH-1:0] pc_next;

//***************************************************************************************************************
// mux seletion wires
wire [LENGTH-1:0] outR_sel_out;
wire [LENGTH-1:0] alu_mem_mux_out;
wire [LENGTH-1:0] pc_hlt_sel_out;

//--------------------------------------------------------------------------------------------------------------//
//                                                                                                              //
//      -----------------------------------------  Module BLOCK   ----------------------------------------      //
//                                                                                                              //
//--------------------------------------------------------------------------------------------------------------//
// Program Counter
programCounter #(
    .LENGTH(LENGTH)
)PC(
    .clk(clk),
    .reset_n(cpu_reset_n),
    .pc_sel_in(pc_next),
    .pc_out(pc_reg_out)
);

// Instruction Register/Memory
instructionRegister #(
    .LENGTH(LENGTH),
    .IR_DEPTH(IR_DEPTH)
)IR(
    .clk(clk),
    .reset_n(reset_n),
    .pc(pc_reg_out),
    .instruction(instruction),
    // for testbench
    .ext_we(ext_IR_we),
    .test_normal(test_normal),
    .ext_data(ext_data),
    .ext_addr(ext_addr[4:0])
);

// insturction Decoder
instr_decoder #(
    .LENGTH(LENGTH),
    .IMM_LENGTH(IMM_LENGTH),
    .OP_LENGTH(OP_LENGTH)
)instr_decode(
    .instruction(instruction),
    .dataAddr0(dataAddr0),
    .dataAddr1(dataAddr1),
    .Rd(Rd),
    .immediate(immediate),
    .opcode(opcode),
    .functionCode(functionCode),
    .branchFunc(branchFunc)
);

// Regiser File
registerFile #(
    .LENGTH(LENGTH),
    .REG_FILE_DEPTH(REG_FILE_DEPTH)
)RF(
    .clk(clk),
    .reset_n(reset_n),
    // read
    .dataAddr0(dataAddr0),
    .dataAddr1(dataAddr1),
    .Rd(Rd),
    // write
    .writeReg(writeReg), // control signal from controller
    .writeData(writeRegData),
    // output
    .readData0(readData0),
    .readData1(readData1)
);

// Immediate Generater
imm_generate #(
    .LENGTH(LENGTH)
)IMM_GEN(
    .immediate_i(immediate),
    .immediate_o(immediate_o)
);

// ALU
ALU #(
    .LENGTH(LENGTH)
)ALU_INST(
    .clk(clk),
    .reset_n(reset_n),
    .aluOpcode(aluOpcode),
    .data0(alu_in0),
    .data1(alu_in1),
    .alu_o(alu_out),
    .NZCV(NZCV)
);

// Data Memory
dataMemory #(    // 256x16 -> 2^8 x 2^4
    .LENGTH(LENGTH),
    .DATA_MEM_DEPTH(DATA_MEM_DEPTH)
)DM(
    .clk(clk),
    .reset_n(reset_n),
    // Testbench
    .test_normal(test_normal),
    .ext_DM_we(ext_DM_we),
    .ext_data(ext_data),
    .ext_addr(ext_addr),
    //
    .writeMem(writeMem),
    .writeData(writeMemData),
    .dataAddr(alu_out[log2(DATA_MEM_DEPTH)-1:0]),
    .mem_data_out(mem_data_out)
);

// Controller
controller#(
    .LENGTH(LENGTH)
)CONTROLLER(
    .branchFunc(branchFunc),
    .functionCode(functionCode),
    .NZCV(NZCV),
    .opcode(opcode),
    // control signal
    .pcSel(pcSel),              // PC sel 
    .outR(outR_signal),         // out register
    .hlt(hlt),                  // done Register
    .regWrite(writeReg),        // register file
    .writeMem(writeMem),        // data memory
    .jal(jal),                  // jal : Rd <- PC
    .mem2Reg(mem2Reg),          // memory out Mux
    .aluSrcB(aluSrcB),          // ALU input select Mux
    .aluOpcode(aluOpcode)
);

//***************************************************************************************************************
// PC SELECT MUX FOR SELECTING THE NEXT PC 
//***************************************************************************************************************
// pc select mux
assign pc_next = (test_normal) ? {LENGTH{1'b0}} : pc_hlt_sel_out;     // if the testbecnch is giving data to the instruction memory, the pc shouldn't jump to the next instruction.

mux_2_to_1 #(
    .LENGTH(LENGTH)
)pc_hlt_sel_mux(
    .in_0(pc_sel_mux_out),
    .in_1(pc_reg_out),
    .sel(hlt),
    .out(pc_hlt_sel_out)
);

mux_4_to_1 #(
    .LENGTH(LENGTH)
)pc_sel_mux(
    .in_0(pc_plus),
    .in_1(pc_branch),
    .in_2(pc_concate),
    .in_3(pc_rd),
    .sel(pcSel),
    .out(pc_sel_mux_out)
);

// pc + immediate for Branch
adder #(
    .LENGTH(LENGTH)
)pc_add_imm(
    .add_in0(pc_reg_out),
    .add_in1(immediate_o),
    .add_out(pc_branch)
);

// pc + 1 for the next insturction
adder #(
    .LENGTH(LENGTH)
)pc_add_one(
    .add_in0(pc_reg_out),
    .add_in1(16'd1),
    .add_out(pc_plus)
);

// JMP : pc[10:0] <= label 11 bits 
assign pc_concate = {pc_reg_out[15:11],immediate};

// JR
assign pc_rd = readData0;

//***************************************************************************************************************
// OUT Register Select Mux
//***************************************************************************************************************
mux_2_to_1 #(
    .LENGTH(LENGTH)
)outR_sel_mux(
    .in_0(outRegiser),
    .in_1(readData0),
    .sel(outR_signal),
    .out(outR_sel_out)
);

//***************************************************************************************************************
// ALU / MEMORY SELECT MUX
//***************************************************************************************************************
mux_2_to_1 #(
    .LENGTH(LENGTH)
)alu_mem_mux(
    .in_0(alu_out),
    .in_1(mem_data_out),
    .sel(mem2Reg),
    .out(alu_mem_mux_out)
);

//***************************************************************************************************************
// Rd / PC SELECT MUX
//***************************************************************************************************************
mux_2_to_1 #(
    .LENGTH(LENGTH)
)rd_pc_mux(
    .in_0(alu_mem_mux_out),
    .in_1(pc_reg_out),
    .sel(jal),
    .out(writeRegData)
);

//***************************************************************************************************************
// ALU SOURCE B SELECT MUX
//***************************************************************************************************************
mux_2_to_1 #(
    .LENGTH(LENGTH)
)alu_source_sel_mux(
    .in_0(readData1),
    .in_1(immediate_o),
    .sel(aluSrcB),
    .out(alu_in1)
);

//--------------------------------------------------------------------------------------------------------------//
//                                                                                                              //
//      -------------------------------------- Top Level Logic BLOCK   -----------------------------------      //
//                                                                                                              //
//--------------------------------------------------------------------------------------------------------------//
assign writeMemData = readData1;
assign mem_out = mem_data_out;
assign alu_in0 = readData0;
// output signals
assign done = doneFlag;
assign outR = outRegiser;

always @(posedge clk or negedge cpu_reset_n) begin
    if(!cpu_reset_n) begin
        doneFlag <= 1'b0;
    end else begin
        doneFlag <= hlt;
    end
end

always @(posedge clk or negedge cpu_reset_n) begin
    if(!cpu_reset_n) begin
        outRegiser <= 16'd0; 
    end else begin
        outRegiser <= outR_sel_out;
    end
end

//--------------------------------------------------------------------------------------------------------------//
//                                                                                                              //
//      ---------------------------------------    Function BLOCK   --------------------------------------      //
//                                                                                                              //
//--------------------------------------------------------------------------------------------------------------//
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
