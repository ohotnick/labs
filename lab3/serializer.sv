module serializer (
  input clk_i,
  input srst_i,

  input [15:0]data_i,
  input [4:0] data_mod_i,
  input data_val_i,

  output ser_data_o,
  output ser_data_val,
  output busy_o
);

logic [15:0]data_i_tv;
logic [15:0]data_i_tv_1;
logic data_val_i_flag;
logic data_val_i_tv;
logic [4:0]data_mod_i_tv;
logic [4:0]cnt;

logic ser_data_o_p;
logic ser_data_val_p;
logic busy_o_p;



always_ff @( posedge clk_i )
  begin
    if( srst_i )                                     //reset
      begin
        data_val_i_flag   <= 1'b0;
        busy_o_p          <= 1'b0;
        data_i_tv         <= 0;
        ser_data_o_p      <= 1'b0;
        ser_data_val_p    <= 1'b0;
        data_mod_i_tv     <= 0;
      end
    else
      begin  //else
        data_mod_i_tv  <= data_mod_i;
        data_val_i_tv  <= data_val_i;
        data_i_tv_1    <= data_i;
    
        if( data_val_i_tv == 1'b1 && data_val_i_flag != 1'b1) //take data, start work
          begin
            data_i_tv <= data_i_tv_1;
            if( data_mod_i_tv >= 3 )
              begin
                data_val_i_flag <= 1'b1;
                cnt             <= 15 - data_mod_i_tv;
              end
          end

        if( data_val_i_flag == 1'b1 )                       //process
          begin
            busy_o_p       <= 1'b1;                             
            ser_data_val_p <= 1'b1;
        
            cnt <=cnt + 1'b1;
    
            ser_data_o_p <= data_i_tv[15];
            data_i_tv    <= data_i_tv << 1;
        
            if( cnt == 15 )                                 //end process
              begin
                busy_o_p        <= 1'b0;
                data_val_i_flag <= 1'b0;
                ser_data_o_p    <= 1'b0;
                ser_data_val_p  <= 1'b0;
              end
          end
        
      end       //else
  end       //always_ff


        assign ser_data_o   = ser_data_o_p;
        assign ser_data_val = ser_data_val_p;
        assign busy_o       = busy_o_p;







endmodule