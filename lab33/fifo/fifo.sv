// module similar to altera with parameters( Mode:Normal/Show-ahead. Optimization Option:Speed )

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
output [(AWIDTH_EXP-1):0]usedw_o
);

logic [(DWIDTH-1):0] ram[(AWIDTH-1):0];       //mem
logic [(AWIDTH_EXP-1):0]index_ram_start;
logic [(AWIDTH_EXP-1):0]index_ram_end;
logic full_flag;
logic empty_flag;
logic [(DWIDTH-1):0]q_o_tv;
logic [(AWIDTH_EXP-1):0]usedw_o_tv;

logic [1:0]count_empt;

initial
  begin
    q_o_tv     <= 0;
    empty_flag <= 1;
    full_flag  <= 0;
    usedw_o_tv <= 0;
    count_empt <= 0;
  end

//------------------

always_ff @( posedge clk_i )
  begin 
    if(srst_i)
      begin
        q_o_tv          <= 0;
      end
    else
      begin
      
        if(( empty_flag == 0 ) && ( SHOWAHEAD  == "ON" )&&( rdreq_i == 1 ))
          begin
            q_o_tv <= ram[index_ram_start + 1'b1];
            if( usedw_o_tv == 1 )
            q_o_tv <= ram[index_ram_start];
           end
         else if(( count_empt >= 1 ) && ( SHOWAHEAD  == "ON" ) && (usedw_o_tv >= 1))
           q_o_tv <= ram[index_ram_start];
        if(( empty_flag == 0 ) && ( rdreq_i == 1 ) && ( SHOWAHEAD  != "ON" ))
          q_o_tv <= ram[index_ram_start];

      end 
  end
  
always_ff @( posedge clk_i )
  begin 
    if(srst_i)
      begin
        index_ram_start <= 0;
        index_ram_end   <= 0;
      end
    else
      begin
        if(( full_flag == 0 ) && ( wrreq_i == 1 ))       //write
          begin
            ram[index_ram_end] <= data_i;
            index_ram_end      <= index_ram_end + 1;
          end
        if( ( empty_flag == 0 ) && ( rdreq_i == 1 ))
            index_ram_start <= index_ram_start + 1;     
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
          
         if(( full_flag == 0 ) && ( wrreq_i == 1 )&& ( rdreq_i != 1 ))       //write
          usedw_o_tv <= usedw_o_tv + 1;
          else if(( full_flag == 1 ) && ( wrreq_i == 1 )&& ( rdreq_i == 1 ))
           usedw_o_tv <= usedw_o_tv - 1;
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
            if( SHOWAHEAD  == "ON" )
              begin
                if( count_empt >= 1 )
                  empty_flag         <= 0;
              end
            else
              begin
                if( count_empt >= 0 )
                  empty_flag         <= 0;
              end
            if(( usedw_o_tv == ( AWIDTH - 1 ) ) && ( empty_flag == 0 ) && ( wrreq_i == 1 )&& ( rdreq_i != 1 ))
              full_flag <= 1;
          end
        if(( empty_flag == 0 ) && ( rdreq_i == 1 ))
          begin
            if( usedw_o_tv == 0 )
              full_flag       <= 0;
            if(( usedw_o_tv == 1 ) && ( full_flag == 0 ) && ( wrreq_i == 0 ) && ( rdreq_i == 1 ))
              empty_flag <= 1;
          end
      end 
  end 
  
assign q_o     = q_o_tv; 
assign empty_o = empty_flag;
assign full_o  = full_flag;
assign usedw_o = usedw_o_tv;

////------
endmodule