module top_tb6;
bit clk;
bit reset;
 
initial 
	forever 
		#100 clk=!clk;
//#10000 clk=!clk;

parameter WIDTH = 5;
  		

logic [WIDTH-1:0]data_i_t;     //вход данные /команда
logic data_val_i_t;

logic [($clog2(WIDTH)+1):0]data_o_t;						//вых
logic data_val_o_t;	





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
   #300; 
   @(posedge clk)
   begin
   data_i_t<=5'b00100;  
   data_val_i_t<=1;
	end   
   @(posedge clk)   
   @(posedge clk)
      begin
   data_i_t<=5'b10101;  
   data_val_i_t<=1;
	end  
   @(posedge clk)
   @(posedge clk)
      begin
   data_i_t<=5'b00100;  
   data_val_i_t<=0;
	end  
	   @(posedge clk)
   @(posedge clk)
      begin
   data_i_t<=5'b11111;  
   data_val_i_t<=1;
	end  
	

  end  


  
  
bit_population_counter DUT 
/*#(
	.WIDTH (5),

)*/
(
	.clk_i(clk),
	.srst_i(reset),

	.data_i(data_i_t),
	.data_val_i(data_val_i_t),

	.data_o(data_o_t),
	.data_val_o(data_val_o_t)
);
  
endmodule

