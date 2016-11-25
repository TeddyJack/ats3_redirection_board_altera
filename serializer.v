module serializer(
input CLK,
input RST,
input [2:0] ADDR,
input [15:0] DATA,
input ENA,
output reg SERIAL_OUT,
output reg LAST_BIT,
output BUSY
);

assign BUSY = (machine_state == send);

reg machine_state;
parameter wait_for_word	= 1'b0;
parameter send				= 1'b1;

reg [18:0] shift_reg_out;
reg [4:0] counter;
always@(posedge CLK or negedge RST)
begin
if(!RST)
	begin
	machine_state <= wait_for_word;
	shift_reg_out <= 0;
	counter <= 0;
	LAST_BIT <= 0;
	SERIAL_OUT <= 0;
	end
else
	case(machine_state)
	wait_for_word:
		begin
		if(ENA)
			begin
			shift_reg_out[18:16] <= ADDR;
			shift_reg_out[15:0] <= DATA;
			machine_state <= send;
			end
		end
	send:
		begin
		SERIAL_OUT <= shift_reg_out[18];
		shift_reg_out[18:1] <= shift_reg_out[17:0];
		if(counter < 5'd19)
			begin
			counter <= counter + 1'b1;
			if(counter == 5'd18)
				LAST_BIT <= 1;
			end
		else
			begin
			counter <= 0;
			machine_state <= wait_for_word;
			LAST_BIT <= 0;
			SERIAL_OUT <= 0;
			shift_reg_out <= 0;
			end
		end
	endcase
end

endmodule
