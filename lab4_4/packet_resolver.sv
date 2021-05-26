
module packet_resolver (
input clk_i,
input srst_i,

//Avalon-ST Sink
input [63:0]ast_data_i,
input ast_valid_i,
input ast_startofpacket_i,
input ast_endofpacket_i,
input [2:0]ast_empty_i,
input ast_channel_i,

output ast_ready_o,

//Avalon-ST Source
input ast_ready_i,

output [63:0]ast_data_o,
output ast_valid_o,
output ast_startofpacket_o,
output ast_endofpacket_o,
output [2:0]ast_empty_o
);

parameter DWIDTH_T     = 64;
parameter AWIDTH_EXP_T = 11;
parameter SHOWAHEAD_T  = "ON";

logic wrreq_i_ff;
logic rdreq_i_ff;
logic empty_o_ff;
logic full_o_ff;
logic [10:0]usedw_o_ff;
logic srst_i_ff;
logic [63:0]ast_data_i_ff;


logic ast_ready_o_tv;
logic ast_valid_o_tv;
logic [63:0]ast_data_o_tv;
logic ast_startofpacket_o_tv;
logic ast_endofpacket_o_tv;
logic [2:0]ast_empty_o_tv;
logic flag_read;
logic flag_channel;
logic flag_SOP;
logic flag_startwork;


always_ff @( posedge clk_i )
  begin
    if(srst_i)
      begin
        srst_i_ff <= 1;
      end
    else
      begin
        if(( ( flag_channel == 0 )||( full_o_ff  == 1 ) )&&( flag_read == 1 ))
          begin
            srst_i_ff  <= 1;
            wrreq_i_ff <= 0;
          end
        else
          srst_i_ff <= 0;
      end
  end
  

  
fifo     #(
            .DWIDTH     (DWIDTH_T),
            .AWIDTH_EXP (AWIDTH_EXP_T),
            .SHOWAHEAD  (SHOWAHEAD_T)
        )     fifoshka_1 (
                .clk_i   (clk_i),
                .srst_i  (srst_i_ff),
                .data_i  (ast_data_i_ff),
                .wrreq_i (wrreq_i_ff),
                
                .rdreq_i ((ast_valid_o_tv == 1) ? ast_ready_i : 1'b0 ),
                .q_o     (ast_data_o_tv),
                .empty_o (empty_o_ff),
                .full_o  (full_o_ff),
                .usedw_o (usedw_o_ff)
                );

//value

always_ff @( posedge clk_i )
  begin
    if(srst_i)
      begin
        ast_ready_o_tv     <= 0;
      end
    else
      begin
        if(( flag_read == 1 )||(( ast_endofpacket_i == 1 )&&( ast_valid_i == 1 )))
          ast_ready_o_tv   <= 0;
        else
          if( flag_read == 0 ) 
            ast_ready_o_tv <= 1;
      end
  end
  
always_ff @( posedge clk_i )
  begin
    if(srst_i)
      begin
        rdreq_i_ff     <= 0;
        wrreq_i_ff     <= 0;
        flag_read      <= 0;
        flag_channel   <= 0;
        ast_valid_o_tv <= 0;
        flag_SOP       <= 0;
        flag_startwork <= 0;
        
        ast_empty_o_tv <= 0;
        ast_endofpacket_o_tv <= 0;
        ast_startofpacket_o_tv <= 0;
      end
    else
      begin
      
        if( flag_read == 0 )
          begin                                                        // flag_read in fifo
            if( ast_valid_i == 1 )
              begin
                if((ast_startofpacket_i)||( flag_startwork ==1 ))
                  begin
                    wrreq_i_ff     <= 1;
                    flag_startwork <= 1;
                  end
                ast_valid_o_tv <= 0;
                ast_data_i_ff  <= ast_data_i;
                if((( ast_endofpacket_i == 1 )||( full_o_ff == 1 ))&&( flag_startwork ==1 ))
                  begin
                    ast_empty_o_tv <= ast_empty_i;
                    flag_read      <= 1;
                    flag_channel   <= ast_channel_i;
                    flag_startwork <= 0;
                  end
              end
            else
              begin
                wrreq_i_ff    <= 0;
                rdreq_i_ff    <= 0;
                ast_data_i_ff <= ast_data_i;
              end
          end                                                         // flag_read
        else if( flag_read == 1 ) //send package
          begin
            wrreq_i_ff <= 0;
            if(( ast_endofpacket_o_tv == 1 )&&( ast_ready_i == 1 ))
              begin
                flag_channel         <= 0;
                ast_endofpacket_o_tv <= 0;
                ast_valid_o_tv       <= 0;
                rdreq_i_ff           <= 0;
                wrreq_i_ff           <= 0;
              end
            else if(( flag_channel == 1 )&&( full_o_ff  == 0 ))
              begin 
                ast_valid_o_tv <= 1;
                
                if( flag_SOP == 0 )
                  begin
                    ast_startofpacket_o_tv <= 1;
                    flag_SOP               <= 1;    
                  end
                else if( ast_ready_i == 1 )
                  begin
                    ast_startofpacket_o_tv <= 0;
                  end
                
                if( ast_ready_i == 1 )
                  begin
                   
                    rdreq_i_ff <= 1;
                    
                    if(( usedw_o_ff <= 2 )||( empty_o_ff == 1 ))
                      begin
                        ast_endofpacket_o_tv <= 1;
                      end
                                        
                  end
                else
                  begin
                    rdreq_i_ff             <= 0;
                  end
              end
            else if(( flag_channel == 0 )||( full_o_ff  == 1 )) //check fifo and channel
              begin
                flag_SOP       <= 0;
                ast_valid_o_tv <= 0;
                rdreq_i_ff     <= 0;
                wrreq_i_ff     <= 0;
                
                ast_endofpacket_o_tv   <= 0;
                flag_channel           <= 0;
                
                if(srst_i_ff == 1)
                  flag_read <= 0;
              end
              
          end
          
          
          
      end
  end

assign ast_ready_o         = (( flag_read == 0 )&&( ast_startofpacket_i == 1 )&&( ast_valid_i == 1 )) ? 1'b1 : ast_ready_o_tv;

assign ast_valid_o         = ast_valid_o_tv;
assign ast_data_o          = ast_data_o_tv;
assign ast_empty_o         = ast_empty_o_tv;
assign ast_endofpacket_o   = ast_endofpacket_o_tv;
assign ast_startofpacket_o = ast_startofpacket_o_tv;


////------
endmodule