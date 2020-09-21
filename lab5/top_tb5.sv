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

logic [WIDTH-1:0] ref_queue [$];
logic [WIDTH-1:0] result_queue_l [$];
logic [WIDTH-1:0] result_queue_r [$];


task send ( logic [WIDTH-1:0] value );

  @( posedge clk )

  begin
    data_i_t = value;
    ref_queue.push_back( value );  
    send_c   = send_c + 1;
    $display( "send N%d:       %b" , send_c, value );
  end
  
endtask
  
  
task get ( );

  @( posedge clk )

  begin
    result_queue_l.push_back( data_left_o_t  );
    result_queue_r.push_back( data_right_o_t );
    get_c = get_c + 1;
    $display( "get N%d:   left %b\n          right %b \n" , get_c, data_left_o_t, data_right_o_t );	
  end
  
endtask


task compare ( logic [WIDTH-1:0] ref_queue [$],
               logic [WIDTH-1:0] result_queue_l [$],
			   logic [WIDTH-1:0] result_queue_r [$]);

logic [WIDTH-1:0] result_l;
logic [WIDTH-1:0] result_r;
logic [WIDTH-1:0] ref_result;
logic [WIDTH-1:0] ref_result_l;
logic [WIDTH-1:0] ref_result_r;

while( ( result_queue_l.size() != 0 ) || ( result_queue_r.size() != 0 ) )
  begin
    if( ref_queue.size() == 0 )
       $error("Extra data from DUT");
    else
      begin
        result_l = result_queue_l.pop_front();
        result_r = result_queue_r.pop_front();	
        
		ref_result =  ref_queue.pop_front();
//left-------------------------------------------------			
		for( int i = 0; i < ( WIDTH ); i++ )    				 
          if( ref_result[ i ] )
	        begin
		      ref_result_l      = 0;
              ref_result_l[ i ] = 1;
		    end
          if( ref_result == 0 )
            ref_result_l = 0;
//right-------------------------------------------------				
		for( int j = 0; j < ( WIDTH ); j++ )    				 
          if( ref_result[ j ] )
	        begin
		      ref_result_r      = 0;
              ref_result_r[ j ] = 1;
			  break;
		    end
          if( ref_result == 0 )
            ref_result_r = 0;
//compare------------------------------------------------
	  
        if( result_l != ref_result_l )
          $error("Data mismatch left result_l %b ref_result_l %b", result_l, ref_result_l );
		if( result_r != ref_result_r )
          $error("Data mismatch right result_r %b ref_result_r %b", result_r, ref_result_r );
      end
  end
endtask

 

initial
  begin
    #500 
    send_c = 0;
	get_c  = 0;
	flag_b = 0;
	
	fork

      begin
        for (int k = 0; k < 2**WIDTH; k++)
		  begin
            send( k );
          end 
		  @( posedge clk );
		  flag_b = 1;  
      end
      begin
	    @( posedge clk );
		@( posedge clk );
        forever
          begin
            get();
		    if ( flag_b == 1 )
		      break;
		  end  
      end		  
	  
	  
	join
	  begin
	    compare( ref_queue, result_queue_l, result_queue_r );
	    $display( "end ------- " );
      end
	  
  end	  
  
  
priority_encoder DUT 
/*#(
	.WIDTH (5)
)*/
(
	.clk_i        ( clk ),
	.srst_i       ( reset ),

	.data_i       ( data_i_t ),

	.data_left_o  ( data_left_o_t  ),
	.data_right_o ( data_right_o_t )
);
  
endmodule

