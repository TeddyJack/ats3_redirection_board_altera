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
output [`NUM_SPI:1] LEDS_BA,
output LED_REMOTE,
// UART
input [(`NUM_UART-1):0] UART_RX,
output [(`NUM_UART-1):0] UART_TX,
output UART_GND,
// I2C
inout SDA,
inout SCL,
// GPIO
output [3:0] GPIO
);

assign TX_CLK = (~RX_CLK);
assign UART_GND = 0;

pll pll(
.inclk0(CLK_IN),
.c0(ifclk)
);
wire ifclk;

assign IFCLK = !ifclk;

wire [(`NUM_SOURCES*16-1):0] fifo_q;
wire [(`NUM_SOURCES-1):0] got_full_msg;
wire [(`NUM_SOURCES*8-1):0] msg_len;
wire [(`NUM_SOURCES-1):0] serializer_busy;
wire [(`NUM_SOURCES-1):0] parity_from_uart;

genvar i;
generate
for(i=0; i<`NUM_SPI; i=i+1)
	begin: wow
	spi_process instance_name(
	.RST(RST),
	.SYS_CLK(ifclk),
	.RX_CLK(RX_CLK[i]),
	.RX_DATA(RX_DATA[i]),
	.RX_LOAD(RX_LOAD[i]),
	.RX_STOP(RX_STOP[i]),
	
	.RD_REQ(rd_req[i]),
	.RD_REQ_LEN(msg_start[i]),	// temporary until mechanism is redone
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
for(i=0; i<`NUM_UART; i=i+1)
	begin: hoy
	uart_process instance2_name(
	.CLK(ifclk),
	.RST(RST),
	.RX(UART_RX[i]),
	.TX(UART_TX[i]),
	.DATA({FD[7:0],FD[15:8]}),
	.ENA(cy_ena[`NUM_SPI+i]),
	.MSG_LEN_IN(payload_len),
	.PARITY_IN(parity_to_uart),
	.BUSY(serializer_busy[`NUM_SPI+i]),
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
.MSG_START(msg_start),
.SLRD(SLRD),
.FIFOADR(FIFOADR),
.PKTEND(PKTEND),
.ENA(cy_ena),

.PARITY_IN(parity_from_uart),
.PARITY_OUT(parity_to_uart),
.payload_len(payload_len)
);
wire [(`NUM_SOURCES-1):0] rd_req;
wire [(`NUM_SOURCES-1):0] msg_start;
wire [(`NUM_SOURCES-1):0] cy_ena;
wire [7:0] payload_len;
wire parity_to_uart;

endmodule
