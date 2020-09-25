module debouncer #(
  parameter CLK_FREQ_MHZ = 20,
  parameter GLITCH_TIME_NS =50
)(
  input clk_i,

  input key_i,

  output key_pressed_stb_o
);

parameter CLK_TIME_NS = 1000/CLK_FREQ_MHZ;		
parameter WIDTH    = GLITCH_TIME_NS/CLK_TIME_NS;

logic key_pressed_stb_o_tv;
logic flag;
logic [($clog2(WIDTH)+1):0]data_o_c;		//counter




always_ff @( posedge clk_i )		
  begin
    if( key_i != 1 || key_i== 1 )
	  begin
        if( key_i == 0 && flag == 0 )
          begin
            flag                 <=1;
            data_o_c            <=0;
            key_pressed_stb_o_tv <=0;
          end 
        if( key_i == 0 )
          flag                 <=1;			  
	  end
	else
	  data_o_c            <=0;  

    if( flag== 1 && key_i == 1 )
      begin
        data_o_c <= data_o_c + 1;
      end 
	else
      if ( data_o_c >= 1)
	    data_o_c <= data_o_c + 1;
	  
    if( flag == 0 )
      key_pressed_stb_o_tv<=0;
    else
      begin
        if( data_o_c >= ( WIDTH ) )
          begin
            if( key_i == 1 )
			  begin
                key_pressed_stb_o_tv<=1;
                flag<=0;
			    data_o_c            <=0;
			  end
			else
    		  begin
                flag<=0;
			    data_o_c            <=0;
			  end
          end
      end
  end  



assign key_pressed_stb_o = key_pressed_stb_o_tv;

endmodule