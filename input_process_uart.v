// потенциально уязвимый модуль, определяет наличие полного сообщения, если в течение времени (2 * T_rx_busy) не приходило новых байт
// T_rx_busy - время десериализации UART байта
// опасность: если за время передачи из FIFO UART в FIFO MAIN придёт следующее целое сообщение, то перепишутся значения MSG_LEN и PARITY_OUT
// особенно критична перезапись MSG_LEN, так как FIFO MAIN дочитывает предыдущее сообщение до величины MSG_LEN и возникнет недочитывание / перечитывание
// чтобы этого избежать, можно поставить FIFO with lengths как в модуле spi_input_process,
// но вероятность настолько скорого прихода второго сообщения после первого - крайне мала и вообще я буду менять принцип всей системы

module input_process_uart(
input CLK,
input RST,
output rx_ready,
input [7:0] rx_data,
input rx_valid,
input rx_busy,

input RD_REQ,
input RD_REQ_LEN,
output [15:0] FIFO_Q,
output reg [7:0] MSG_LEN,
output reg PARITY_OUT,
output reg GOT_FULL_MESSAGE,
output [1:0] state_mon 
);
assign rx_ready = 1'b1;
assign state_mon = state;

uart_fifo uart_fifo(
.data(rx_data),
.rdclk(CLK),
.rdreq(RD_REQ),
.wrclk(CLK),
.wrreq(rx_valid | wr_req_stuff),
.q({FIFO_Q[7:0],FIFO_Q[15:8]}),
.rdusedw(rd_used),
.wrusedw(wr_used)
);
wire [6:0] rd_used;
wire [7:0] wr_used;

reg [31:0] measurer;
reg [31:0] measured_time;
reg [31:0] counter;
reg [1:0] state;
parameter [1:0] idle		= 2'h0;
parameter [1:0] measure	= 2'h1;
parameter [1:0] count	= 2'h2;
reg wr_req_stuff;

always@(posedge CLK or negedge RST or posedge RD_REQ)
begin
if(RD_REQ)						// if at least one byte was read
	GOT_FULL_MESSAGE <= 0;
else if(!RST)
	begin
	measurer <= 0;
	counter <= 0;
	measured_time <= 0;
	state <= idle;
	GOT_FULL_MESSAGE <= 0;
	MSG_LEN <= 0;
	PARITY_OUT <= 0;
	wr_req_stuff <= 0;
	end
else
	case(state)
	idle:
		begin
		wr_req_stuff <= 0;
		if(rx_busy)
			state <= measure;
		end
	measure:
		begin
		if(rx_busy)
			begin
			measurer <= measurer + 1'b1;
			end
		else
			begin
			measurer <= 0;
			measured_time <= measurer;
			state <= count;
			end
		end
	count:
		begin
		if(rx_busy)
			begin
			counter <= 0;
			state <= measure;
			end
		else
			begin
			if(counter < (measured_time << 1))
				counter <= counter + 1'b1;
			else
				begin
				state <= idle;
				GOT_FULL_MESSAGE <= 1;
				if(wr_used[0])		// if odd number of bytes
					begin
					wr_req_stuff <= 1;
					PARITY_OUT <= 1;
					MSG_LEN <= rd_used + 1'b1;
					end
				else
					begin
					PARITY_OUT <= 0;
					MSG_LEN <= rd_used;
					end
				counter <= 0;
				end
			end
		end
	endcase
end


endmodule
