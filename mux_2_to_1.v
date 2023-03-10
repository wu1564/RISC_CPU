module mux_2_to_1 #(
    parameter integer LENGTH = 16
)(
    input  [LENGTH-1:0] in_0,
    input  [LENGTH-1:0] in_1,
    input  sel,
    output reg [LENGTH-1:0] out
);

always @(*) begin
    case(sel)
        1'b0:    out = in_0;
        1'b1:    out = in_1;
        default: out = in_0;
    endcase
end

endmodule
