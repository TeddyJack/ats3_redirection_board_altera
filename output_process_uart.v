module output_process_uart(
input CLK,
input RST,

input tx_ready,
//output reg [7:0] tx_data,
output [7:0] tx_data,
output reg tx_valid,

input [15:0] DATA,
input ENA,
input LAST_AND_ODD,
output [1:0] state_mon
);
assign state_mon = state;

reg [1:0] state;
parameter [1:0] wait_word		= 2'h0;
parameter [1:0] send_byte		= 2'h1;
parameter [1:0] empty_state	= 2'h2;
parameter [1:0] wait_ready		= 2'h3;

reg now_sending_lsb;
reg rd_req;
assign tx_data = (now_sending_lsb) ? fifo_data[7:0] : fifo_data[15:8];

out_fifo_uart out_fifo_uart(
.clock(CLK),
.data({LAST_AND_ODD, DATA}),
.rdreq(rd_req),
.sclr(full),
.wrreq(ENA),
.empty(empty),
.full(full),
.q({fifo_last_and_odd, fifo_data})
);
wire empty;
wire full;
wire fifo_last_and_odd;
wire [15:0] fifo_data;

always@(posedge CLK or negedge RST)
begin
if(!RST)
	begin
	state <= empty_state;		// at the reset to make sure that (tx_ready = 1) before waiting for a new word
	tx_valid <= 0;
	//tx_data <= 0;
	now_sending_lsb <= 1;
	rd_req <= 0;
	end
else
	case(state)
	wait_word:
		begin
		if(!empty)
			begin
			state <= send_byte;
			rd_req <= 1;
			end
		end
	send_byte:
		begin
		rd_req <= 0;
		tx_valid <= 1;
		state <= empty_state;
		//if(now_sending_lsb)
		//	tx_data <= fifo_data[7:0];
		//else
		//	tx_data <= fifo_data[15:8];
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
			if(now_sending_lsb | fifo_last_and_odd)
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
