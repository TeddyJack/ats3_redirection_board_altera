module output_process_spi(
input RST,
input RX_CLK,
output TX_DATA,
output TX_LOAD,
output TX_STOP,
input type_ver_now
);

serializer serializer(
.CLK(RX_CLK),
.RST(RST),
.ADDR(3'h1),
.DATA(data),
.ENA(ena),
.SERIAL_OUT(TX_DATA),
.LAST_BIT(TX_LOAD),
.BUSY(busy)
);
wire busy;

reg [15:0] board_mode_message [5:0];
initial
begin
board_mode_message[0] = 16'h55AA;
board_mode_message[1] = 16'h0082;
board_mode_message[2] = 16'h0001;
board_mode_message[3] = 16'h1000;
board_mode_message[4] = 16'h0000;
board_mode_message[5] = 16'h0000;
end

reg [2:0] i;
reg [15:0] data;
reg ena;

reg state;
parameter idle					= 1'b0;
parameter send_board_mode	= 1'b1;

always@(posedge RX_CLK or negedge RST)
begin
if(!RST)
	begin
	state <= idle;
	i <= 0;
	data <= 0;
	ena <= 0;
	end
else
	case(state)
	idle:
		begin
		if(type_ver_now)
			state <= send_board_mode;
		end
	send_board_mode:
		begin
		if(i < 6)
			begin
			if(!busy && !ena)
				begin
				i <= i + 1'b1;
				data <= board_mode_message[i];
				ena <= 1;
				end
			else
				ena <= 0;
			end
		else
			begin
			ena <= 0;
			i <= 0;
			state <= idle;
			end
		end
	endcase
end

endmodule
