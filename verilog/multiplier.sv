`define WIDTH_LOG 5
`define WIDTH (1 << `WIDTH_LOG)
`define OUT_WIDTH (`WIDTH << 1)

// Shift-and-Add multiplier
module MUL(
    input clk,
    input in_valid,
    input [`WIDTH-1:0] a,
    input [`WIDTH-1:0] b,
    output [`OUT_WIDTH-1:0] o,
    output out_valid
);
    reg [`WIDTH-1:0] a_reg, b_reg;
    reg [`OUT_WIDTH-1:0] o_reg;
    reg busy;
    reg finish;
    reg [`WIDTH_LOG:0] counter;

    initial begin
        a_reg = 0;
        b_reg = 0;
        o_reg = 0;
        busy = 0;
        finish = 0;
        counter = 0;
    end

    wire busy_next = in_valid && !busy || busy && !finish;
    wire finish_next = (a_reg == 0 || b_reg == 0) && busy;
    wire [`WIDTH-1:0] a_reg_next = in_valid && !busy ? a : a_reg;
    wire [`WIDTH-1:0] b_reg_next = in_valid && !busy ? b : b_reg >> 1;
    wire [`WIDTH_LOG:0] counter_next = !busy ? 0 : counter + 1;
    wire [`OUT_WIDTH-1:0] o_reg_next = !busy ? 0 : o_reg + (b_reg[0] ? a_reg << counter : 0);

    always @(posedge clk) begin
        finish <= finish_next;
        busy <= busy_next;
        a_reg <= a_reg_next;
        b_reg <= b_reg_next;
        counter <= counter_next;
        o_reg <= o_reg_next;
    end

    assign o = o_reg;
    assign out_valid = finish;
endmodule