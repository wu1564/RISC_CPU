module adder #(
    parameter integer LENGTH = 16
)(
    input  [LENGTH-1:0] add_in0,
    input  [LENGTH-1:0] add_in1,
    output [LENGTH-1:0] add_out
);

assign add_out = add_in0 + add_in1;

endmodule
