module input_process_spi(
input RST,
input SYS_CLK,
input RX_CLK,
input RX_DATA,
input RX_LOAD,
output TX_STOP,

input RD_REQ,
input MSG_START,
output [15:0] FIFO_Q,
output reg GOT_FULL_MSG,

output reg [7:0] MSG_LEN
);

deserializer deserializer(
.RST(RST),
.RX_CLK(RX_CLK),
.RX_DATA(RX_DATA),
.RX_LOAD(RX_LOAD),

.P_ADDR(p_addr),
.P_DATA(p_data),
.P_ENA(p_ena)
);
wire [2:0] p_addr;
wire [15:0] p_data;
wire p_ena;

in_fifo_spi in_fifo_spi(
.aclr(!RST),
.data(p_data),
.rdclk(SYS_CLK),
.rdreq(RD_REQ),
.wrclk(RX_CLK),
.wrreq(p_ena),
.q(FIFO_Q),
.rdusedw(used),
.wrfull(TX_STOP)
);
wire [9:0] used;

// нижеприведённая state machine идентична машине в input process uart за исключением PARITY бита
reg [31:0] timer;
always@(posedge SYS_CLK or negedge RST)
begin
if(!RST)
	begin
	GOT_FULL_MSG <= 0;
	MSG_LEN <= 0;
	timer <= 0;
	end
else
	begin
	if(RD_REQ)
		GOT_FULL_MSG <= 0;
	else if(((timer == `GFM_LIMIT) && (used > 0)) || (used == `SPI_WORDS))
		GOT_FULL_MSG <= 1;
	////
	if(RD_REQ)		// здесь может быть MSG_SENT, тогда возможно счётчик будет отсчитывать точнее
		timer <= 0;
	else
		begin
		if(timer < `GFM_LIMIT)
			timer <= timer + 1'b1;
		else
			begin
			if(used == 0)
				timer <= 0;
			end
		end
	/////
	if(MSG_START)
		begin
		MSG_LEN <= {8{used[8]}} | used[7:0];		// if (used > 255) (MSG_LEN <= 255) else (MSG_LEN <= used);
		end													// because length field in msg header is 8 bits wide. No need to make it wider
	end
end

endmodule
