module deserializer(
input RST,
input RX_CLK,
input RX_DATA,
input RX_LOAD,
input RX_STOP,
output [2:0] P_ADDR,
output [15:0] P_DATA,
output reg P_ENA
);

assign P_ADDR = shift_reg_in[18:16];
assign P_DATA = shift_reg_in[15:0];

reg [18:0] shift_reg_in;
always@(posedge RX_CLK or negedge RST)
begin
if(!RST)
	begin
	shift_reg_in <= 0;
	end
else
	begin
	shift_reg_in[0] <= RX_DATA;
	shift_reg_in[18:1] <= shift_reg_in[17:0];
	end
end

always@(posedge RX_CLK or negedge RST)
begin
if(!RST)
	P_ENA <= 0;
else
	P_ENA <= RX_LOAD;
end

endmodule
