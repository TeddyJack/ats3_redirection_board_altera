module output_process_uart(
input CLK,
input RST,

input tx_ready,
output reg [7:0] tx_data,
output reg tx_valid,

input [15:0] DATA,
input ENA,
input [7:0] MSG_LEN_IN,
input PARITY_IN,
output BUSY
);

reg [1:0] state;
parameter [1:0] idle				= 2'h0;
parameter [1:0] empty_state	= 2'h1;
parameter [1:0] send_byte		= 2'h2;
assign BUSY = (state != idle);

reg [7:0] counter;
reg [7:0] captured_lsb;
reg flag_lsb;

always@(posedge CLK or negedge RST)
begin
if(!RST)
	begin
	state <= idle;
	counter <= 0;
	captured_lsb <= 0;
	tx_valid <= 0;
	tx_data <= 0;
	flag_lsb <= 0;
	end
else
	case(state)
	idle:
		begin
		if(ENA)
			begin
			tx_valid <= 1;
			tx_data <= DATA[15:8];
			captured_lsb <= DATA[7:0];
			state <= empty_state;
			end
		end
	send_byte:
		begin
		if(tx_ready)
			begin
			if(flag_lsb)
				begin
				state <= idle;
				flag_lsb <= 0;
				if(counter < (MSG_LEN_IN-1'b1))
					counter <= counter + 1'b1;
				else
				counter <= 0;
				end
			else
				begin
				if((PARITY_IN == 1) && (counter == (MSG_LEN_IN-1'b1)))
					begin
					counter <= 0;
					state <= idle;
					end
				else
					begin
					tx_valid <= 1;
					tx_data <= captured_lsb;
					state <= empty_state;
					flag_lsb <= 1;
					end
				end
			end
		end
	empty_state:
		begin
		tx_valid <= 0;
		state <= send_byte;
		end
	endcase
end

endmodule
