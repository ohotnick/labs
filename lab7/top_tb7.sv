module top_tb7;
bit clk;
//bit reset;
 
parameter GLITCH_TIME_NS_T = 500;
parameter CLK_FREQ_MHZ_T   = 20; 
 
initial 
  forever 
    #(1000000/CLK_FREQ_MHZ_T/2) clk=!clk;

logic key_i_t;     //input button

logic key_pressed_stb_o_t;					

int   temp_v;
int   temp_v1=0;
int   temp_v2=0;



task send ( );

  @( posedge clk )
  
  for (int k = 0; k < GLITCH_TIME_NS_T; k++)
  begin
    temp_v = $urandom%20;
    if( temp_v > 14 )
	  key_i_t = 1;
	else
      key_i_t = 0;
    #1000;	    
	  
    $display( "send %d" , temp_v );
  end
  key_i_t = 1;
  for (int k = 0; k < GLITCH_TIME_NS_T/(1000/CLK_FREQ_MHZ_T); k++)
  @( posedge clk );
  key_i_t = 0;
endtask



task get ( );

  forever
    begin
	 @( posedge clk )
     if( key_i_t == 1 )
	   begin
	     temp_v1 = $time;
		 break;
	   end
    end
  
    forever
    begin
	 @( posedge clk )
     if( key_pressed_stb_o_t == 1 )
	   begin
	     temp_v2 = $time;
		 break;
	   end
    end
  $display( "temp_v1 %d:   temp_v2 %d rez %d " , temp_v1, temp_v2, temp_v2-temp_v1);	
  
endtask




task compare ( int temp1, int temp2 );

    if( ( temp_v2 - temp_v1 - 2*1000000/CLK_FREQ_MHZ_T ) == ( GLITCH_TIME_NS_T * 1000 ) )
      $display( "Glitch time is done" );
    else
      $error("no match of results");
 
endtask




initial
  begin
    #500 
    @( posedge clk )
	key_i_t = 0;
    @( posedge clk )
    @( posedge clk )
    @( posedge clk )	
	
	fork
      begin
        send(  );
      end
      begin
        get(); 
      end		  
	join
	  begin
	    compare( temp_v1, temp_v2  );
	    $display( "end ------- " );
		$stop;
      end 
  end

debouncer 
#(
  .CLK_FREQ_MHZ   ( CLK_FREQ_MHZ_T ),
  .GLITCH_TIME_NS ( GLITCH_TIME_NS_T )
)DUT 
(
	.clk_i(clk),

	.key_i(key_i_t),

	.key_pressed_stb_o(key_pressed_stb_o_t)
);
  
endmodule

