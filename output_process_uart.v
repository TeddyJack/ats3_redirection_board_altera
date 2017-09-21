module output_process_uart(
input CLK,
input RST,

input tx_ready,
output reg [7:0] tx_data,
output reg tx_valid,

input [15:0] DATA,
input ENA,
input LAST_AND_ODD,
output BUSY,
output [1:0] state_mon
);
assign state_mon = state;

reg [1:0] state;
parameter [1:0] wait_word		= 2'h0;
parameter [1:0] send_byte		= 2'h1;
parameter [1:0] empty_state	= 2'h2;
parameter [1:0] wait_ready		= 2'h3;
assign BUSY = (state != wait_word);

reg [15:0] captured_word;
reg last_and_odd;
reg now_sending_lsb;

always@(posedge CLK or negedge RST)
begin
if(!RST)
	begin
	state <= empty_state;		// at the reset to make sure that (tx_ready = 1) before waiting for a new word
	captured_word <= 0;
	tx_valid <= 0;
	tx_data <= 0;
	now_sending_lsb <= 1;
	end
else
	case(state)
	wait_word:
		begin
		if(ENA)
			begin
			captured_word <= DATA;
			state <= send_byte;
			last_and_odd <= LAST_AND_ODD;
			end
		end
	send_byte:
		begin
		tx_valid <= 1;
		state <= empty_state;
		if(now_sending_lsb)
			tx_data <= captured_word[7:0];
		else
			tx_data <= captured_word[15:8];
		end
	empty_state:
		begin
		tx_valid <= 0;
		state <= wait_ready;
		end
	wait_ready:
		begin
		if(tx_ready)
			begin
			if(now_sending_lsb | last_and_odd)
				begin
				state <= wait_word;
				now_sending_lsb <= 0;
				end
			else
				begin
				state <= send_byte;
				now_sending_lsb <= 1;
				end
			end
		end
	endcase
end

endmodule
