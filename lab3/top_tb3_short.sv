module top_tb3;
bit clk;
bit reset;
 
initial 
	forever 
		#100 clk=!clk;


parameter DESER_W_T = 16;


logic data_i_t;		//вход данные
logic data_val_i_t;

logic [(DESER_W_T-1):0]ser_data_o_t;			//вых данные
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
  end  


logic flag_b;
logic flag_send;

logic [( DESER_W_T - 1 ):0] ref_queue [$];									
logic [( DESER_W_T - 1 ):0] result_queue [$];
int compare_queue_c;

// send data ------------
task send ( logic [( DESER_W_T - 1 ):0] value_1 );

  flag_send = 1;
  ref_queue.push_back( value_1 );  
  $display( "send %b", value_1 );

  for( int i = 0; i < ( DESER_W_T ); i++ )
    begin
      @(posedge clk);
      data_i_t     = value_1[DESER_W_T - ( 1 + i )];
      data_val_i_t = 1;
    end
  @(posedge clk)
  data_val_i_t = 0;

endtask

// get data ---------
task get (  );

  @(posedge clk)
  if( ser_data_val_t == 1 )
    begin
      result_queue.push_back( ser_data_o_t );
      $display( "get  %b" , ser_data_o_t );
      flag_send = 0;
    end

endtask

//compare data ------------
task compare ( logic [( DESER_W_T - 1 ):0] ref_queue [$],
                         logic [( DESER_W_T - 1 ):0] result_queue [$] );

logic [( DESER_W_T - 1 ):0] result;
logic [( DESER_W_T - 1 ):0] ref_result;

while( result_queue.size() != 0 )
  begin
    if( ref_queue.size() == 0 )
       $error("Extra data from DUT");
    else
      begin
        result     = result_queue.pop_front();
        ref_result =  ref_queue.pop_front();	
		compare_queue_c = compare_queue_c + 1;
		$display( "%d, " , compare_queue_c );
		$display( "send %b, get %b " , ref_result,result  );
        if( result != ref_result )
          $error("Data mismatch");
      end
  end
endtask
  
logic [(DESER_W_T-1):0] value_1_t; 
  
initial
  begin
   #300; 
   flag_b = 0;
   compare_queue_c = 0;
   flag_send = 0;

   fork
      begin                                  // send
        for( int i = 0; i < ( 50 ); i++ )
          begin   
		   @(posedge clk)
		   $display( "send for------ " );
		   if( flag_send == 0 )
	           begin
                 value_1_t = $urandom;
                 send( value_1_t ); 
				 $display( "send for if------ " );
				 i--;
		       end
			 if( flag_send == 1 )
			   begin
			     data_i_t = 0;
               end				 
			   
		  end	
		#5000;
		flag_b = 1;
      end
      begin                                     //get
	    forever
          begin
              get(); 
			  if ( flag_b == 1 )
		        break;
		  end
      end		  
	join
	  begin
	    compare( ref_queue, result_queue );
	    $display( "end ------- " );
      end 
   #5000; 
   $stop;
  end  
  
  
deserializer #(
  .DESER_W ( DESER_W_T )
) DUT (
	.clk_i(clk),
	.srst_i(reset),

	.data_i(data_i_t),
	.data_val_i(data_val_i_t),

	.ser_data_o(ser_data_o_t),
	.ser_data_val(ser_data_val_t)
);
  
endmodule

