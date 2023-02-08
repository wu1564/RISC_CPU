`timescale 1ns / 1ps

//`define ADD_SUB_TEST
//`define ADD_TWO_NUM_AND_STORE
//`define ADD_TEN_NUMS_IN_MEM
//`define FIND_MINUMUN_MAXIMUM_IN_MEM
`define MOV_N_MEM_BLOCK

module RISC_complete_tb();

parameter clk_period = 50;
parameter delay_factor = 2;

// Inputs
integer i;
reg clk;
reg ext_DM_we;
reg test_normal;
reg cpu_reset_n;
reg reset_n;
reg [15:0] ext_data;
reg [7:0] ext_addr;
reg ext_IR_we;

// Output
wire [15:0] mem_out;
wire done;
wire [15:0] outR;

// Instantiate the UUT
RISC_complete UUT (
    .mem_out(mem_out), 
    .clk(clk), 
    .ext_DM_we(ext_DM_we), 
    .test_normal(test_normal), 
    .reset_n(reset_n), 
    .done(done), 
    .outR(outR), 
    .ext_data(ext_data), 
    .ext_addr(ext_addr), 
    .ext_IR_we(ext_IR_we),
    .cpu_reset_n(cpu_reset_n)
);

// generate the clock signal
always begin
    #(clk_period/ 2) clk <= 1'b0;
    #(clk_period/ 2) clk <= 1'b1;
end

initial begin
	cpu_reset_n = 1'b1;
    reset_n = 1'b1;
    test_normal = 1'b1;
	ext_DM_we = 1'b0;
	ext_IR_we = 1'b0;
	ext_data = 0;
	ext_addr = 0;
    repeat(9) begin@(posedge clk)
        #(clk_period/delay_factor) reset_n <= 1'b0;
        test_normal = 1'b1;
    end
    reset_n <='b1;
// Test Start
`ifdef ADD_SUB_TEST
    write_instruction(16'h0, 16'b0001_0000_0010_0101); // LLI R0,#25
    write_instruction(16'h1, 16'b0000_1000_0110_0011); // LHI R0,#63
    write_instruction(16'h2, 16'b1110_0000_0000_0000); // OUT R0 (6325H)
    write_instruction(16'h3, 16'b0001_1001_0000_0000); // LDR R1,R0,#0  Mem[R0+0] -> R1
    write_instruction(16'h4, 16'b0001_1010_0000_0001); // LDR R2,R0,#1  Mem[R0+1] -> R2
    write_instruction(16'h5, 16'b1110_0000_0010_0000); // OUT R1 (47H)
    write_instruction(16'h6, 16'b1110_0000_0100_0000); // OUT R2 (89H)
    write_instruction(16'h7, 16'b0000_0011_0010_1000); // ADD R3,R1,R2
    write_instruction(16'h8, 16'b1110_0000_0110_0000); // OUT R3 (D0H)
    write_instruction(16'h9, 16'b0000_0011_0010_1010); // SUB R3,R1,R2
    write_instruction(16'hA, 16'b1110_0000_0110_0000); // OUT R3 (FFBEH)
    write_instruction(16'hB, 16'b1110_0000_0000_0001); // HLT
	#1 ext_IR_we = 1'b0;
    writeDataMem(16'h25,16'h47) ; // data (25h, 47h)
    writeDataMem(16'h26,16'h89) ; // data (26h, 89h)
	#1 ext_DM_we = 1'b0;

`elsif FIND_MINUMUN_MAXIMUM_IN_MEM  // 1. Find the minimum and maximum from two numbers in memory
//************************************************************************************************
// Implementation
//------------------------------------------------------------------------------------------------
// int a = mem[0];
// int b = mem[1];
// if(a > b) begin
//   $display("%3d", b);
//   $display("%3d", a);
// end else begin
//   $display("%3d", a);
//   $display("%3d", b);
// end
//************************************************************************************************
    writeDataMem(16'h0, 16'd210);
    writeDataMem(16'h1, 16'd999);
	#1 ext_DM_we = 1'b0;
    write_instruction(16'h0, {5'b00011, 3'd0, 3'd0, 5'd0});          // LDR R0, R0, #0             Mem[0]  => R0(16'd210)
    write_instruction(16'h1, {5'b00011, 3'd1, 3'd1, 5'd1});          // LDR R1, R1, #1             Mem[1]  => R0(16'd999)
	write_instruction(16'h2, {5'b00110, 3'd0, 3'd0, 3'd1, 2'd1});    // CMP R0, R1
    write_instruction(16'h3, {8'b11000010, 8'd4});                   // BCS SMALLER                if(sub carry == 1) {show R1 and R0;} else {show R0 and R1;}
    // LARGER
    write_instruction(16'h4, {5'b11100, 3'd0, 3'd1, 3'd0, 2'd0});    // OutR R1                    ouptut the smaller one => OutR(16'd210)
    write_instruction(16'h5, {5'b11100, 3'd0, 3'd0, 3'd0, 2'd0});    // OutR R0                    ouptut the larger  one => OutR(16'd999)
    write_instruction(16'h6, {5'b11100, 9'd0, 2'd1});                // HLT
    // SMALLER
    write_instruction(16'h7, {5'b11100, 3'd0, 3'd0, 3'd0, 2'd0});    // OutR R0                    ouptut the smaller one => OutR(16'd210)
    write_instruction(16'h8, {5'b11100, 3'd0, 3'd1, 3'd0, 2'd0});    // OutR R1                    ouptut the larger  one => OutR(16'd999)
    write_instruction(16'h9, {5'b11100, 9'd0, 2'd1});                // HLT

`elsif ADD_TWO_NUM_AND_STORE // 2. Add two numbers in memory and store the result in another memory location.
//************************************************************************************************
// Implementation
//------------------------------------------------------------------------------------------------
// int a = mem[0];
// int b = mem[1];
// int c = a + b;
// int d = 0;
// $display("%d", c);
// mem[d+9] = c;
// b = mem[d+9];
// $display("%d", b);
//************************************************************************************************
    writeDataMem(16'h0, 16'd210);
    writeDataMem(16'h1, 16'd999);
	#1 ext_DM_we = 1'b0;
    write_instruction(16'h0, {5'b00011, 3'd0, 3'd0, 5'd0});       // LDR  R0, R0, #0   Mem[0]  => R0(16'h8)
    write_instruction(16'h1, {5'b00011, 3'd1, 3'd1, 5'd1});       // LDR  R1, R1, #1   Mem[1]  => R1(16'h9)
    write_instruction(16'h2, {5'b00000, 3'd2, 3'd0, 3'd1, 2'd0}); // ADD  R2, R0, R1   R0 + R1 => R2(16'h11)
    write_instruction(16'h3, {5'b11100, 3'd0, 3'd2, 3'd0, 2'd0}); // OutR R2 (16'h11)
	write_instruction(16'h4, {5'b00101, 3'd2, 3'd3, 5'd9});       // STR  R2, R3, #9   R2  => Mem[9](16'h11)
	write_instruction(16'h5, {5'b00011, 3'd7, 3'd6, 5'd9});       // LDR  R1, R6, #9   Mem[9]  => R7(16'h11)
    write_instruction(16'h6, {5'b11100, 3'd0, 3'd7, 3'd0, 2'd0}); // OutR R7(16'h11)
	write_instruction(16'h7, {5'b11100, 9'd0, 2'd1});             // HLT

`elsif ADD_TEN_NUMS_IN_MEM // 3. Add ten numbers in consecutive memory locations
//************************************************************************************************
// Implementation
//------------------------------------------------------------------------------------------------
// for(i = 0; i < 10; ++i) begin
//     mem[i] = i + 5;
// end
//************************************************************************************************
	write_instruction(16'h0, 16'b00010_000_00000000);             // LLI R0,#0  R0 -> i
	write_instruction(16'h1, 16'b00010_001_00000101);             // LLI R1,#5  R1 -> base number + i
	write_instruction(16'h2, 16'b00010_011_00001010);             // LLI R3,#10 R3 -> i range
	// JUMP
	write_instruction(16'h3, {5'b00000, 3'd4, 3'd0, 3'd1, 2'd0}); // ADD  R4, R0, R1   R4 <= R1(5) + R0(i)
	write_instruction(16'h4, {5'b00101, 3'd4, 3'd0, 5'd0});       // STR  R4, R0, #0   R1 => Mem[i]
	write_instruction(16'h5, {5'b00011, 3'd5, 3'd0, 5'd0});       // LDR  R5, R0, #0   R5 <= Mem[i](5~14)
	write_instruction(16'h6, {5'b11100, 3'd0, 3'd5, 3'd0, 2'd0}); // OutR R5           R5 (5~14)
	write_instruction(16'h7, {5'b00111, 3'd0, 3'd0, 5'd1});       // ADDI R0, R0, #1   i = i + 1
	write_instruction(16'h8, {5'b00110, 3'd0, 3'd0, 3'd3, 2'd1}); // CMP  R0, R1       i != 10
	write_instruction(16'h9, {8'b11000010, 8'b11111010});         // BCS  JUMP(-6)
	write_instruction(16'ha, {5'b11100, 9'd0, 2'd1});             // HLT	 
	
`elsif MOV_N_MEM_BLOCK // 4. Mov a memory block of N words from one place to another
//************************************************************************************************
// Implementation
//------------------------------------------------------------------------------------------------
// int temp = 0; (R4)
// int new_index = 30;
// int index = 25;
// int i = 0;
//	for(i = 0; i < 2; ++i) begin
//   $display("%3d", index);
//   mem[i] = i + index;
//   index++;
// end
// for(i = 0; i < 2; ++i) begin
//     temp = mem[i];
//     mem[new_index] = temp;
//     int newTemp = mem[new_index];
//     $display("%3d", newTemp);
//     newTemp++;
// end
//************************************************************************************************
    write_instruction(16'd0, 16'b00010_000_00011001);              // LLI R0,#25  (index)
    write_instruction(16'd1, 16'b00010_001_00000000);              // LLI R1,#0   (i)
    write_instruction(16'd2, 16'b00010_010_00000011);              // LLI R2,#3   (range)
    write_instruction(16'd3, 16'b00010_101_00011110);              // LLI R5,#30  (new index)
// JUMP
    write_instruction(16'd4, {5'b11100, 3'd0, 3'd0, 3'd0, 2'd0});  // OutR R0  (25~27)
    write_instruction(16'd5, {5'b00101, 3'd0, 3'd1, 5'd0});        // STR  R0, R1, #0   25 ~ 27 => Mem[0] ~ Mem[2]
    write_instruction(16'd6, {5'b00111, 3'd0, 3'd0, 5'd1});        // ADDI R0, R0, #1   25 => 26
    write_instruction(16'd7, {5'b00111, 3'd1, 3'd1, 5'd1});        // ADDI R1, R1, #1   i = i + 1
    write_instruction(16'd8, {5'b00110, 3'd0, 3'd1, 3'd2, 2'd1});  // CMP  R1, R2       i != 3
    write_instruction(16'd9, {8'b11000010, 8'b11111011});          // BCS  JUMP(-5)
    write_instruction(16'd10, 16'b00010_001_00000000);             // LLI  R1, #0       (i)
// JUMP
    write_instruction(16'd11, {5'b01000, 3'd0, 3'd0, 5'd1});       // SUBI R0, R0, #1   28 - i
    write_instruction(16'd12, {5'b00011, 3'd4, 3'd1, 5'd0});       // LDR  R4, R1, #0   R4 <= Mem[i]  
    write_instruction(16'd13, {5'b00101, 3'd4, 3'd5, 5'd0});       // STR  R4, R5, #0   25 + i => Mem[30], 25 ~ 27 => Mem[30] ~ Mem[32]
    write_instruction(16'd14, {5'b00011, 3'd7, 3'd5, 5'd0});       // LDR  R7, R5, #0   R7 <= Mem[30]
    write_instruction(16'd15, {5'b11100, 3'd0, 3'd7, 3'd0, 2'd0}); // OutR R7  (25~27)
    write_instruction(16'd16, {5'b00111, 3'd5, 3'd5, 5'd1});       // ADDI R5, R5, #1   30 => 31
    write_instruction(16'd17, {5'b00111, 3'd1, 3'd1, 5'd1});       // ADDI R1, R1, #1   i = i + 1
    write_instruction(16'd18, {5'b00110, 3'd0, 3'd1, 3'd2, 2'd1}); // CMP  R1, R2       i != 3
    write_instruction(16'd19, {8'b11000010, 8'b11111000});         // BCS  JUMP(-8)
    write_instruction(16'd20, {5'b11100, 9'd0, 2'd1});             // HLT
`endif

	// disable the extern write enable
	ext_IR_we = 1'b0;
	ext_DM_we = 1'b0;
	 
    // delay one clock to ensure the proper write to memory
    @(posedge clk) #(clk_period/delay_factor) ext_IR_we = 1'b0;

    // start the cpu to execute the program in memory    
	cpu_reset_n = 1'b0;
	#(clk_period * 10);
	#1 cpu_reset_n = 1'b1;
    test_normal = 1'b0;
    wait (done);
end

task write_instruction;
input [15:0 ] addr, data;
begin
	@(negedge clk)
	test_normal = 1'b1;
	ext_IR_we = 1'b1; ext_addr = addr;
	ext_data = data;
	#(clk_period);
end
endtask

task writeDataMem;
input [15:0] addr, data;
begin
    @(negedge clk);
	 test_normal = 1'b1;
	 ext_DM_we = 1'b1; ext_addr = addr;
	 ext_data = data;
	 #(clk_period);
end
endtask

initial #100000 $finish;
initial $monitor($realtime, "ns %h %h %h %h %h %h %h %h %h \n", clk, reset_n, ext_IR_we, test_normal, ext_addr, ext_data, mem_out, outR, done);

endmodule
