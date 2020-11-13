module fifo #(
  parameter DWIDTH     = 8,
  parameter AWIDTH_EXP = 3,
  parameter AWIDTH     = 2**AWIDTH_EXP,
  parameter SHOWAHEAD  = "ON"
)(
input clk_i,
input srst_i,

input [(DWIDTH-1):0]data_i,
input wrreq_i,
input rdreq_i,

output [(DWIDTH-1):0]q_o,
output empty_o,
output full_o,
output [(AWIDTH-1):0]usedw_o
);


logic [(DWIDTH-1):0] ram[(AWIDTH-1):0];       //mem
logic [(AWIDTH_EXP-1):0]index_ram_start;
logic [(AWIDTH_EXP-1):0]index_ram_end;
logic full_flag;
logic empty_flag;
//logic full_flag_prev;
//logic empty_flag_prev;
logic [(DWIDTH-1):0]q_o_tv;
logic [(AWIDTH_EXP-1):0]usedw_o_tv;

initial
  begin
	q_o_tv     <= 0;
	empty_flag <= 1;
	full_flag  <= 0;
  end
	
always_ff @( posedge clk_i )
  begin
  
   // full_flag = (set_q_to_x || set_q_to_x_by_empty)? 1'bX : 1'b1;
  // full_flag_prev  = full_flag;
   //empty_flag_prev = empty_flag;
	
    if(srst_i)
      begin
        q_o_tv          <= 0;
		index_ram_start <= 0;
		index_ram_end   <= 0;
		full_flag       <= 0;
		empty_flag      <= 1;
		usedw_o_tv      <= 0;
      end
	else
	  begin
	  
	    if( ( full_flag == 0 ) && ( wrreq_i == 1 ) )       //write
		  begin
		    ram[index_ram_end] <= data_i;
			index_ram_end      = index_ram_end + 1;
			if( usedw_o_tv >= 1 )
			  empty_flag         <= 0;
			if(( usedw_o_tv == ( AWIDTH - 1 ) ) && ( empty_flag == 0 ) && ( wrreq_i == 1 ))
			  full_flag <= 1;
			usedw_o_tv         = usedw_o_tv + 1;
		  end
		  /*
			if(( SHOWAHEAD == "ON" ) && ( empty_flag == 0 ))
			  if ( ( empty_flag == 0 ) && ( empty_flag_prev == 0 ) && ( rdreq_i == 1 ) && ( usedw_o_tv >=1) )
			    q_o_tv <= ram[index_ram_start + 1];	
			  else
			    q_o_tv <= ram[index_ram_start];
		  */
	    if( ( empty_flag == 0 ) && ( rdreq_i == 1 ) )
          begin
		    q_o_tv          <= ram[index_ram_start];
			index_ram_start = index_ram_start + 1;
			if( usedw_o_tv == 0 )
			  full_flag       <= 0;
			usedw_o_tv      = usedw_o_tv - 1;	
			if(( usedw_o_tv == 0 ) && ( full_flag == 0 ) && ( wrreq_i == 0 ) && ( rdreq_i == 1 ))
			  empty_flag <= 1;
		  end	  
		    
	  end
  end	



//assign q_o     = ( empty_flag )? 'bX : q_o_tv; 
assign q_o     = q_o_tv; 
assign empty_o = empty_flag;
assign full_o  = full_flag;
assign usedw_o = usedw_o_tv;
//assign q_o = ( SHOWAHEAD == "ON" )?   : tmp_q;

/*
    assign q = (set_q_to_x || set_q_to_x_by_empty)? {lpm_width{1'bX}} : tmp_q;
    assign full = (set_q_to_x || set_q_to_x_by_empty)? 1'bX : full_flag;
    assign empty = (set_q_to_x || set_q_to_x_by_empty)? 1'bX : empty_flag;
*/

////-------


////------




endmodule