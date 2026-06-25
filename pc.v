module pc(
    input clk,
    input wr_en,    // create stall
    input b_sel,    // branch detect
    input [31:0] b_target,
    input reset_n,    //active low
    output reg [31:0] pc,
    output [31:0] pc_4) ;

    wire [31:0] next_pc;
    assign pc_4= pc+32'd4;
    assign next_pc =(b_sel)? b_target : pc_4;

    always @(posedge clk) begin
    if (!reset_n)
        pc <= 32'b0;
    else if (wr_en)
        pc <= next_pc;
    end
    
endmodule 