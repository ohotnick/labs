module priority_encoder #(
  parameter WIDTH = 5
)(
  input clk_i,
  input srst_i,

  input  [WIDTH-1:0] data_i,

  output [WIDTH-1:0] data_left_o,
  output [WIDTH-1:0] data_right_o
);

logic [WIDTH-1:0] data_i_tv;
logic [WIDTH-1:0] data_left_o_tv;
logic [WIDTH-1:0] data_right_o_tv;


always_ff @( posedge clk_i )		
  begin
    if(srst_i)
      begin
        data_i_tv <= 0;
      end
    else									
      begin
        data_i_tv <= data_i;
      end   
  end   


always_comb	                     				
  begin
  
    for( int i = 0; i < ( WIDTH ); i++ )     //left bit
      if( data_i_tv[ i ] )
	    begin
		  data_left_o_tv      = 0;
          data_left_o_tv[ i ] = 1;
		end
    if( data_i_tv == 0 )
      data_left_o_tv = 0;	

    for( int j = 0; j < ( WIDTH ); j++ )     //right bit
      if( data_i_tv[ WIDTH - j - 1 ] )
	    begin
		  data_right_o_tv = 0;
          data_right_o_tv[ WIDTH - j - 1  ] = 1;
		end
    if( data_i_tv == 0 )
      data_right_o_tv = 0;

  end


assign data_left_o  = data_left_o_tv;
assign data_right_o = data_right_o_tv;

endmodule