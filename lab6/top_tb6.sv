module top_tb6;

bit clk;
bit reset;
 
parameter WIDTH  = 5;
parameter AN_VAR = 0; //another variant 0 - data_val_i_t const/ 1 - data_val_i_t vary

logic [WIDTH-1:0]           data_i_t;                      //data in
logic                       data_val_i_t;

logic [($clog2(WIDTH)+1):0] data_o_t;			 //out
logic                       data_val_o_t;	

initial 
  forever 
    #100 clk =! clk;

initial
  begin
    @( posedge clk )
      reset <= 1'b1;	  
    @( posedge clk )
      reset <= 1'b0;
  end
  
  //-----------------------------
logic [WIDTH-1:0] ref_queue [$];
logic [WIDTH-1:0] result_queue [$];

logic [WIDTH:0] ref_queue_c;
logic [WIDTH:0] result_queue_c;
logic [WIDTH:0] compare_queue_c;
logic bbb1;

task send ( logic [WIDTH-1:0] value );

  @( posedge clk );
  if ( AN_VAR == 0 )
  data_val_i_t   = 1'b1;
  else
    begin
      if( value & 1 )
        data_val_i_t   = 1'b1;
      else
        data_val_i_t   = 1'b0;
    end
  data_i_t       = value;
  if( data_val_i_t )
  begin
    ref_queue.push_back( value );
    ref_queue_c = ref_queue_c + 1;
	$display( "ref_queue N%d: %b\n" , ref_queue_c, value );
  end	
endtask


task get ( );
  
  @( posedge clk );
  if( data_val_o_t && ( ref_queue_c != result_queue_c ) )
  begin
    result_queue.push_back( data_o_t );
	result_queue_c = result_queue_c + 1;
	$display( "result_queue N%d: %d\n" , result_queue_c, data_o_t );
  end	
  
endtask


task compare ( logic [WIDTH-1:0] ref_queue [$],
                         logic [WIDTH-1:0] result_queue [$] );

logic [WIDTH-1:0] result;
logic [WIDTH-1:0] ref_result;

while( result_queue.size() != 0 )
  begin
    if( ref_queue.size() == 0 )
       $error("Extra data from DUT");
    else
      begin
        result     = result_queue.pop_front();
        ref_result = $countones( ref_queue.pop_front() );
		compare_queue_c = compare_queue_c + 1;
		$display( "%d, " , compare_queue_c );
        if( result != ref_result )
          $error("Data mismatch");
      end
  end
endtask

initial
  begin
    #500
    $monitor( "input  data: %b \ninput  valid N%d: %d \noutput  data:%d \noutput valid N%d: %b\n\n"   , data_i_t, ref_queue_c , data_val_i_t, data_o_t, result_queue_c , data_val_o_t );
    ref_queue_c     = 0;
    result_queue_c  = 0;
    compare_queue_c = 0;
    bbb1 = 0;
	
    fork
      begin
        forever
          begin
            get();
		    if ( bbb1 == 1 && (result_queue_c == ref_queue_c))
		      break;
		  end  
      end	
      begin
        for (int i = 0; i < 2**WIDTH; i++)
		  begin
            send( i );
          end   
		  bbb1 = 1;  
      end
	join
	  begin
	    $display( "compare_queue_c: " );
        compare( ref_queue, result_queue );
      end
	
	$display( "get, send, compare: %d,%d ,%d  \n" , result_queue_c, ref_queue_c, compare_queue_c);
  end
  
  


  
  //-----------------------------
bit_population_counter DUT 
/*#(
	.WIDTH (5),

)*/
(
	.clk_i      ( clk          ),
	.srst_i     ( reset        ),

	.data_i     ( data_i_t     ),
	.data_val_i ( data_val_i_t ),

	.data_o     ( data_o_t     ),
	.data_val_o ( data_val_o_t )
);
  
endmodule

