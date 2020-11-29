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

logic flag_get;


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
    #100; 
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
  
  
  #1;  
  if((rdreq_i == 1) && (empty_o == 0) && (wrreq_i == 0))
    begin  
	  #1; 
	  flag_get <= 1;
	  if(( ref_queue_q_full.size() != 0 ) &&  (flag_get == 1))
	    begin
          temp_val = ref_queue_q_full.pop_back();
          ref_queue_q.push_back ( temp_val );
	      result_queue_q.push_back ( q_o );
		  $display( "ref_queue_q.push_back/q_o  %d./%d  %d ps" , temp_val, q_o , $time) ;
		end
     // $display( "ref_queue_q.push_back/q_o  %d./%d  %d ps" , temp_val, q_o , $time) ; 
    end
  else   
  if((wrreq_i == 1) && (full_o == 0) && (rdreq_i == 0)) 
    begin
	  flag_get = 0;
      #1; 
      if((wrreq_i == 1) && (full_o != 1) && (rdreq_i != 1)) 
        begin
          ref_queue_q_full.push_back       ( data_i_t );
          $display( "ref_queue_q_full.push_back  %d.  %d ps" , data_i_t, $time) ;
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
	wrreq_i  = 0;
	rdreq_i  = 0;
	flag_get = 0;
	#700;
    fork
      begin                                  // send
        for( int i = 0; i < ( 3*(2**AWIDTH_EXP_T)*4 ); i++ )
          begin  
          
            if( i >= 55 )    //  then empty write
              begin
                $display( "4 test i = %d ",i );
                if( empty_o == 1 )
                  begin   
                    wrreq_i_temp = 1;             
                    rdreq_i_temp = 0;
                  end
                else if( empty_o == 0 )
                  begin   
                    wrreq_i_temp = 0;             
                    rdreq_i_temp = 1;
                  end
              end
            else if( i >= 30 )     //  then full read
              begin
                $display( "3 test i = %d ",i );
                wrreq_i_temp = 1;
                if( usedw_o <= (2**AWIDTH_EXP_T - 1) && ( full_o == 0 ) )
                  begin             
                    rdreq_i_temp = 0;
                  end
                else if( full_o >= 1 )
                  begin             
                    rdreq_i_temp = 1;
                  end 
              end
            else if( i >= 12 )     //  r/w not full not empty
              begin
                $display( "2 test i = %d ",i );
                if(( usedw_o <= 3 ) && ( full_o == 0 ))
                  begin             
                    wrreq_i_temp = 1;
                    rdreq_i_temp = 0;
                  end
                else if( ( usedw_o >= 5 ) || (( usedw_o == 0 ) && ( full_o == 1 )))
                  begin             
                    wrreq_i_temp = 0;
                    rdreq_i_temp = 1;
                  end 
              end
            else if( i >= 0 )
              begin
                 $display( "1 test i = %d ",i );
				 if(count_send == 1)	
                 wrreq_i_temp = 1;
                if( full_o == 1 ) 
                  begin  		  
                    wrreq_i_temp = 0;
                    rdreq_i_temp = 1;
                  end 
              end
		  
          
            /*  if(count_send == 1)
               wrreq_i_temp = 1;
               if(count_send == 12)
               rdreq_i_temp = 1;
               if(count_send == 12)
               wrreq_i_temp = 0;
            /   if(count_send == 20)
               wrreq_i_temp = 1;
               if(count_send == 21)
               wrreq_i_temp = 0;
               if(count_send == 29)
               rdreq_i_temp = 0;*/
            
 
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

