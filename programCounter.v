module programCounter #(
    parameter integer LENGTH = 16
)(
    input  clk,
    input  reset_n,
    input  [LENGTH-1:0] pc_sel_in,
    output [LENGTH-1:0] pc_out
);

reg [LENGTH-1:0] pc;

assign pc_out = pc;

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        pc <= {LENGTH{1'b0}};
    end else begin
        pc <= pc_sel_in;
    end
end

endmodule
