module top_tb;
bit clk;
bit reset;
 
initial 
	forever 
		#100 clk=!clk;
//#10000 clk=!clk;


  


logic [15:0]data_i_t;		//вход данные
logic [3:0]data_mod_i_t;  //число валидных бит, от 3
logic data_val_i_t;

logic ser_data_o_t;			//вых данные
logic ser_data_val_t;		//вых валид
logic busy_o_t;				//вых занят




initial
  begin
    @(posedge clk)
    begin
    reset<=1'b1;
    end
    @(posedge clk)
    reset<=1'b0;
  end
  
initial
  begin
   #500; 
   data_i_t <= 16'b1100101010001101;
   data_mod_i_t <= 4'b0111;
   data_val_i_t <= 1'b1;
   #200
   data_val_i_t <= 1'b0;
   #2500; 
   data_i_t <= 16'b1100101010001101;
   data_mod_i_t <= 4'b0010;
   data_val_i_t <= 1'b1;
  end  

  
  
serializer DUT (
	.clk_i(clk),
	.srst_i(reset),

	.data_i(data_i_t),
	.data_mod_i(data_mod_i_t),
	.data_val_i(data_val_i_t),

	.ser_data_o(ser_data_o_t),
	.ser_data_val(ser_data_val_t),
	.busy_o(busy_o_t)
);
  
endmodule

