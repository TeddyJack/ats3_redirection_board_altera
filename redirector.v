module redirector(
input CLK_IN,
input RST,
// SPI bus
input [3:0] RX_CLK,
input [3:0] RX_DATA,
input [3:0] RX_LOAD,
input [3:0] RX_STOP,
output [3:0] TX_CLK,
output [3:0] TX_DATA,
output [3:0] TX_LOAD,
output [3:0] TX_STOP,
// cypress exchange pins
input FLAG_EMPTY,	// FLAGA
input FLAG_FULL,	// FLAGB
inout [15:0] FD,
output SLOE,
output SLWR,
output SLRD,
output [1:0] FIFOADR,
output PKTEND,
output IFCLK,
// LEDs on front panel
output [4:1] LEDS_BA,
output LED_REMOTE,
// UART
input UART0_RX,
output UART0_TX,
input UART1_RX,
output UART1_TX,
// I2C
inout SDA,
inout SCL,
// GPIO
output [3:0] GPIO
);

assign TX_CLK = (~RX_CLK);

pll pll(
.inclk0(CLK_IN),
.c0(ifclk)
);
wire ifclk;

assign IFCLK = ifclk;

wire [63:0] fifo_q;
wire [3:0] got_full_msg;
wire [31:0] msg_len;
wire [3:0] serializer_busy;

genvar i;
generate
for(i=0; i<4; i=i+1)
	begin: wow
	spi_process instance_name(
	.RST(RST),
	.SYS_CLK(ifclk),
	.RX_CLK(RX_CLK[i]),
	.RX_DATA(RX_DATA[i]),
	.RX_LOAD(RX_LOAD[i]),
	.RX_STOP(RX_STOP[i]),
	
	.RD_REQ(rd_req[i]),
	.RD_REQ_LEN(msg_sent[i]),
	.FIFO_Q(fifo_q[(16*i+15):(16*i)]),
	.GOT_FULL_MSG(got_full_msg[i]),
	.msg_len_out(msg_len[(8*i+7):(8*i)]),
	
	.TX_DATA(TX_DATA[i]),
	.TX_LOAD(TX_LOAD[i]),
	.TX_STOP(TX_STOP[i]),
	
	.DATA({FD[7:0],FD[15:8]}),	// words are transferred via cypress in little-endian format, we convert into big-endian
	.ENA(cy_ena[i]),
	.BUSY(serializer_busy[i])
	);
	end
endgenerate

read_write_slave_fifo read_write_slave_fifo(
.CLK(ifclk),
.RST(RST),
.FLAG_EMPTY(FLAG_EMPTY),
.FLAG_FULL(FLAG_FULL),
.FD({FD[7:0],FD[15:8]}),	// words are transferred via cypress in little-endian format, we convert into big-endian
.fifo_q_bus(fifo_q),
.GOT_FULL_MSG(got_full_msg),
.SERIALIZER_BUSY(serializer_busy),
.MSG_LEN_BUS(msg_len),

.SLOE(SLOE),
.SLWR(SLWR),
.RD_REQ(rd_req),
.MSG_SENT(msg_sent),
.SLRD(SLRD),
.FIFOADR(FIFOADR),
.PKTEND(PKTEND),
.ENA(cy_ena)
);
wire [3:0] rd_req;
wire [3:0] msg_sent;
wire [3:0] cy_ena;

endmodule
