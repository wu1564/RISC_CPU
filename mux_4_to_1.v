module mux_4_to_1 #(
    parameter integer LENGTH = 16
)(
    input  [LENGTH-1:0] in_0,
    input  [LENGTH-1:0] in_1,
    input  [LENGTH-1:0] in_2,
    input  [LENGTH-1:0] in_3,
    input  [1:0] sel,
    output reg [LENGTH-1:0] out
);

always @(*) begin
    case(sel)
        2'd0:    out = in_0;
        2'd1:    out = in_1;
        2'd2:    out = in_2;
        2'd3:    out = in_3;
        default: out = in_0;
    endcase
end

endmodule
