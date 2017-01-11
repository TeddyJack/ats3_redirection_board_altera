module input_process_spi(
input RST,
input SYS_CLK,
input RX_CLK,
input RX_DATA,
input RX_LOAD,
input RX_STOP,

input RD_REQ,
output [15:0] FIFO_Q,
output reg GOT_FULL_MSG,

output type_ver_now,
output [7:0] msg_len_out
);

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
.WR_REQ_LEN(wr_req_len),
.type_ver_now(type_ver_now)
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
.rdreq(rd_req_len),
.wrclk(RX_CLK),
.wrreq(wr_req_len),
.q(msg_len_out),
.rdempty(len_fifo_empty)
);

//wire [7:0] msg_len_out;	// commented coz added to ports
wire len_fifo_empty;

reg [1:0] output_state;
parameter output_idle			= 2'h0;
parameter output_in_progress	= 2'h1;
parameter output_timeout		= 2'h2;

reg rd_req_len;
reg [7:0] counter;

always@(posedge SYS_CLK or negedge RST)	// этот блок формирует сигнал GOT_FULL_MSG
begin
if(!RST)
	begin
	rd_req_len <= 0;
	counter <= 0;
	output_state <= output_idle;
	GOT_FULL_MSG <= 0;
	end
else
	case(output_state)
	output_idle:
		begin
		if(!len_fifo_empty)
			GOT_FULL_MSG <= 1;
		if(RD_REQ)
			begin
			output_state <= output_in_progress;
			counter <= counter + 1'b1;
			end
		end
	output_in_progress:
		if(RD_REQ)
			begin
			if(counter < (msg_len_out - 1'b1))
				counter <= counter + 1'b1;
			else
				begin
				counter <= 0;
				output_state <= output_timeout;
				rd_req_len <= 1;
				GOT_FULL_MSG <= 0;
				end
			end
		output_timeout:
			begin
			rd_req_len <= 0;
			if(counter < 2)	// таймаут 2 такта
				counter <= counter + 1'b1;
			else
				begin
				output_state <= output_idle;
				counter <= 0;
				end
			end
	endcase
end

endmodule
