module top_tb_fifo;
bit clk;
bit reset;
 
parameter DWIDTH_T     = 8;
parameter AWIDTH_EXP_T = 3;
parameter SHOWAHEAD_T  = "OFF";
 
initial 
    forever 
        #100 clk=!clk;

logic rdreq_i;
logic [(DWIDTH_T-1):0] data_i;       
logic wrreq_i;

logic empty_o;
logic full_o;
logic [(DWIDTH_T-1):0] q_o;
logic [(AWIDTH_EXP_T-1):0] usedw_o;

logic empty_o_a;
logic full_o_a;
logic [(DWIDTH_T-1):0] q_o_a;
logic [(AWIDTH_EXP_T-1):0] usedw_o_a;

int count_send;

logic rdreq_i_temp;     
logic [(DWIDTH_T-1):0] data_i_temp;
logic wrreq_i_temp;

logic [(DWIDTH_T-1):0] result_queue_q [$];
logic [(DWIDTH_T-1):0] result_queue_usedw [$];
logic [(DWIDTH_T-1):0] result_queue_q_alter [$];
logic [(DWIDTH_T-1):0] result_queue_usedw_alter [$];

logic flag_b;

initial
  begin
    #300;
    @(posedge clk)
    begin
    reset<=1'b1;
    end
    @(posedge clk)
    reset<=1'b0;
  end
  
initial
  begin
    #600;  
  end  
  
// send data ------------
task send ( logic value_1, logic value_2, logic [(DWIDTH_T-1):0] value_3 ); //read, write, data
  @(posedge clk)
  rdreq_i    = value_1;
  wrreq_i    = value_2;
  data_i     = value_3;
  count_send = count_send + 1;
  
  $display( "Send N %d 1)rdreq %b, 2)wrreq %b, 3)data %d",count_send, value_1, value_2, value_3 );
endtask

// get data ---------
task get (  );
  $display( "get  Test_q/Altera_q= %d/ %d. Test_u/Altera_u= %d/ %d " , q_o, q_o_a, usedw_o, usedw_o_a );
            
  result_queue_q.push_back      ( q_o );
  result_queue_q_alter.push_back( q_o_a ); 
            
  result_queue_usedw.push_back      ( usedw_o );
  result_queue_usedw_alter.push_back( usedw_o_a );

endtask

//compare data ------------
task compare ( logic [(DWIDTH_T-1):0] result_queue_q [$], logic [(DWIDTH_T-1):0] result_queue_q_alter [$],logic [(DWIDTH_T-1):0] result_queue_usedw [$], logic [(DWIDTH_T-1):0] result_queue_usedw_alter [$]);

logic [(DWIDTH_T-1):0] ref_result_q;
logic [(DWIDTH_T-1):0] ref_result_q_alter;
logic [(DWIDTH_T-1):0] ref_result_usedw;
logic [(DWIDTH_T-1):0] ref_result_usedw_alter;

while( result_queue_q_alter.size() != 0 )
  begin
    if( result_queue_q_alter.size() == 0 )
      $error("Extra data from DUT");
    else
      begin
        ref_result_q           = result_queue_q.pop_front();
        ref_result_q_alter     = result_queue_q_alter.pop_front();   
        ref_result_usedw       = result_queue_usedw.pop_front();
        ref_result_usedw_alter = result_queue_usedw_alter.pop_front(); 
        $display( "Compare Test_q/Altera_q= %d/ %d. Test_u/Altera_u= %d/ %d " , ref_result_q, ref_result_q_alter, ref_result_usedw, ref_result_usedw_alter );
        if(( ref_result_q != ref_result_q_alter ) || ( ref_result_usedw != ref_result_usedw_alter ))
          $error("Data mismatch");
        else
          $display( "ok" );
      end
  end
endtask

initial
  begin
    //$monitor( "Value: 1)data_i:%d 2)rdreq:%b 3)wrreq_i:%b 4)empty_o:%b 5)full_o:%b 6)q_o:%d 7)usedw_o:%d 8) %d ns",data_i, rdreq_i, wrreq_i, empty_o, full_o, q_o, usedw_o, $time);
    $monitor( "\n Value: 1)data_i:%d 2)rdreq:%b 3)wrreq_i:%b 4)empty_o_a:%b 5)full_o_a:%b 6)q_o_a:%d 7)usedw_o_a:%d 8) %d ns \n",data_i, rdreq_i, wrreq_i, empty_o_a, full_o_a, q_o_a, usedw_o_a, $time);
    count_send = 0;
    flag_b     = 0;
    rdreq_i_temp = 0;
    wrreq_i_temp = 0;
    fork
      begin                                  // send
        for( int i = 0; i < ( 3*(2**AWIDTH_EXP_T)*3 ); i++ )
          begin  
          
          
            if( empty_o_a == 1 )
              wrreq_i_temp = 1;
            else if( full_o_a == 1 ) 
              wrreq_i_temp = 0;
            if( full_o_a == 1 )  
              rdreq_i_temp = 1;
            else if( empty_o_a == 1 )  
              rdreq_i_temp = 0;
              /*
              if(count_send == 1)
               wrreq_i_temp = 1;
               if(count_send == 12)
               rdreq_i_temp = 1;
               if(count_send == 19)
               wrreq_i_temp = 0;
               if(count_send == 20)
               wrreq_i_temp = 1;
               if(count_send == 21)
               wrreq_i_temp = 0;
               if(count_send == 29)
               rdreq_i_temp = 0;
            */
 
            data_i_temp  = $urandom%(2**DWIDTH_T-1);     
            send( rdreq_i_temp, wrreq_i_temp, data_i_temp ); 
          end   
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
        compare( result_queue_q, result_queue_q_alter, result_queue_usedw, result_queue_usedw_alter );
        $display( "end ------- " );
      end 
  
    $display( "end ------- " );
    #5000; 
    $stop;
  end  
  
  
  fifo     #(
  .DWIDTH (DWIDTH_T),
  .AWIDTH_EXP (AWIDTH_EXP_T),
  .SHOWAHEAD  (SHOWAHEAD_T)
)     fifoshka_1 (
                .clk_i   (clk),
                .srst_i  (reset),
                .data_i  (data_i),
                .wrreq_i (wrreq_i),
                .rdreq_i (rdreq_i),
                .q_o     (q_o),
                .empty_o (empty_o),
                .full_o  (full_o),
                .usedw_o (usedw_o)
                );
                
  fifo_alter     #( .SHOWAHEAD  (SHOWAHEAD_T)
  )   fifoshka_2 (
                .clock (clk),
                .data  (data_i),
                .rdreq (rdreq_i),
                .sclr  (reset),
                .wrreq (wrreq_i),
                .empty (empty_o_a),
                .full  (full_o_a),
                .q     (q_o_a),
                .usedw (usedw_o_a)
                );
  
endmodule

