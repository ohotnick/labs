module deserializer (
input clk_i,
input srst_i,

input data_i,
input data_val_i,

output [15:0]ser_data_o,
output ser_data_val
);


logic [15:0]ser_data_o_p;
logic ser_data_val_p;
logic [3:0]cnt;
logic per;


always_ff @(posedge clk_i)
begin
 // ser_data_o_p <= ser_data_o_p >> 1;
//  ser_data_o_p[1] <= data_i;
  
  if(srst_i)					//если сброс
  begin
	 cnt <= 0;
    per <= 0;
	 ser_data_val_p <= 0;
	 ser_data_o_p <=0;
  
	end
	else
	begin  //else
	
	
	if(per!=1)
	 begin
	 cnt <= 0;
    per <= 1;
	 ser_data_val_p <= 0;
	 //ser_data_o_p <=0;
	 end
	 
	else
		begin
		
	
	
	if(data_val_i==1)
	begin 
	cnt <=cnt + 1'b1;
	ser_data_o_p <= ser_data_o_p << 1;
	ser_data_o_p[0] <= data_i;
	
		if(cnt==15)
	 begin
	 ser_data_val_p <= 1;
    per <= 0;
	 end
	end
	

	
		end//else
	

end		//else


end		//always_ff

		assign ser_data_o = ser_data_o_p;
		assign ser_data_val = ser_data_val_p;


endmodule