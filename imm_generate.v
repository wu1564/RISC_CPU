module imm_generate #(
    parameter integer LENGTH = 16
)(
    input  [10:0] immediate_i,
    output [15:0] immediate_o
);

assign immediate_o = {{5{immediate_i[10]}},immediate_i};

endmodule
