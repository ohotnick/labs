module top_tb5;
bit clk;
bit reset;
 
initial 
	forever 
		#100 clk=!clk;
//#10000 clk=!clk;

parameter WIDTH = 5;
  		

logic [WIDTH-1:0]data_i_t;     //вход данные /команда

logic [WIDTH-1:0]data_left_o_t;						//вых
logic [WIDTH-1:0]data_right_o_t;	





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
   data_i_t<=5'b00110;    
   @(posedge clk)   
   @(posedge clk)
   data_i_t<=5'b11111; 
   @(posedge clk)
   @(posedge clk)
   data_i_t<=5'b00000; 

  end  


  
  
priority_encoder DUT 
/*#(
	.BLINK_HALF_PERIOD (2),
	.GREEN_BLINKS_NUM (3),
	.RED_YELLOW_TIME (3),
	.RED_TIME_DEFAULT (3),
	.YELLOW_TIME_DEFAULT (3),
	.GREEN_TIME_DEFAULT (3)
)*/
(
	.clk_i(clk),
	.srst_i(reset),

	.data_i(data_i_t),

	.data_left_o(data_left_o_t),
	.data_right_o(data_right_o_t)
);
  
endmodule

