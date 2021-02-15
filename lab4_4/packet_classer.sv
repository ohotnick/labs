
module packet_classer (
input clk_i,
input srst_i,

//Avalon-MM Slave
input [1:0]csr_address_i,
input csr_write_i,
input [31:0]csr_writedata_i,
input csr_read_i,

output [31:0]csr_readdata_o,
output csr_readdatavalid_o,
output csr_waitrequest_o,

//Avalon-ST Sink
input [63:0]ast_data_i,
input ast_valid_i,
input ast_startofpacket_i,
input ast_endofpacket_i,
input [2:0]ast_empty_i,

output ast_ready_o,

//Avalon-ST Source
input ast_ready_i,

output [63:0]ast_data_o,
output ast_valid_o,
output ast_startofpacket_o,
output ast_endofpacket_o,
output [2:0]ast_empty_o,
output ast_channel_o
);

//Avalon-MM
logic [31:0] ram[8:0];       //reg
logic [31:0]csr_readdata_o_tv;
logic csr_readdatavalid_o_tv;
logic csr_waitrequest_o_tv;

initial 
  begin
    ram[3] = 32b'01101000011001010110110001101100;  //hell h - 01101000
	ram[2] = 32b'01101111001011000111011101101111;  //o,wo
	ram[1] = 32b'01110010011011000110010000100001;  //rld!
	ram[0] = 32b'00000000000000000000000000000001;  //1-ON 2-OFF
  end

//Avalon-MM page 21 read
always_ff @( posedge clk_i )
  begin
    if(srst_i)
      begin
        csr_readdata_o_tv      <= 0;
        csr_readdatavalid_o_tv <= 0;
		csr_waitrequest_o_tv   <= 0;
      end
    else
	  begin
	    if( csr_readdatavalid_o_tv == 1 )
		  begin
		    csr_readdatavalid_o_tv <= 0;
		  end
	    else if( ( csr_read_i == 1 ) && ( csr_waitrequest_o_tv == 0 ) )
		  begin
		    csr_waitrequest_o_tv   <= 1;
			csr_readdata_o_tv      <= ram [csr_address_i];
			csr_readdatavalid_o_tv <= 0;
		  end
		else if( ( csr_waitrequest_o_tv == 1 ) && ( csr_read_i == 1 ) )
		  begin
		    csr_waitrequest_o_tv   <= 0;
			csr_readdatavalid_o_tv <= 1;
		  end
	  end
  end	

//Avalon-MM page 21 write
always_ff @( posedge clk_i )
  begin
    if(srst_i)
      begin
		
      end
    else
	  begin
	    if( ( csr_write_i == 1 ) && ( csr_waitrequest_o_tv == 0 ) )
		  begin
		    csr_waitrequest_o_tv <= 1;
		  end
		else if( ( csr_write_i == 1 ) && ( csr_waitrequest_o_tv == 1 ) )
		  begin
		    csr_waitrequest_o_tv <= 0;
			ram [csr_address_i]  <= csr_writedata_i;
		  end
		else if( ( csr_write_i == 0 ) && ( csr_waitrequest_o_tv == 1 ) && ( csr_read_i == 0 ) )
		  csr_waitrequest_o_tv <= 0;
	  end
  end
  
//Avalon-ST
logic flag_1;
logic flag_2;
logic flag_3;
logic flag_4;
logic flag_5;
logic flag_6_1;
logic flag_6_2;
logic flag_7_1;
logic flag_7_2;
logic flag_8_2;
logic flag_8_2;
logic ast_channel_o_tv;

// dataBitsPerSymbol = 8
  
//Avalon-ST page 50-52
always_ff @( posedge clk_i )
  begin
    if(srst_i)
      begin
		flag_1           <= 0;
		flag_2           <= 0;
		flag_3           <= 0;
		flag_4           <= 0;
		flag_5           <= 0;
		flag_6_1         <= 0;
		flag_6_2         <= 0;
		flag_7_1         <= 0;
		flag_7_2         <= 0;
		flag_8_1         <= 0;
		flag_8_2         <= 0;
		ast_channel_o_tv <= 0;
      end
    else
	  begin
	    if (( ast_valid_i == 1 ) && ( ast_ready_i == 1 ) && ( [0]ram[0] == 1 ))
		  begin
	      //mask 1
	        if( ( {ram[3],ram[2]} == ast_data_i ) && ( ast_endofpacket_i != 1 ) )
		      flag_1 <= 1;
	      	else
	    	  flag_1 <= 0;
            if (( flag_1 == 1 ) && ( ram[1] == [63:32]ast_data_i ))
	    	  begin
	    	    if(( ast_endofpacket_i == 1 ) && ( ast_empty_i <= 4 ))
		          ast_channel_o_tv <= 1;
			    if( ast_endofpacket_i == 0 )
    		      ast_channel_o_tv <= 1;
	    	  end
	        if( ast_endofpacket_i == 1 )
    		  begin
    		    flag_1           <= 0;
    			flag_2           <= 0;
	    		flag_3           <= 0;
		    	flag_4           <= 0;
			    flag_5           <= 0;
    			flag_6_1         <= 0;
	    		flag_6_2         <= 0;
		    	flag_7_1         <= 0;
			    flag_7_2         <= 0;
    			flag_8_1         <= 0;
	    		flag_8_2         <= 0;
		    	ast_channel_o_tv <= 0;
    	      end
	      //mask 2
	        if( ( {ram[3],[31:8]ram[2]} == [55:0]ast_data_i) && ( ast_endofpacket_i != 1 ) )
    		  flag_2 <= 1;
    		else
    		  flag_2 <= 0;
    		if (( flag_2 == 1 ) && ( {[7:0]ram[2],ram[1]} == [63:24]ast_data_i ))
	    	  begin
	    	    if(( ast_endofpacket_i == 1 ) && ( ast_empty_i <= 3 ))
	    	      ast_channel_o_tv <= 1;
	    		if( ast_endofpacket_i == 0 )
	    	      ast_channel_o_tv <= 1;
	    	  end
    	  //mask 3
	        if( ( {ram[3],[31:16]ram[2]} == [47:0]ast_data_i) && ( ast_endofpacket_i != 1 ) )
	    	  flag_3 <= 1;
    		else
	    	  flag_3 <= 0;
	    	if (( flag_3 == 1 ) && ( {[15:0]ram[2],ram[1]} == [63:16]ast_data_i ))
	    	  begin
	    	    if(( ast_endofpacket_i == 1 ) && ( ast_empty_i <= 2 ))
	    	      ast_channel_o_tv <= 1;
	    		if( ast_endofpacket_i == 0 )
	    	      ast_channel_o_tv <= 1;
	    	  end
	      //mask 4
	    	if( ( {ram[3],[31:24]ram[2]} == [39:0]ast_data_i) && ( ast_endofpacket_i != 1 ) )
	    	  flag_4 <= 1;
	    	else
	    	  flag_4 <= 0;
	    	if (( flag_4 == 1 ) && ( {[7:0]ram[2],ram[1]} == [63:8]ast_data_i ))
	    	  begin
	    	    if(( ast_endofpacket_i == 1 ) && ( ast_empty_i <= 1 ))
	    	      ast_channel_o_tv <= 1;
	    		if( ast_endofpacket_i == 0 )
		          ast_channel_o_tv <= 1;
		      end
	      //mask 5
	    	if( ( ram[3] == [31:0]ast_data_i) && ( ast_endofpacket_i != 1 ) )
	    	  flag_5 <= 1;
	    	else
	    	  flag_5 <= 0;
	    	if (( flag_5 == 1 ) && ( {ram[2],ram[1]} == ast_data_i ))
	    	  begin
		        if(( ast_endofpacket_i == 1 ) && ( ast_empty_i == 0 ))
		          ast_channel_o_tv <= 1;
		    	if( ast_endofpacket_i == 0 )
		          ast_channel_o_tv <= 1;
		      end
    	  //mask 6
	    	if( ( flag_6_1 == 1 ) &&( {[7:0]ram[3],ram[2],[31:8]ram[1]} == ast_data_i) && ( ast_endofpacket_i != 1 ) )
	    	  flag_6_2 <= 1;
	    	else
	    	  flag_6_2 <= 0;
		  
	    	if( ( [31:8]ram[3] == [23:0]ast_data_i) && ( ast_endofpacket_i != 1 ) )
	    	  flag_6_1 <= 1;
	    	else
	    	  flag_6_1 <= 0;  
		  
	    	if (( flag_6_2 == 1 ) && ( [7:0]ram[1] == [63:56]ast_data_i ))
	    	  begin
	    	    if(( ast_endofpacket_i == 1 ) && ( ast_empty_i <= 7 ))
	    	      ast_channel_o_tv <= 1;
	    		if( ast_endofpacket_i == 0 )
	    	      ast_channel_o_tv <= 1;
	    	  end
	      //mask 7
	        if( ( flag_7_1 == 1 ) &&( {[15:0]ram[3],ram[2],[31:16]ram[1]} == ast_data_i) && ( ast_endofpacket_i != 1 ) )
	    	  flag_7_2 <= 1;
	    	else
		      flag_7_2 <= 0;
		  
	    	if( ( [31:16]ram[3] == [15:0]ast_data_i) && ( ast_endofpacket_i != 1 ) )
	    	  flag_7_1 <= 1;
	    	else
	    	  flag_7_1 <= 0;  
		  
	    	if (( flag_7_2 == 1 ) && ( [15:0]ram[1] == [63:48]ast_data_i ))
		      begin
		        if(( ast_endofpacket_i == 1 ) && ( ast_empty_i <= 6 ))
		          ast_channel_o_tv <= 1;
		    	if( ast_endofpacket_i == 0 )
		          ast_channel_o_tv <= 1;
	      //mask 8
	        if( ( flag_8_1 == 1 ) &&( {[23:0]ram[3],ram[2],[31:24]ram[1]} == ast_data_i) && ( ast_endofpacket_i != 1 ) )
	    	  flag_8_2 <= 1;
	    	else
	    	  flag_8_2 <= 0;
		  
	    	if( ( [31:24]ram[3] == [7:0]ast_data_i) && ( ast_endofpacket_i != 1 ) )
	    	  flag_8_1 <= 1;
		    else
		      flag_8_1 <= 0;  
		  
		    if (( flag_8_2 == 1 ) && ( [23:0]ram[1] == [63:40]ast_data_i ))
		      begin
		        if(( ast_endofpacket_i == 1 ) && ( ast_empty_i <= 5 ))
		          ast_channel_o_tv <= 1;
		    	if( ast_endofpacket_i == 0 )
		          ast_channel_o_tv <= 1;
		  end
		else if ( [0]ram[0] == 1 )
		  ast_channel_o_tv <= 1;
		  //
	  end
  end
  
logic ast_ready_o_tv;
logic ast_valid_o_tv;
logic [63:0]ast_data_o_tv;
logic ast_startofpacket_o_tv;
logic ast_endofpacket_o_tv;
logic [2:0]ast_empty_o_tv;
  
//value

always_ff @( posedge clk_i )
  begin
    if(srst_i)
      begin
		ast_ready_o_tv <= 0;
      end
    else
	  begin
	    if( ast_ready_i == 0 )
		  ast_ready_o_tv <= 0;
		else
		  ast_ready_o_tv <= 1;
	  end
  end
  
always_ff @( posedge clk_i )
  begin
    if(srst_i)
      begin
		ast_valid_o_tv <= 0;
		ast_data_o_tv  <= 0;
      end
    else
	  begin
	    if( ast_ready_i == 1 )
		  begin
		    if( ast_valid_i == 1 )
		      begin
			    ast_valid_o_tv <= 1;
				ast_data_o_tv  <= ast_data_i;
				if( ast_startofpacket_i == 1 )
				  ast_startofpacket_o_tv <= 1;
				else
				  ast_startofpacket_o_tv <= 0;
				if( ast_endofpacket_i == 1)
				  begin
				    ast_endofpacket_o_tv <= 1;
					ast_empty_o_tv       <= ast_empty_i;
				  end
				else
				  ast_endofpacket_o_tv <= 0;
			  end
			else
			  begin
			    ast_valid_o_tv         <= 0;
				ast_startofpacket_o_tv <= 0;
				ast_endofpacket_o_tv   <= 0;
			  end
		  end
		else
		  begin
		    ast_startofpacket_o_tv <= 0;
			ast_endofpacket_o_tv   <= 0;
		  end
	  end
  end

assign csr_readdata_o      = csr_readdata_o_tv;
assign csr_readdatavalid_o = csr_readdatavalid_o_tv;
assign csr_waitrequest_o   = csr_waitrequest_o_tv;
assign ast_channel_o       = ast_channel_o_tv;
assign ast_ready_o         = ast_ready_o_tv;
assign ast_valid_o         = ast_valid_o_tv;
assign ast_data_o          = ast_data_o_tv;
assign ast_empty_o         = ast_empty_o_tv;
assign ast_endofpacket_o   = ast_endofpacket_o_tv;
assign ast_startofpacket_o = ast_startofpacket_o_tv;


////------
endmodule