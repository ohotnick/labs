module top_tb_lifo;
bit clk;
bit reset;
 
parameter DWIDTH_T     = 8;
parameter AWIDTH_EXP_T = 3;
 
initial 
    forever 
        #100 clk=!clk;

logic rdreq_i;
logic [(DWIDTH_T-1):0] data_i_t;       
logic wrreq_i;

logic empty_o;
logic full_o;
logic [(DWIDTH_T-1):0] q_o;
logic [(AWIDTH_EXP_T-1):0] usedw_o;

int count_send;

logic rdreq_i_temp;     
logic [(DWIDTH_T-1):0] data_i_t_temp;
logic wrreq_i_temp;

logic [(DWIDTH_T-1):0] result_queue_q [$];

logic [(DWIDTH_T-1):0] ref_queue_q [$];
logic [(DWIDTH_T-1):0] ref_queue_q_full [$];


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
  data_i_t     = value_3;
  count_send = count_send + 1;
endtask

// get data ---------
task get (  );
  
  logic [(DWIDTH_T-1):0] temp_val;
   
  if((rdreq_i == 1) && (empty_o != 1) && (wrreq_i != 1)&& (full_o != 1))
    begin   
      result_queue_q.push_back      ( q_o );
      temp_val = ref_queue_q_full.pop_back();
      ref_queue_q.push_back ( temp_val );
      $display( "ref_queue_q.push_back  %d.  %d ns" , temp_val , $time) ; 
    end
  else   
  if((wrreq_i == 1) && (full_o != 1) && (rdreq_i != 1)) 
    begin
      #1; 
      if((wrreq_i == 1) && (full_o != 1) && (rdreq_i != 1)) 
        begin
          ref_queue_q_full.push_back       ( data_i_t );
          $display( "ref_queue_q_full.push_back  %d.  %d ns" , data_i_t, $time) ;
        end
    end
    
endtask

//compare data ------------
task compare ( logic [(DWIDTH_T-1):0] result_queue_q [$], logic [(DWIDTH_T-1):0] ref_queue_q_t [$]);

logic [(DWIDTH_T-1):0] ref_result_q;
logic [(DWIDTH_T-1):0] result_q;

$display( "ref_queue_q_t.size()  %d." , ref_queue_q_t.size() );
while( result_queue_q.size() != 0 )
  begin
    if( result_queue_q.size() == 0 )
      $error("Extra data from DUT");
    else
      begin
        ref_result_q = ref_queue_q_t.pop_front();       
        result_q     = result_queue_q.pop_front();
        $display( "Compare Test/Lifo= %d/ %d." , ref_result_q, result_q );
        if(( ref_result_q != result_q  ))
          $error("Data mismatch");
        else
          $display( "ok" );
      end
  end
endtask

initial
  begin
    //$monitor( "\n Value: 1)data_i_t:%d 2)rdreq:%b 3)wrreq_i:%b 4)empty_o_a:%b 5)full_o_a:%b 6)q_o_a:%d 7)usedw_o_a:%d 8) %d ns \n",data_i_t, rdreq_i, wrreq_i, empty_o_a, full_o_a, q_o_a, usedw_o_a, $time);
    count_send = 0;
    flag_b     = 0;
    rdreq_i_temp = 0;
    wrreq_i_temp = 0;
    fork
      begin                                  // send
        for( int i = 0; i < ( 3*(2**AWIDTH_EXP_T)*3 ); i++ )
          begin  
          
          
            if( empty_o == 1 )
              wrreq_i_temp = 1;
            else if( full_o == 1 ) 
              wrreq_i_temp = 0;
            if( full_o == 1 )  
              rdreq_i_temp = 1;
            else if( empty_o == 1 )  
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
 
            data_i_t_temp  = $urandom%(2**DWIDTH_T-1);     
            send( rdreq_i_temp, wrreq_i_temp, data_i_t_temp ); 
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
        compare( result_queue_q, ref_queue_q );
        $display( "end ------- " );
      end 
  
    $display( "end ------- " );
    #5000; 
    $stop;
  end  
  
  
  lifo     #(
  .DWIDTH (DWIDTH_T),
  .AWIDTH_EXP (AWIDTH_EXP_T)
)     fifoshka_1 (
                .clk_i   (clk),
                .srst_i  (reset),
                .data_i  (data_i_t),
                .wrreq_i (wrreq_i),
                .rdreq_i (rdreq_i),
                .q_o     (q_o),
                .empty_o (empty_o),
                .full_o  (full_o),
                .usedw_o (usedw_o)
                );
                
endmodule

