module top_tb3;
bit    clk;
bit    reset;
 
initial 
	forever 
		#100 clk=!clk;
		
parameter DESER_W_T = 16;

logic [15:0]data_i_t_s;		//in data
logic [4:0] data_mod_i_t_s;  //count of valid bit, >=3
logic data_val_i_t_s;

logic ser_data_o_t_s;			//out data ser
logic ser_data_val_t_s;		    //out valid ser
logic busy_o_t_s;				//out busy ser

logic [DESER_W_T-1:0] ser_data_o_t_ds; //out data dser
logic ser_data_val_t_ds;             //out valid ser

//clk
initial
  begin
    @(posedge clk)
    begin
    reset<=1'b1;
    end
    @(posedge clk)
    reset<=1'b0;
  end
  

 
logic flag_b;

logic [15:0] ref_queue [$];									
logic [15:0] result_queue [$];
int compare_queue_c;

// send data ------------
task send ( logic [15:0] value_1, logic [4:0] value_2 );

    @(posedge clk)
    data_i_t_s     = value_1;
	data_mod_i_t_s = value_2;
	data_val_i_t_s = 1;
	  
	@(posedge clk)
	data_val_i_t_s = 0;
	
	ref_queue.push_back( value_1 );  
    $display( "send %b, valid %d", value_1, value_2 );

endtask

// get data ---------
task get (  );

  @(posedge clk)

	if( ser_data_val_t_ds == 1 )
      begin
	    result_queue.push_back( ser_data_o_t_ds );
	    $display( "get  %b" , ser_data_o_t_ds );
		
	  end

endtask

//compare data ------------
task compare ( logic [15:0] ref_queue [$],
                         logic [15:0] result_queue [$] );

logic [15:0] result;
logic [15:0] ref_result;

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
  
logic [15:0] value_1_t; 
logic [4:0] value_2_t; 
  
  
initial
  begin
   #300; 
   flag_b = 0;
   value_2_t = 0;
   compare_queue_c = 0;

   fork
      begin                                  // send
        for( int i = 0; i < ( 20 ); i++ )
          begin   
		   if( data_mod_i_t_s >= 3 )
			 @(negedge busy_o_t_s)
	           begin
                 value_1_t = $urandom%65535;
			    //value_1_t = 65535;
		         //value_2_t = $urandom%16;
				 value_2_t = 16;
                 send( value_1_t, value_2_t ); 
		       end
			else
              begin			
	            @(posedge clk)
	            @(posedge clk)
				@(posedge clk)
                value_1_t = 65535;
		        //value_2_t = $urandom%16;
				value_2_t = 16;
                send( value_1_t, value_2_t ); 
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

  
  
serializer DUT (
	.clk_i ( clk ),
	.srst_i( reset),

	.data_i    ( data_i_t_s ),
	.data_mod_i( data_mod_i_t_s ),
	.data_val_i( data_val_i_t_s ),

	.ser_data_o  ( ser_data_o_t_s ),
	.ser_data_val( ser_data_val_t_s ),
	.busy_o      ( busy_o_t_s )
);

deserializer #(
  .DESER_W ( DESER_W_T )
) DUT2 (
	.clk_i ( clk ),
	.srst_i( reset ),

	.data_i    ( ser_data_o_t_s ),
	.data_val_i( ser_data_val_t_s ),

	.ser_data_o  ( ser_data_o_t_ds ),
	.ser_data_val( ser_data_val_t_ds )
);
  
endmodule

