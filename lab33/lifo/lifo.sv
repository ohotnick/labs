
module lifo #(
  parameter DWIDTH     = 8,
  parameter AWIDTH_EXP = 3,
  parameter AWIDTH     = 2**AWIDTH_EXP
)(
input clk_i,
input srst_i,

input [(DWIDTH-1):0]data_i,
input wrreq_i,
input rdreq_i,

output [(DWIDTH-1):0]q_o,
output empty_o,
output full_o,
output [(AWIDTH_EXP-1):0]usedw_o
);

logic [(DWIDTH-1):0] ram[(AWIDTH-1):0];       //mem
logic [(AWIDTH_EXP-1):0]index_ram_wr;
logic [(AWIDTH_EXP-1):0]index_ram_rd;
logic full_flag;
logic empty_flag;
logic [(DWIDTH-1):0]q_o_tv;
logic [(AWIDTH_EXP-1):0]usedw_o_tv;

logic [1:0]count_empt;
/*
initial
  begin
    q_o_tv     <= 0;
    empty_flag <= 1;
    full_flag  <= 0;
    usedw_o_tv <= 0;
    count_empt <= 0;
  end
*/
//------------------

always_ff @( posedge clk_i )
  begin 
    if(srst_i)
      begin
        q_o_tv          <= 0;
      end
    else
      begin
         if(( empty_flag == 0 ) && ( rdreq_i == 1 ) && ( wrreq_i == 0 ))
         begin
            q_o_tv <= ram[index_ram_rd];
           //$display( "index %d q_o=%d" , index_ram_wr, q_o_tv );
          end
      end 
  end
  
always_ff @( posedge clk_i )
  begin 
    if(srst_i)
      begin
        index_ram_wr <= 0;
		index_ram_rd <= 0;
      end
    else
      begin
        if(( full_flag == 0 ) && ( wrreq_i == 1 )&& ( rdreq_i == 0 ))       //write
          begin   
            
            ram[index_ram_wr] <= data_i;
            //$display( "index %d data_i=%d" , index_ram_wr, data_i );
            if(index_ram_wr != (AWIDTH-1))
			  begin
                index_ram_wr <= index_ram_wr + 1;
				if(index_ram_wr != 0)
				  index_ram_rd <= index_ram_rd + 1;
			  end
			else  
              begin
			    index_ram_wr <= index_ram_wr;
				index_ram_rd <= index_ram_rd;
			  end
			if(index_ram_wr == (AWIDTH-1))
              index_ram_rd <= index_ram_rd + 1;  
			  
          end
        else if( ( empty_flag == 0 ) && ( rdreq_i == 1 )&& ( wrreq_i != 1 ))
           if(index_ram_rd != 0)
		     begin
			   if(index_ram_rd != (AWIDTH-1))
                 index_ram_wr <= index_ram_wr - 1;
			   index_ram_rd <= index_ram_rd - 1; 
			 end
		   else
		     begin
			   if(index_ram_rd == 0)
			     index_ram_wr <= index_ram_wr - 1; 
			   
			   index_ram_wr <= index_ram_wr;
			   index_ram_rd <= index_ram_rd; 
             end			   
      end 
  end

always_ff @( posedge clk_i )
  begin 
    if(srst_i)
      begin
        usedw_o_tv <= 0;
      end
    else
      begin
          
         if(( full_flag == 0 ) && ( wrreq_i == 1 )&& ( rdreq_i != 1 ))       //write &&( usedw_o_tv <(AWIDTH-1))
          usedw_o_tv <= usedw_o_tv + 1;
          else if(( empty_flag == 0 ) && ( rdreq_i == 1 )&& ( wrreq_i != 1 ))
          usedw_o_tv <= usedw_o_tv - 1;
          else if(( empty_flag == 1 ) && ( wrreq_i == 1 ))
          usedw_o_tv <= usedw_o_tv + 1;
          else 
          usedw_o_tv <= usedw_o_tv;
        
      end 
  end 
  
always_ff @( posedge clk_i )
  begin 
    if(srst_i)
      begin
        full_flag  <= 0;
        empty_flag <= 1;
        count_empt <= 0;
      end
    else
      begin
      
          if(usedw_o_tv == 0)
          count_empt <= 0;
          else if(usedw_o_tv >= 1)
          count_empt <= count_empt + 1;
          
          
        if(( full_flag == 0 ) && (usedw_o_tv >= 1))       //write
          begin
                if( count_empt >= 0 )
                  empty_flag         <= 0;
            if(( usedw_o_tv == ( AWIDTH - 1 ) ) && ( empty_flag == 0 ) && ( wrreq_i == 1 )&& ( rdreq_i != 1 ))
              full_flag <= 1;
          end
        if(( empty_flag == 0 ) && ( rdreq_i == 1 )&& ( wrreq_i == 0 ))
          begin
            if(( usedw_o_tv == ( AWIDTH - 1 ) ) && ( rdreq_i == 1 ))
              full_flag       <= 0;
            if(( usedw_o_tv == 1 ) && ( full_flag == 0 ) && ( wrreq_i == 0 ) && ( rdreq_i == 1 ))
              empty_flag <= 1;
          end
      end 
  end 
  
//assign q_o     = q_o_tv; 
assign q_o     = (( wrreq_i == 1 ) && ( rdreq_i == 1 ))? 'X : q_o_tv;
assign empty_o = empty_flag;
assign full_o  = full_flag;
assign usedw_o = usedw_o_tv;

////------
endmodule