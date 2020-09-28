module top_tb3;
bit clk;
bit reset;
 
initial 
	forever 
		#100 clk=!clk;
//#10000 clk=!clk;


  


logic data_i_t;		//вход данные
logic data_val_i_t;

logic [15:0]ser_data_o_t;			//вых данные
logic ser_data_val_t;		//вых валид





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
   #600; 
   @(posedge clk)
   begin
   data_i_t<=1;             //1бит 1
   data_val_i_t<=1;
   end
   @(posedge clk)
   data_i_t<=1;             //2бит  11
      @(posedge clk)
   data_i_t<=0;             //3бит  110
      @(posedge clk)
   data_i_t<=1;             //4бит  1101
      @(posedge clk)
   data_i_t<=0; 	           //5бит  11010
      @(posedge clk)
   data_i_t<=1;             //6бит  110101
      @(posedge clk)
   data_i_t<=0;             //7бит  1101010
      @(posedge clk)
   data_i_t<=1;             //8бит  11010101
      @(posedge clk)
   data_i_t<=0; 	           //9бит  110101010
      @(posedge clk)
   data_i_t<=1;             //10бит 1101010101
      @(posedge clk)
   data_i_t<=0;             //11бит 11010101010
      @(posedge clk)
   data_i_t<=1;             //12бит 110101010101
      @(posedge clk)
   data_i_t<=0;             //13бит 1101010101010
      @(posedge clk)
   data_i_t<=1;             //14бит 11010101010101

   
        @(posedge clk)
   begin
   data_i_t<=1;             //ложный бит 1
   data_val_i_t<=0;
   end
        @(posedge clk)
   begin
   data_i_t<=0;             //15бит 110101010101010
   data_val_i_t<=1;
   end
   
      @(posedge clk)
   data_i_t<=1;             //16бит 1101010101010101
   
     @(posedge clk)
   begin
   data_i_t<=1;             //ложный
   data_val_i_t<=0;
   end
        @(posedge clk)
   begin
   data_i_t<=0;             //новая пачка 0
   data_val_i_t<=1;
   end
      @(posedge clk)
      begin
   data_i_t<=1;             //обрыв
   data_val_i_t<=0;
   end

  end  

  
  
deserializer DUT (
	.clk_i(clk),
	.srst_i(reset),

	.data_i(data_i_t),
	.data_val_i(data_val_i_t),

	.ser_data_o(ser_data_o_t),
	.ser_data_val(ser_data_val_t)
);
  
endmodule

