module input_process_uart(
input CLK,
input RST,
output rx_ready,
input [7:0] rx_data,
input rx_valid,

input RD_REQ,
input MSG_START,
output [15:0] FIFO_Q,
output reg [7:0] MSG_LEN,
output reg PARITY_OUT,
output reg GOT_FULL_MESSAGE
);
assign rx_ready = !fifo_full;

uart_fifo uart_fifo(
.data(rx_data),
.rdclk(CLK),
.rdreq(RD_REQ),
.wrclk(CLK),
.wrreq(rx_valid | wr_req_stuff),
.q({FIFO_Q[7:0],FIFO_Q[15:8]}),
.rdusedw(rd_used),
.wrfull(fifo_full),
.wrusedw(wr_used)
);
wire [6:0] rd_used;
wire fifo_full;
wire [7:0] wr_used;

// wr_used[0] - is a plain indicator of odd number of bytes in FIFO
wire wr_req_stuff = MSG_START & wr_used[0] & (!rx_valid);	// stuffing byte if we have odd number of bytes in FIFO
reg [31:0] timer;

always@(posedge CLK or negedge RST)
begin
if(!RST)
	begin
	GOT_FULL_MESSAGE <= 0;
	MSG_LEN <= 0;
	PARITY_OUT <= 0;
	timer <= 0;
	end
else
	begin
	if(RD_REQ)
		GOT_FULL_MESSAGE <= 0;
	else if(((timer == `GFM_LIMIT) && (wr_used > 0)) || (rd_used == `UART_WORDS))
		GOT_FULL_MESSAGE <= 1;
	////
	if(RD_REQ)		// здесь может быть MSG_SENT
		timer <= 0;
	else
		begin
		if(timer < `GFM_LIMIT)
			timer <= timer + 1'b1;
		else
			begin
			if(wr_used == 0)
				timer <= 0;
			end
		end
	/////
	if(MSG_START)
		begin
		//MSG_LEN <= rd_used + wr_used[0];			// simple variant if FIFO is small, and rd_used never exceeds 256
		MSG_LEN <= {8{used[8]}} | used[7:0];		// complex variant for FIFO more than 256 words (each of 2 bytes). Versatile. Also that makes this state_machine similar to state_machine in input_process_spi module
		PARITY_OUT <= wr_used[0] & (!rx_valid);
		end
	end
end

wire [8:0] used = rd_used + wr_used[0];			// if odd bytes then stuffing is applied, so (used + 1). Don't try to understand, it just works.


endmodule
