module top_tb6;

bit clk;
bit reset;
 
parameter WIDTH = 5; 

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
 
 /*
initial
  begin
    #300; 
    @( posedge clk )
      begin
        data_i_t     <= 5'b00100;  
        data_val_i_t <= 1; 
	  end   
    @( posedge clk )   
      begin
	    $display( "input  1data: %b"  , data_i_t     );
	    $display( "input  valid: %b"  , data_val_i_t );
	  end
    @( posedge clk )
      begin
        data_i_t     <= 5'b10101;  
        data_val_i_t <= 1;   
	  end  
    @( posedge clk )
      begin
	    $display( "output  data:%d"    , data_o_t     );
	    $display( "output valid: %b\n" , data_val_o_t );
	  
	    $display( "input  2data: %b"   , data_i_t     );
	    $display( "input  valid: %d"   , data_val_i_t );
	  end
    @( posedge clk )
      begin
        data_i_t     <= 5'b00100;  
        data_val_i_t <= 0;
	  end  
    @( posedge clk )
      begin
	    $display( "output  data:%d"    , data_o_t     );
	    $display( "output valid: %b\n" , data_val_o_t );
	  
	    $display( "input  3data: %b"   , data_i_t     );
	    $display( "input  valid: %d"   , data_val_i_t );
	  end
    @( posedge clk )
      begin
        data_i_t     <= 5'b11111;  
        data_val_i_t <= 1;
	  end  
	@( posedge clk )
	  begin
	    $display( "output  data:%d"    , data_o_t     );
	    $display( "output valid: %b\n" , data_val_o_t );
	  
	    $display( "input  4data: %b"   , data_i_t     );
	    $display( "input  valid: %d"   , data_val_i_t );
	  end	
	@( posedge clk )
	@( posedge clk )
	  begin
	    $display( "output  data:%d"    , data_o_t     );
	    $display( "output valid: %b\n" , data_val_o_t );
	  end

  end 
*/  
  //-----------------------------
logic [WIDTH-1:0] ref_queue [$];
logic [WIDTH-1:0] result_queue [$];

task send ( logic [WIDTH-1:0] value );

  @( posedge clk );
  data_val_i_t   <= 1'b1;
  data_i_t       <= value;
  ref_queue.push_back( value );
  
endtask


task get ( );

  @( posedge clk );
  if( data_val_o_t )
    result_queue.push_back( data_o_t );
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
        result = result_queue.pop_front();
        ref_result = $countones( ref_queue.pop_front() );
        if( result != ref_result )
          $error("Data mismatch");
      end
  end
endtask

//выполнение параллельно тасков и дожидается пока одини выполнятся чтоб выполнить compare
initial
  begin
  #300
		//$monitor( "output  data:%d"    , data_o_t     );
	   // $display( "output valid: %b\n" , data_val_o_t );
	  
	    $monitor( "input  4data: %b \ninput  valid: %d \noutput  data:%d \noutput valid: %b\n\n"   , data_i_t, data_val_i_t, data_o_t, data_val_o_t );
	  //  $monitor( "input  valid: %d"   , data_val_i_t ); 
  
  
  
    fork
      begin
 //     for (int i = 0; i < WIDTH; i++)
        for (int i = 0; i < 4; i++)
          send( i );
      end
      begin
         forever
           get();
      end
    join_any
    compare( ref_queue, result_queue );
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

