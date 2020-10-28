module deserializer #(
  parameter DESER_W = 16
)(
input clk_i,
input srst_i,

input data_i,
input data_val_i,

output [DESER_W-1:0] ser_data_o,
output ser_data_val
);


logic [DESER_W-1:0] ser_data_o_p;
logic ser_data_val_p;
logic [($clog2(DESER_W)+1):0] cnt;
logic flag;

logic data_i_tv;
logic data_val_i_tv;

/*
always_ff @( posedge clk_i )
begin
  
  data_i_tv     <= data_i;
  data_val_i_tv <= data_val_i;
  
  if(srst_i)                    //если сброс
    begin
      cnt            <= 0;
      flag           <= 0;
      ser_data_val_p <= 0;
      ser_data_o_p   <= 0;
      data_i_tv      <= 0;
      data_val_i_tv  <= 0;
    end
  else
    begin  //else
        
    if(flag!=1)
     begin
       cnt  <= 0;
       flag <= 1;
       ser_data_val_p <= 0;
       ser_data_o_p   <= 0;
     end 
    else
      begin
        if( data_val_i_tv == 1 )
          begin 
            cnt <= cnt + 1'b1;
            ser_data_o_p[DESER_W - cnt -1] <= data_i_tv;
    
            if(cnt==(DESER_W-1))
              begin
                ser_data_val_p <= 1;
                flag           <= 0;
              end
          end
      end
    end     

end  */   

always_ff @( posedge clk_i )
begin
  if(srst_i)                    
    begin
      cnt            <= 0;
    end

  else
    begin  
      if(flag!=1)
        begin
         cnt  <= 0;
        end 
      else
        begin
          if( data_val_i_tv == 1 )
            begin 
              cnt <= cnt + 1'b1;
            end
        end
    end     
end    


always_ff @( posedge clk_i )
begin
  data_val_i_tv <= data_val_i;
  if(srst_i)                    
    begin
      flag           <= 0;
      data_val_i_tv  <= 0;
    end

  else
    begin     
      if(flag!=1)
        begin
          flag <= 1;
        end 
      else
        begin
          if( data_val_i_tv == 1 )
            begin 
              if(cnt==(DESER_W-1))
                begin
                  flag           <= 0;
                end
            end
        end
    end     
end   


always_ff @( posedge clk_i )
begin
  data_i_tv     <= data_i;
  if(srst_i)                    
    begin
      ser_data_val_p <= 0;
      ser_data_o_p   <= 0;
      data_i_tv      <= 0;
    end

  else
    begin         
      if(flag!=1)
        begin
         ser_data_val_p <= 0;
         ser_data_o_p   <= 0;
        end 
      else
        begin
          if( data_val_i_tv == 1 )
            begin 
              ser_data_o_p[DESER_W - cnt -1] <= data_i_tv;
              if(cnt==(DESER_W-1))
                begin
                  ser_data_val_p <= 1;
                end
            end
        end
    end     
end    

        assign ser_data_o   = ser_data_o_p;
        assign ser_data_val = ser_data_val_p;


endmodule