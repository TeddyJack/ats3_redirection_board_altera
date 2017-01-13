module capacity_check(
input RST,
input RX_CLK,
input [15:0] P_DATA_IN,
input P_ENA_IN,
input [8:0] USED,

output [15:0] P_DATA_OUT,
output P_ENA_OUT,
output [7:0] MSG_LEN,
output WR_REQ_LEN,

output reg [7:0] cont_counter,
output [2:0] state_mon
);

wire [8:0] free_space = 9'd511 - USED;
assign MSG_LEN = data_len + non_data_len;
assign state_mon = state;
wire clear_fifo = (end_of_msg && (!capacity_ok)) || not_prefix;
assign WR_REQ_LEN = end_of_msg && capacity_ok;

three_words_fifo three_words_fifo(
.sclr((!RST) || clear_fifo),
.clock(RX_CLK),
.data(P_DATA_IN),
.rdreq(P_ENA_OUT),
.wrreq(P_ENA_IN),
.q(P_DATA_OUT),
.empty(empty)
);
wire empty;
assign P_ENA_OUT = capacity_ok && (!empty);

reg [2:0] state;
parameter [2:0] read_prefix	= 3'h0;
parameter [2:0] read_cod_cmd	= 3'h1;
parameter [2:0] read_len		= 3'h2;
parameter [2:0] read_data		= 3'h3;
parameter [2:0] read_chksum	= 3'h4;

reg msg_has_chksum;
reg [7:0] data_len;
reg [7:0] non_data_len;
reg [7:0] data_cnt;
reg [15:0] msg_chksum;
reg capacity_ok;
reg end_of_msg;
reg not_prefix;
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
	end_of_msg <= 0;
	cont_counter <= 0;
	capacity_ok <= 0;
	not_prefix <= 0;
	end
else if(P_ENA_IN)
	case(state)
	read_prefix:
		begin
		if(P_DATA_IN == 16'h55AA)
			begin
			non_data_len <= 2;
			data_len <= 0;
			state <= read_cod_cmd;
			cont_counter <= cont_counter + 1'b1;
			capacity_ok <= 0;
			end
		else
			not_prefix <= 1;
		end
	read_cod_cmd:
		begin
		msg_has_chksum <= P_DATA_IN[1];
		non_data_len <= non_data_len + msg_has_chksum;	// учитываем поле "контр. сумма" при вычислении длины сообщения
		if(P_DATA_IN[0])						// если сообщение содержит поле "длина"
			state <= read_len;
		else									// если сообщение не содержит поле "длина" (команда имеет фиксированную длину)
			begin
			// здесь определить длину в зависимости от кода команды
			if(P_DATA_IN == 16'hFF00)		// для команды "выйти из цикла приёма сообщений"
				begin
				state <= read_prefix;
				if(MSG_LEN < free_space)	// or free_space > 2
					capacity_ok <= 1;
				// data_len remains 0
				end_of_msg <= 1;
				end
			else								// для остальных команд с фиксированной длиной
				begin
				case(P_DATA_IN)
				16'h0140:	data_len <= 2;				// type ver
				16'h0300:	data_len <= 252;			// status
				endcase
				state <= read_data;
				end
			end
		msg_chksum <= P_DATA_IN;
		end
	read_len:
		begin
		data_len <= P_DATA_IN[7:0];
		state <= read_data;
		msg_chksum <= msg_chksum + P_DATA_IN;
		non_data_len <= non_data_len + 1'b1;	// учитываем поле "data len" при вычислении длины сообщения
		end
	read_data:
		begin
		if(MSG_LEN < free_space)
			capacity_ok <= 1;
			
		if(data_cnt < (data_len - 1'b1))
			data_cnt <= data_cnt + 1'b1;
		else
			begin
			data_cnt <= 0;
			if(msg_has_chksum)
				state <= read_chksum;
			else
				begin
				end_of_msg <= 1;
				state <= read_prefix;
				end
			end
		msg_chksum <= msg_chksum + P_DATA_IN;
		end
	read_chksum:
		begin
		state <= read_prefix;
		end_of_msg <= 1;
		end
	endcase
else
	begin
	end_of_msg <= 0;
	not_prefix <= 0;
	end
end


endmodule
