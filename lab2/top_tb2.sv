module top_tb2;
bit    clk;
bit    reset;
 
initial 
    forever 
        #100 clk=!clk;

logic [15:0]data_i_t;       //in data
logic [3:0] data_mod_i_t;  //count of valid bit, >=3
logic data_val_i_t;

logic ser_data_o_t;         //out data
logic ser_data_val_t;       //out valid
logic busy_o_t;             //out busy


initial
  begin
    @(posedge clk)
    begin
    reset<=1'b1;
    end
    @(posedge clk)
    reset<=1'b0;
  end
  
logic [15:0] value_get; 
logic flag_b; 
logic flag_a;
int q;

logic [15:0] ref_queue [$];
logic [15:0] result_queue [$];
logic [15:0] ref_queue_temp;
int compare_queue_c;

// send data ------------
task send ( logic [15:0] value_1, logic [3:0] value_2 );

    @(posedge clk)
    data_i_t     = value_1;
    data_mod_i_t = value_2;
    data_val_i_t = 1;
    if ( value_2 >= 3 )
      begin
        ref_queue_temp = value_1;
        for( int t = 0; t < 16;  t++ )
          if( (( 15 - value_2 ) >= t ) && ( t >= 0 ) )
            ref_queue_temp[t] = ref_queue_temp[t] & 0;
      
        ref_queue.push_back( ref_queue_temp );
      end
      
    @(posedge clk)
    data_val_i_t = 0;
      
    $display( "send %b, valid %d", value_1, value_2 );

endtask

// get data ---------
task get (  );

    if( ser_data_val_t == 0 )
      begin
        if( flag_a == 1 )
          begin 
            $display( "get  %b" , value_get );
            //$display( "get time  %d" , $time );
            result_queue.push_back( value_get );
            flag_a = 0;
          end   
        q = 15;
        value_get = 0;
      end

      if( ser_data_val_t == 1 ) 
        begin
          flag_a = 1;
          $display( "get time  %d" , $time );
          value_get[ q ] = ser_data_o_t;
          q = q - 1;
        end

endtask

//compare data ------------
task compare ( logic [15:0] ref_queue [$],
                         logic [15:0] result_queue [$] );

logic [15:0] result;
logic [15:0] ref_result;

while( result_queue.size() != 0 )
  begin
    if( ref_queue.size() == 0 )
       $error("Extra data from DUT");
    else
      begin
        result     = result_queue.pop_front();
        ref_result =  ref_queue.pop_front();    
        compare_queue_c = compare_queue_c + 1;
        $display( "%d, " , compare_queue_c );
        $display( "send %b, get %b ", ref_result, result  );
        if( result != ref_result )
          $error("Data mismatch");
      end
  end
endtask
  
logic [15:0] value_1_t; 
logic [3:0] value_2_t; 
  
  
initial
  begin
   #300; 
   flag_b = 0;
   flag_a = 0;
   value_get = 0;
   q = 15;
   value_2_t = 0;
   compare_queue_c = 0;

   fork
      begin                                  // send
        for( int i = 0; i < ( 20 ); i++ )
          begin   
           if( data_mod_i_t >= 3 )
             @(negedge busy_o_t)
               begin
                 value_1_t = $urandom%65535;
                //value_1_t = 65535;
                 value_2_t = $urandom%16;
                 send( value_1_t, value_2_t ); 
                //@(posedge clk)
                begin
                  data_i_t     = 1;
                  data_val_i_t = 0;
                end
               end
               
            else
              begin         
                @(posedge clk)
                @(posedge clk)
                @(posedge clk)
                value_1_t = 65535;
                value_2_t = $urandom%16;
                send( value_1_t, value_2_t ); 
              end
          end   
        #5000;
        flag_b = 1;
      end
      begin                                     //get
        forever
          begin
            @(posedge clk)
            get(); 
            if ( flag_b == 1 )
              break;
          end
      end         
    join
      begin
        compare( ref_queue, result_queue );
        $display( "end ------- " );
      end 
   #5000; 
   $stop;
  end  

  
  
serializer DUT (
    .clk_i ( clk ),
    .srst_i( reset),

    .data_i    ( data_i_t ),
    .data_mod_i( data_mod_i_t ),
    .data_val_i( data_val_i_t ),

    .ser_data_o  ( ser_data_o_t ),
    .ser_data_val( ser_data_val_t ),
    .busy_o      ( busy_o_t )
);
  
endmodule

