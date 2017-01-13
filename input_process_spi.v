module input_process_spi(
input RST,
input SYS_CLK,
input RX_CLK,
input RX_DATA,
input RX_LOAD,
input RX_STOP,

input RD_REQ,
input RD_REQ_LEN,
output [15:0] FIFO_Q,
output GOT_FULL_MSG,

output [7:0] msg_len_out
);
assign GOT_FULL_MSG = !len_fifo_empty;

deserializer deserializer(
.RST(RST),
.RX_CLK(RX_CLK),
.RX_DATA(RX_DATA),
.RX_LOAD(RX_LOAD),
.RX_STOP(RX_STOP),

.P_ADDR(p_addr),
.P_DATA(p_data),
.P_ENA(p_ena)
);
wire [2:0] p_addr;
wire [15:0] p_data;
wire p_ena;

capacity_check capacity_check(
.RST(RST),
.RX_CLK(RX_CLK),
.P_DATA_IN(p_data),
.P_ENA_IN(p_ena),
.USED(used),

.P_DATA_OUT(p_data_out),
.P_ENA_OUT(p_ena_out),
.MSG_LEN(msg_len),
.WR_REQ_LEN(wr_req_len)
);
wire [15:0] p_data_out;
wire p_ena_out;
wire [7:0] msg_len;
wire wr_req_len;

in_fifo_spi in_fifo_spi(
.aclr(!RST),
.data(p_data_out),
.rdclk(SYS_CLK),
.rdreq(RD_REQ),
.wrclk(RX_CLK),
.wrreq(p_ena_out),
.q(FIFO_Q),
.wrusedw(used)
);
wire [8:0] used;

fifo_with_lengths fifo_with_lengths(
.aclr(!RST),
.data(msg_len),
.rdclk(SYS_CLK),
.rdreq(RD_REQ_LEN),
.wrclk(RX_CLK),
.wrreq(wr_req_len),
.q(msg_len_out),
.rdempty(len_fifo_empty)
);

wire len_fifo_empty;

endmodule
