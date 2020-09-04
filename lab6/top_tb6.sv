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

