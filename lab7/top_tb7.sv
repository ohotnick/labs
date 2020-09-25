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

logic flag_b;
int ttt;
int   ttt1=0;
int   ttt2=0;



task send ( );

  @( posedge clk )
  
  for (int k = 0; k < GLITCH_TIME_NS_T; k++)
  begin
    ttt = $urandom%20;
    if( ttt > 14 )
	  key_i_t = 1;
	else
      key_i_t = 0;
    #1000;	    
	  
    $display( "send %d" , ttt );
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
	     ttt1 = $time;
		 break;
	   end
    end
  
    forever
    begin
	 @( posedge clk )
     if( key_pressed_stb_o_t == 1 )
	   begin
	     ttt2 = $time;
		 break;
	   end
    end
  $display( "ttt1 %d:   ttt2 %d rez %d " , ttt1, ttt2, ttt2-ttt1);	
  
endtask




task compare ( int temp1, int temp2 );

    if( ( ttt2 - ttt1 - 1000000/CLK_FREQ_MHZ_T ) == ( GLITCH_TIME_NS_T * 1000 ) )
      $display( "Glitch time is done" );
    else
      $error("no match of results");
 
endtask




initial
  begin
    #500 
	flag_b = 0;
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
	    compare( ttt1, ttt2  );
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

