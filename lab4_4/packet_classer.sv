
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
logic [31:0] bank_reg[8:0];       //bank_reg
logic [31:0]csr_readdata_o_tv;
logic csr_readdatavalid_o_tv;
logic csr_waitrequest_o_tv;
logic work_on;

/*
initial 
  begin
  
  logic [11:0][7:0] mem_data = "hello,world!";
  
  //bank_reg[3] = 32'b01101000011001010110110001101100;  //hell h - 01101000
 // bank_reg[3] = 32'b01101100011011000110010101101000;  //big endian
  //bank_reg[3] = "lleh";
  bank_reg[3] = mem_data[95:0] >> 64;  
  //bank_reg[2] = 32'b01101111001011000111011101101111;  //o,wo
  //bank_reg[2] = 32'b01101111011101110010110001101111;
  //bank_reg[2] = "ow,o";
  bank_reg[2] = mem_data[63:0] >> 32;
  //bank_reg[1] = 32'b01110010011011000110010000100001;  //rld!
  //bank_reg[1] = 32'b00100001011001000110110001110010; 
  //bank_reg[1] = "!dlr";
  bank_reg[1] = mem_data[31:0];
  bank_reg[0] = 32'b00000000000000000000000000000001;  //1-ON 2-OFF
  end
*/

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
            csr_readdata_o_tv      <= bank_reg [csr_address_i];
            csr_readdatavalid_o_tv <= 0;
          end
        else if( ( csr_waitrequest_o_tv == 1 ) )
          begin
            csr_waitrequest_o_tv   <= 0;
            csr_readdatavalid_o_tv <= 1;
          end
          
        //Avalon-MM page 21 write  
          if( ( csr_write_i == 1 ) && ( csr_waitrequest_o_tv == 0 ) )
          begin
            csr_waitrequest_o_tv <= 1;
          end
        else if( ( csr_waitrequest_o_tv == 1 ) )
          begin
            csr_waitrequest_o_tv <= 0;
            bank_reg [csr_address_i]  <= csr_writedata_i;
          end
          
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
logic flag_8_1;
logic flag_8_2;
logic ast_channel_o_tv;

  
logic ast_ready_o_tv;
logic ast_valid_o_tv;
logic [63:0]ast_data_o_tv;
logic ast_startofpacket_o_tv;
logic ast_endofpacket_o_tv;
logic [2:0]ast_empty_o_tv;

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
        work_on          <= bank_reg[0][0];
      end
    else
      begin
        
        work_on <= bank_reg[0][0];
        
        if(( ast_endofpacket_o_tv == 1 )&& ( ast_ready_i == 1 ) && ( work_on == 1 ))
               begin
                ast_channel_o_tv <= 0;
                //$display( "7)ast_channel_o_tv %d (if( ast_endofpacket_o_tv == 1 )), time %d ns ",ast_channel_o_tv , $time);
               end
        
        //if (( ast_valid_i == 1 ) && ( ast_ready_i == 1 ) && ( work_on == 1 ))
        if((( ast_valid_o_tv == 0 )&&( ast_valid_i == 1 )&&( ast_ready_o == 1 )||(( ast_valid_o_tv == 1 )&&( ast_ready_i == 1 )&&( ast_valid_i == 1 )))&& ( work_on == 1 ))
          begin
          //mask 1
          /*
          $display( "1)flag_1 %d, time %d ns ",flag_1 , $time);
          $display( "2)flag_2 %d, time %d ns ",flag_2 , $time);
          $display( "3)flag_3 %d, time %d ns ",flag_3 , $time);
          $display( "4)flag_4 %d, time %d ns ",flag_4 , $time);
          $display( "5)flag_5 %d, time %d ns ",flag_5 , $time);
          $display( "6_1)flag_6_1 %d, time %d ns ",flag_6_1 , $time);
          $display( "6-2)flag_6_2 %d, time %d ns ",flag_6_2 , $time);
          $display( "7_1)flag_7_1 %d, time %d ns ",flag_7_1 , $time);
          $display( "7_2)flag_7_2 %d, time %d ns ",flag_7_2 , $time);
          $display( "8_1)flag_8_1 %d, time %d ns ",flag_8_1 , $time);
          $display( "8_2)flag_8_2 %d, time %d ns ",flag_8_2 , $time);*/
          
          //$display( "7)flag_8_1 %d, time %d ns ",flag_8_1 , $time);
          //$display( "7)flag_8_2 %d, time %d ns ",flag_8_2 , $time);
          //$display( "5)ast_channel_o_tv %d, time %d ns ",ast_channel_o_tv , $time);
          
          //$display( "1)ast_endofpacket_o_tv       %b, time %d ns ",ast_endofpacket_o_tv , $time);
          //$display( "2)ast_data_i       %b, time %d ns ",ast_data_i , $time);
          //$display( "1)bank_reg[3][31:24]    %b, time %d ns ",bank_reg[3][31:24] , $time);
          
          //$display( "1)bank_reg[3]                                     %b, time %d ns ",bank_reg[3] , $time);
          
          
            if( ( bank_reg[3] == ast_data_i[31:0] ) && ( ast_endofpacket_i != 1 ) )
              flag_1 <= 1;
            else
              flag_1 <= 0;
            if (( flag_1 == 1 ) && ( {bank_reg[2],bank_reg[1]} == ast_data_i ))
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
                
              end

          //mask 2
            if( ( {bank_reg[3],bank_reg[2][31:24]} == ast_data_i[39:0]) && ( ast_endofpacket_i != 1 ) )
              flag_2 <= 1;
            else
              flag_2 <= 0;
            if (( flag_2 == 1 ) && ( {bank_reg[2][23:0],bank_reg[1]} == ast_data_i[63:8] ))
              begin
                if(( ast_endofpacket_i == 1 ) && ( ast_empty_i <= 3 ))
                  ast_channel_o_tv <= 1;
                if( ast_endofpacket_i == 0 )
                  ast_channel_o_tv <= 1;
              end
          //mask 3
            if( ( {bank_reg[3],bank_reg[2][31:16]} == ast_data_i[47:0]) && ( ast_endofpacket_i != 1 ) )
              flag_3 <= 1;
            else
              flag_3 <= 0;
            if (( flag_3 == 1 ) && ( {bank_reg[2][15:0],bank_reg[1]} == ast_data_i[63:16] ))
              begin
                if(( ast_endofpacket_i == 1 ) && ( ast_empty_i <= 2 ))
                  ast_channel_o_tv <= 1;
                if( ast_endofpacket_i == 0 )
                  ast_channel_o_tv <= 1;
              end
          //mask 4
            if( ( {bank_reg[3],bank_reg[2][31:8]} == ast_data_i[55:0]) && ( ast_endofpacket_i != 1 ) )
              flag_4 <= 1;
            else
              flag_4 <= 0;
            if (( flag_4 == 1 ) && ( {bank_reg[2][7:0],bank_reg[1]} == ast_data_i[63:24] ))
              begin
                if(( ast_endofpacket_i == 1 ) && ( ast_empty_i <= 1 ))
                  ast_channel_o_tv <= 1;
                if( ast_endofpacket_i == 0 )
                  ast_channel_o_tv <= 1;
              end
          //mask 5
            if( ( {bank_reg[3],bank_reg[2]} == ast_data_i) && ( ast_endofpacket_i != 1 ) )
              flag_5 <= 1;
            else
              flag_5 <= 0;
            if (( flag_5 == 1 ) && ( bank_reg[1] == ast_data_i[63:32] ))
              begin
                if(( ast_endofpacket_i == 1 ) && ( ast_empty_i == 0 ))
                  ast_channel_o_tv <= 1;
                if( ast_endofpacket_i == 0 )
                  ast_channel_o_tv <= 1;
              end
          //mask 6
            if( ( flag_6_1 == 1 ) &&( {bank_reg[3][23:0],bank_reg[2],bank_reg[1][31:24]} == ast_data_i) && ( ast_endofpacket_i != 1 ) )
              flag_6_2 <= 1;
            else
              flag_6_2 <= 0;
          
            if( ( bank_reg[3][31:24] == ast_data_i[7:0]) && ( ast_endofpacket_i != 1 ) )
              flag_6_1 <= 1;
            else
              flag_6_1 <= 0;  
          
            if (( flag_6_2 == 1 ) && ( bank_reg[1][23:0] == ast_data_i[63:40] ))
              begin
                if(( ast_endofpacket_i == 1 ) && ( ast_empty_i <= 7 ))
                  ast_channel_o_tv <= 1;
                if( ast_endofpacket_i == 0 )
                  ast_channel_o_tv <= 1;
              end
          //mask 7
            if( ( flag_7_1 == 1 ) &&( {bank_reg[3][15:0],bank_reg[2],bank_reg[1][31:16]} == ast_data_i) && ( ast_endofpacket_i != 1 ) )
              flag_7_2 <= 1;
            else
              flag_7_2 <= 0;
          
            if( ( bank_reg[3][31:16] == ast_data_i[15:0]) && ( ast_endofpacket_i != 1 ) )
              flag_7_1 <= 1;
            else
              flag_7_1 <= 0;  
          
            if (( flag_7_2 == 1 ) && ( bank_reg[1][15:0] == ast_data_i[63:48] ))
              begin
                if(( ast_endofpacket_i == 1 ) && ( ast_empty_i <= 6 ))
                  ast_channel_o_tv <= 1;
                if( ast_endofpacket_i == 0 )
                  ast_channel_o_tv <= 1;
              end
          //mask 8
            if( ( flag_8_1 == 1 ) &&( {bank_reg[3][7:0],bank_reg[2],bank_reg[1][31:8]} == ast_data_i) && ( ast_endofpacket_i != 1 ) )
              flag_8_2 <= 1;
            else
              flag_8_2 <= 0;
          
            if( ( bank_reg[3][31:8] == ast_data_i[23:0]) && ( ast_endofpacket_i != 1 ) )
              flag_8_1 <= 1;
            else
              flag_8_1 <= 0;  
          
            if (( flag_8_2 == 1 ) && ( bank_reg[1][7:0] == ast_data_i[63:56] ))
              begin
                if(( ast_endofpacket_i == 1 ) && ( ast_empty_i <= 5 ))
                  ast_channel_o_tv <= 1;
                if( ast_endofpacket_i == 0 )
                  ast_channel_o_tv <= 1;
              end
          end
        else if ( work_on == 0 )
          ast_channel_o_tv <= 1;
          //
      end
  end
  

  
//value


  
always_ff @( posedge clk_i )
  begin
    if(srst_i)
      begin
        ast_valid_o_tv <= 0;
        ast_data_o_tv  <= 0;
        ast_empty_o_tv <= 0;
        ast_ready_o_tv <= 1;
      end
    else
      begin
      //$display( "packet_classer: 1)ast_startofpacket_o %d, 2)ast_endofpacket_o %d 3)ast_ready_i %d, time %d ns ",ast_startofpacket_o,ast_endofpacket_o, ast_ready_i , $time);
      
      
      if(( ast_valid_o_tv == 0 )&&( ast_valid_i == 1 )&&( ast_ready_o == 1 ))
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
          if( ast_ready_i == 1 )
            ast_ready_o_tv <= 1;
          else
            ast_ready_o_tv <= 0;
        end
        
      else if(( ast_valid_o_tv == 1 )&&( ast_ready_i == 1 ))
        begin
          if( ast_valid_i == 1 )
            begin
              ast_valid_o_tv <= 1;
              ast_data_o_tv  <= ast_data_i;
              ast_ready_o_tv <= 1;
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
          else if ( ast_valid_i == 0 )
            begin
              ast_ready_o_tv         <= 1;
              ast_valid_o_tv         <= 0;
              ast_startofpacket_o_tv <= 0;
              ast_endofpacket_o_tv   <= 0;
            end
        end
          
      end
  end

assign csr_readdata_o      = csr_readdata_o_tv;
assign csr_readdatavalid_o = csr_readdatavalid_o_tv;
assign csr_waitrequest_o   = csr_waitrequest_o_tv;
assign ast_channel_o       = ast_channel_o_tv;
//assign ast_ready_o         = ast_ready_i;
assign ast_ready_o         = (( ast_valid_o_tv == 1 )&&( ast_ready_i == 0 ))? 1'b0 : ((( ast_valid_i == 1 )&&( ast_ready_i == 1 )) ? 1'b1: ast_ready_o_tv);
assign ast_valid_o         = ast_valid_o_tv;
assign ast_data_o          = ast_data_o_tv;
assign ast_empty_o         = ast_empty_o_tv;
assign ast_endofpacket_o   = ast_endofpacket_o_tv;
assign ast_startofpacket_o = ast_startofpacket_o_tv;


////------
endmodule