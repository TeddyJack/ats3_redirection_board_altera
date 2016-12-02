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

output reg type_ver_now,
output [2:0] state_monitor,
output [7:0] msg_len_out,
output reg [7:0] cont_counter
);

assign state_monitor = state;

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
wire [7:0] msg_len_in = data_len + non_data_len;
reg [7:0] data_len;
reg [7:0] non_data_len;
reg [7:0] data_cnt;
reg [15:0] msg_chksum;
reg type_ver_flag;
reg wr_req_len;
always@(posedge RX_CLK or negedge RST)
begin
if(!RST)
	begin
	state <= read_prefix;
	msg_has_chksum <= 0;
	data_len <= 0;
	non_data_len <= 2;	// prefix and code_cmd
	data_cnt <= 0;
	msg_chksum <= 0;
	type_ver_now <= 0;
	type_ver_flag <= 0;
	wr_req_len <= 0;
	cont_counter <= 0;
	end
else if(p_ena)
	case(state)
	read_prefix:
		begin
		if(p_data == 16'h55AA)
			begin
			non_data_len <= 2;
			state <= read_cod_cmd;
			cont_counter <= cont_counter + 1'b1;
			end
		end
	read_cod_cmd:
		begin
		msg_has_chksum <= p_data[1];
		non_data_len <= non_data_len + msg_has_chksum;	// учитываем поле "контр. сумма" при вычислении длины сообщения
		if(p_data[0])						// если сообщение содержит поле "длина"
			state <= read_len;
		else									// если сообщение не содержит поле "длина" (команда имеет фиксированную длину)
			begin
			// здесь определить длину в зависимости от кода команды
			if(p_data == 16'hFF00)		// для команды "выйти из цикла приёма сообщений"
				begin
				state <= read_prefix;
				data_len <= 0;
				wr_req_len <= 1;
				end
			else								// для остальных команд с фиксированной длиной
				begin
				case(p_data)
				16'h0140:	begin								// type ver
								data_len <= 2;
								type_ver_flag <= 1;
								end
				16'h0300:	data_len <= 16;				// status
				endcase
				state <= read_data;
				end
			end
		msg_chksum <= p_data;
		end
	read_len:
		begin
		data_len <= p_data[7:0];
		state <= read_data;
		msg_chksum <= msg_chksum + p_data;
		non_data_len <= non_data_len + 1'b1;	// учитываем поле "data len" при вычислении длины сообщения
		end
	read_data:
		begin
		if(data_cnt < (data_len - 1'b1))
			data_cnt <= data_cnt + 1'b1;
		else
			begin
			data_cnt <= 0;
			if(msg_has_chksum)
				state <= read_chksum;
			else
				begin
				wr_req_len <= 1;
				state <= read_prefix;
				if(type_ver_flag)
					begin
					type_ver_now <= 1;
					type_ver_flag <= 0;
					end
				
				end
			end
		msg_chksum <= msg_chksum + p_data;
		end
	read_chksum:
		begin
		state <= read_prefix;
		end
	endcase
else
	begin
	type_ver_now <= 0;
	wr_req_len <= 0;
	end
end

in_fifo_spi in_fifo_spi(
.aclr((!RST) | fifo_full),		// fifo_full только для отладки
.data(p_data),
.rdclk(SYS_CLK),
.rdreq(RD_REQ),
.wrclk(RX_CLK),
.wrreq(p_ena),
.q(FIFO_Q),
.rdusedw(used),
.wrfull(fifo_full)
);
wire [7:0] used;
wire fifo_full;

fifo_with_lengths fifo_with_lengths(
.aclr((!RST) | fifo_full),
.data(msg_len_in),
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

always@(posedge SYS_CLK or negedge RST)
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
