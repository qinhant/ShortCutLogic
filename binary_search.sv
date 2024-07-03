`define LENGTH_LOG 4
`define LENGTH (1 << 4)
`define WIDTH 8

module binary_search(
    input clk,
    input [`WIDTH-1:0] data
);

reg [`WIDTH-1:0] array [`LENGTH-1:0];
reg [`LENGTH_LOG:0] counter;
reg [`WIDTH-1:0] last_data = 0;

always @(posedge clk) begin
    counter <= (counter == `LENGTH) ? counter : counter + 1;
    array[counter] <= (counter < `LENGTH) ? data : array[counter];
    last_data <= data;
end

assume property (data >= last_data || counter == `LENGTH);

reg [`LENGTH - 1 : 0] compare;
reg [`LENGTH_LOG - 1 : 0] result_array [`LENGTH - 2 : 0];
always @(*) begin
    for (int i = 0; i < `LENGTH; i=i+1) begin
        compare[i] = (counter < `LENGTH) ? 0 : (array[i] >= data);
    end
    for (int j = 0; j < `LENGTH - 1; j = j + 1) begin
        result_array[j] = (compare[j] == 0 && compare[j+1] == 1) ? j + 1 : 0;
    end

end

wire not_found = result_array == 0;
wire [`LENGTH_LOG - 1 : 0] result = not_found ? `LENGTH - 1 : |result_array;






endmodule

