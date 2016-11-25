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
output [7:0] current_msg_len,

output reg type_ver_now
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

reg [2:0] state;
parameter [2:0] read_prefix	= 3'h0;
parameter [2:0] read_cod_cmd	= 3'h1;
parameter [2:0] read_len		= 3'h2;
parameter [2:0] read_data		= 3'h3;
parameter [2:0] read_chksum	= 3'h4;

reg msg_has_chksum;
reg [7:0] data_len;
reg [7:0] data_cnt;
reg [15:0] msg_chksum;
reg type_ver_already;
reg type_ver_flag;
reg wr_req_len;
always@(posedge RX_CLK or negedge RST)
begin
if(!RST)
	begin
	state <= read_prefix;
	msg_has_chksum <= 0;
	data_len <= 0;
	data_cnt <= 0;
	msg_chksum <= 0;
	type_ver_now <= 0;
	type_ver_already <= 0;
	type_ver_flag <= 0;
	wr_req_len <= 0;
	end
else if(p_ena)
	case(state)
	read_prefix:
		begin
		if(p_data == 16'h55AA)
			state <= read_cod_cmd;
		end
	read_cod_cmd:
		begin
		msg_has_chksum <= p_data[1];
		if(p_data[0])	// если содержится поле "длина"
			state <= read_len;
		else			// для команд с фиксированной длиной
			begin
			state <= read_data;
			// здесь определить длину в зависимости от кода команды
			wr_req_len <= 1;
			case(p_data)
			16'h0140:	begin
							data_len <= 2;
							//if(!type_ver_already)		// чтобы только один раз, а не при каждом получении type_ver
								type_ver_flag <= 1;
							end
			16'h0300:	data_len <= 16;
			endcase
			end
		msg_chksum <= p_data;
		end
	read_len:
		begin
		wr_req_len <= 1;
		data_len <= p_data[7:0];
		state <= read_data;
		msg_chksum <= msg_chksum + p_data;
		end
	read_data:
		begin
		wr_req_len <= 0;
		if(data_cnt < (data_len - 1'b1))
			data_cnt <= data_cnt + 1'b1;
		else
			begin
			data_cnt <= 0;
			if(msg_has_chksum)
				state <= read_chksum;
			else
				begin
				state <= read_prefix;
				if(type_ver_flag)
					begin
					type_ver_now <= 1;
					type_ver_already <= 1;
					type_ver_flag <= 0;
					end
				end
			end
		msg_chksum <= msg_chksum + p_data;
		end
	endcase
else
	type_ver_now <= 0;
end

in_fifo_spi in_fifo_spi(
.aclr(!RST),
.data(p_data),
.rdclk(SYS_CLK),
.rdreq(RD_REQ),
.wrclk(RX_CLK),
.wrreq(p_ena),
.q(FIFO_Q),
.rdusedw(used)
);
wire [7:0] used;

assign current_msg_len = data_len + 2'd2;
always@(posedge SYS_CLK or negedge RST)
begin
if(!RST)
	begin
	GOT_FULL_MSG <= 0;
	end
else
	begin
	if(used >= current_msg_len)
		GOT_FULL_MSG <= 1;
	else
		GOT_FULL_MSG <= 0;
	end
end

fifo_with_lengths fifo_with_lengths(
.aclr(!RST),
.data(current_msg_len),
.rdclk(),
.rdreq(),
.wrclk(RX_CLK),
.wrreq(wr_req_len),
.q()
);

reg output_state;
parameter output_idle			= 1'b0;
parameter output_in_progress	= 1'b1;

reg rd_req_len;

always@(posedge RX_CLK or negedge RST)
begin
if(!RST)
	begin
	rd_req_len <= 0;
	end
else
	case(output_state)
	output_idle:
		begin
		if(GOT_FULL_MSG && RD_REQ)
			begin
			rd_req_len <= 1;
			output_state <= output_in_progress;
			end
		end
	output_in_progress:
		begin
		rd_req_len <= 0;
		// добавить здесь переход обратно в idle
		end
	endcase
end

endmodule
