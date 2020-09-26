module serializer (
input clk_i,
input srst_i,

input [15:0]data_i,
input [3:0]data_mod_i,
input data_val_i,

output ser_data_o,
output ser_data_val,
output busy_o
);

logic [15:0]data_i_p;
//logic [3:0]data_mod_i_p;
logic data_val_i_p;
logic [3:0]cnt;

logic ser_data_o_p;
logic ser_data_val_p;
logic busy_o_p;



always_ff @(posedge clk_i)
begin
  if(srst_i)					//если сброс
  begin
	data_val_i_p<=1'b0;
	busy_o_p<=1'b0;
	data_i_p<=0;
	ser_data_o_p <= 1'b0;
	ser_data_val_p <= 1'b0;
	end
	else
	begin  //else
	
	if(data_val_i==1'b1 && data_val_i_p!=1'b1) //принимаем данные и начинаем работу
		begin
		data_i_p <= data_i;
		//data_mod_i_p <= data_mod_i;
		if(data_mod_i>=3)
		begin
		data_val_i_p <= 1'b1;
		cnt <=15-data_mod_i;
		end
		end
//	else
//	begin
		if(data_val_i_p==1'b1)						//работа
		begin
		busy_o_p <= 1'b1;								//заняты
		ser_data_val_p <= 1'b1;
		
		cnt <=cnt + 1'b1;
		
		
		ser_data_o_p <= data_i_p[15];
		data_i_p<=data_i_p<<1;
		
		if(cnt == 15)									//конец работы
		begin
		busy_o_p <= 1'b0;
		data_val_i_p <= 1'b0;
		ser_data_o_p <= 1'b0;
		ser_data_val_p <= 1'b0;
		end
		end
		
//end		//else второй	
end		//else
end		//always_ff


		assign ser_data_o = ser_data_o_p;
		assign ser_data_val = ser_data_val_p;
		assign busy_o = busy_o_p;







endmodule