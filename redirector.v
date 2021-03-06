`include "defines.v"

module redirector(
input CLK_IN,
input RST,
// SPI bus
input [(`NUM_SPI-1):0] RX_CLK,
input [(`NUM_SPI-1):0] RX_DATA,
input [(`NUM_SPI-1):0] RX_LOAD,
input [(`NUM_SPI-1):0] RX_STOP,
output [(`NUM_SPI-1):0] TX_CLK,
output [(`NUM_SPI-1):0] TX_DATA,
output [(`NUM_SPI-1):0] TX_LOAD,
output [(`NUM_SPI-1):0] TX_STOP,
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
output [`NUM_LEDS:1] LEDS_BA_R,
output [`NUM_LEDS:1] LEDS_BA_G,
output [`NUM_LEDS:1] LEDS_BA_B,
output LED_REMOTE,
// UART
input [(`NUM_UART-1):0] UART_RX,			// RX and TX pins in Pin Planner were swapped due to wrong naming in scheme
output [(`NUM_UART-1):0] UART_TX,
// I2C
inout SDA,
inout SCL,
// GPIO
output [6:0] GPIO
);

assign GPIO[6] = FLAG_EMPTY;
assign GPIO[5] = FLAG_FULL;

assign TX_CLK = {`NUM_SPI{CLK_IN}};
assign IFCLK = !CLK_IN;						// without this action PKTEND is not always accepted by Cypress. Maybe it's better to fix this with some kinda signal delay

wire [(`NUM_SOURCES*16-1):0] fifo_q;
wire [(`NUM_SOURCES-1):0] got_full_msg;
wire [(`NUM_SOURCES*8-1):0] msg_len;
wire [(`NUM_SOURCES-1):0] parity_from_uart;

genvar i;
generate
for(i=0; i<`NUM_SPI; i=i+1)
	begin: wow
	spi_process instance_name(
	.RST(RST),
	.SYS_CLK(CLK_IN),
	.RX_CLK(RX_CLK[i]),
	.RX_DATA(RX_DATA[i]),
	.RX_LOAD(RX_LOAD[i]),
	.RX_STOP(RX_STOP[i]),
	
	.RD_REQ(rd_req[i]),
	.MSG_START(msg_start[i]),
	.FIFO_Q(fifo_q[(16*i+15):(16*i)]),
	.GOT_FULL_MSG(got_full_msg[i]),
	.MSG_LEN(msg_len[(8*i+7):(8*i)]),
	
	.TX_DATA(TX_DATA[i]),
	.TX_LOAD(TX_LOAD[i]),
	.TX_STOP(TX_STOP[i]),
	
	.DATA(`ifdef BIG_ENDIAN `swap_bytes(FD) `else FD `endif),
	.ENA(cy_ena[i])
	);
	end
for(i=0; i<`NUM_UART; i=i+1)
	begin: hoy
	uart_process instance2_name(
	.CLK(CLK_IN),
	.RST(RST),
	.RX(UART_RX[i]),
	.TX(UART_TX[i]),
	.DATA(`swap_bytes(FD)),
	.ENA(cy_ena[`NUM_SPI+i]),
	.LAST_AND_ODD(last_and_odd),
	.RD_REQ(rd_req[`NUM_SPI+i]),
	.MSG_START(msg_start[`NUM_SPI+i]),
	.FIFO_Q(fifo_q[(16*(`NUM_SPI+i)+15):(16*(`NUM_SPI+i))]),
	.MSG_LEN(msg_len[(8*(`NUM_SPI+i)+7):(8*(`NUM_SPI+i))]),
	.PARITY_OUT(parity_from_uart[`NUM_SPI+i]),
	.GOT_FULL_MESSAGE(got_full_msg[`NUM_SPI+i])
	);
	end
endgenerate

read_write_slave_fifo read_write_slave_fifo(
.CLK(CLK_IN),
.RST(RST),
.FLAG_EMPTY(FLAG_EMPTY),
.FLAG_FULL(FLAG_FULL),
.FD(`swap_bytes(FD)),
.fifo_q_bus(fifo_q),
.GOT_FULL_MSG(got_full_msg),
.MSG_LEN_BUS(msg_len),

.SLOE(SLOE),
.SLWR(SLWR),
.RD_REQ(rd_req),
.MSG_START(msg_start),
.SLRD(SLRD),
.FIFOADR(FIFOADR),
.PKTEND(PKTEND),
.ENA(cy_ena),
.data(data),

.PARITY_IN(parity_from_uart),
.LAST_AND_ODD(last_and_odd)
);
wire [(`NUM_SOURCES-1):0] rd_req;
wire [(`NUM_SOURCES-1):0] msg_start;
wire [(`NUM_SOURCES-1):0] cy_ena;
wire last_and_odd;
wire [15:0] data;

assign FD = SLOE ? 16'hzzzz : `swap_bytes(data);

endmodule
