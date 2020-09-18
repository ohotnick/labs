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
 
 /*
initial
  begin
   #300; 
   @(posedge clk)
   data_i_t<=5'b00110;    
   @(posedge clk)   
   data_i_t<=5'b11111; 
   @(posedge clk)
   data_i_t<=5'b00000; 

  end  
*/
//-------------------------
logic [WIDTH:0] send_c;
logic [WIDTH:0] get_c;
logic flag_b;


task send ( logic [WIDTH-1:0] value );

  @( posedge clk )
  @( posedge clk )
  begin
  data_i_t = value;
  send_c   = send_c + 1;
  $display( "send N%d:       %b" , send_c, value );
  end
  
endtask
  
task get ( );
  
  @( posedge clk )
  @( posedge clk )
  begin
  get_c = get_c + 1;
  $display( "get N%d:   left %b\n          right %b \n" , get_c, data_left_o_t, data_right_o_t );	
  end
  
endtask
 

initial
  begin
    #500 
    send_c = 0;
	get_c  = -1;
	flag_b = 0;
	
	fork
      begin
        forever
          begin
            get();
		    if ( flag_b == 1 )
		      break;
		  end  
      end	
      begin
        for (int i = 0; i < 2**WIDTH; i++)
		  begin
            send( i );
          end   
		  flag_b = 1;  
      end
	join
	  begin
	    $display( "end ------- " );
      end
	  
  end	  
  
  
priority_encoder DUT 
/*#(
	.WIDTH (5)
)*/
(
	.clk_i(clk),
	.srst_i(reset),

	.data_i(data_i_t),

	.data_left_o(data_left_o_t),
	.data_right_o(data_right_o_t)
);
  
endmodule

