module top_tb7;
bit clk;
//bit reset;
 
initial 
	forever 
		#100 clk=!clk;
//#10000 clk=!clk;
/*
parameter CLK_FREQ_MHZ = 20;
parameter GLITCH_TIME_NS = 50;
parameter CLK_TIME = 1/CLK_FREQ_MHZ;		//50ns и меньше идет в 1 такт
parameter WIDTH = CLK_TIME/GLITCH_TIME_NS;
  		
*/
logic key_i_t;     //вход данные /команда

logic key_pressed_stb_o_t;						//вых





/*
initial
  begin
    @(posedge clk)
    begin
    reset<=1'b1;
    end
    @(posedge clk)
    reset<=1'b0;
  end
 */

initial
  begin
   #100; 
   @(posedge clk)
   key_i_t<=0;  
      @(posedge clk)
   key_i_t<=1;  
   #400; 
   @(posedge clk)
   key_i_t<=0;  
      @(posedge clk)
   key_i_t<=1; 

	

  end  


  
  
debouncer DUT 
/*#(
	.WIDTH (5),

)*/
(
	.clk_i(clk),

	.key_i(key_i_t),

	.key_pressed_stb_o(key_pressed_stb_o_t)
);
  
endmodule

