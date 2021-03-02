module top_tb_lab4;
bit clk;
bit reset;
 
//parameter DWIDTH = 8;
 
initial 
    forever 
        #100 clk=!clk;
		
// interface avalon_st_if
//parameter DATA_WIDTH = 64;

interface avalon_st_if #(parameter DATA_WIDTH = 64)(input logic clk);
  logic ready;
  logic [(DATA_WIDTH-1):0]data;
  logic valid;
  logic startofpacket;
  logic endofpacket;
  logic [($clog2(DATA_WIDTH/8)-1):0]empty;
  logic channel;
  
  modport av_st_snk (input data,
                     input valid,
                     input startofpacket,
                     input endofpacket,
                     input empty,
					 input clk,

                     output ready);
  
  modport av_st_snk_c (input ast_data_i,
                       input valid,
                       input startofpacket,
                       input endofpacket,
                       input empty,
					   input clk,
				       input channel,

                       output ready);
					
  modport av_st_src_c (input ready,

                       output data,
                       output valid,
                       output startofpacket,
                       output endofpacket,
                       output empty,
                       output channel);
					   
  modport av_st_src (input ready,

                     output data,
                     output valid,
                     output startofpacket,
                     output endofpacket,
                     output empty);
					 
  property  err_2ep; 
    @(posedge clk) endofpacket ## 1 endofpacket;
  endproperty

  task ready_data(logic [(DATA_WIDTH-1):0]data_tv, logic valid_tv,  logic ready_tv);
    logic flag_data = 0;
	logic [(DATA_WIDTH-1):0]data_tv_flag;
	logic valid_flag;
    @(posedge clk)
	if( ready_tv == 0 )
      begin
	    if( flag_data == 0 )
		  begin
		    if( ( data_tv_flag != data_tv )||( valid_flag != valid_tv ) )
			  begin
			    valid_flag   = valid_tv;
		        data_tv_flag = data_tv;
			    flag_data    = 1;
			  end
		  end
		else if( flag_data == 1 )
		  if( ( data_tv_flag != data_tv )||( valid_flag != valid_tv ) )
		    $error("Miss data avalon");
	  end
	else if( ready_tv == 1 )
	  begin
	    flag_data     = 0;
		valid_flag   = valid_tv;
		data_tv_flag = data_tv;
	  end
    
  endtask
  
  task hardcode_av(logic startofpacket_tv, logic endofpacket_tv, logic empty_tv);
    integer i_count = 0;
    @(posedge clk)
	if( startofpacket_tv == 1 )
	  i_count = DATA_WIDTH/8;
	else if( endofpacket_tv == 1 )
	  i_count = i_count + empty_tv;
	else 
	i_count = i_count + DATA_WIDTH/8;
	
    if( 1514 < i_count < 60 )
      $error("Wrong size packet");
	  
  endtask
  
endinterface
		
		
class AVClassPackGen;

  virtual avalon_st_if.av_st_snk  av_st_if_v(clk);

  function new( virtual avalon_st_if.av_st_snk  av_st_if_v_new(clk) );
    av_st_if_v = av_st_if_v_new;
  endfunction
  
  task send_pack( integer size_max, integer size_min, logic flag_set_word )
	logic [191:0] pack_to_send;
	logic [31:0]  wrd_N1;
	logic [31:0]  wrd_N2;
	logic [31:0]  wrd_N3;
	logic flag_word;
	logic flag_b;
	
	integer i_size_pack = 0;
	integer i_send_pack = 0;
	
	wrd_N1 = 32b'01101000011001010110110001101100;  //hell h - 01101000
	wrd_N2 = 32b'01101111001011000111011101101111;  //o,wo
	wrd_N3 = 32b'01110010011011000110010000100001;  //rld!
	
	[95:0]pack_to_send  = {wrd_N1,wrd_N1,wrd_N1}; 
	pack_to_send        = pack_to_send << (8*$random_range(7,0));
	
	i_size_pack = $random_range(size_max,size_min); //$random_range(1514,60)
	i_send_pack = 0;
	flag_word   = $random_range(10,0);
	
	if( (i_size_pack > 192)&&(flag_word > 4) )
	
	av_st_if_v.data          = 0;
    av_st_if_v.valid         = 0;
    av_st_if_v.startofpacket = 0;
    av_st_if_v.endofpacket   = 0;
    av_st_if_v.empty         = 0;
	flag_b                   = 0;
	//av_st_if_v.clk
    //av_st_if_v. ready
	
	
	  forever
        begin
          @(posedge av_st_if_v.clk)
            begin
			  if( av_st_if_v.ready == 1 )
			  
		        if( i_send_pack == 0 )
				  begin
			        if((i_size_pack > 192)&&(flag_word > 4))
				      begin
			            av_st_if_v.data          <= [191:127]pack_to_send;
				     	av_st_if_v.valid         <= 1;
					    av_st_if_v.startofpacket <= 1;
						i_send_pack              = i_send_pack + 64;
				  	  end
				    else
				      begin
					    av_st_if_v.data          <= 1;
					    av_st_if_v.valid         <= 1;
					    av_st_if_v.startofpacket <= 1;
						if( i_size_pack > (i_send_pack + 64))
						  i_send_pack = i_send_pack + 64;
						else
						  begin
						    i_send_pack            <= i_send_pack + i_size_pack;
							av_st_if_v.endofpacket <= 0;
                            av_st_if_v.empty       <= i_send_pack + 64 - i_size_pack;
							flag_b                 = 1;
						  end
					  end
				  end
				else if( i_send_pack == 64 ) 
                  begin
			        if((i_size_pack > 192)&&(flag_word > 4))
				      begin
			            av_st_if_v.data          <= [126:64]pack_to_send;
				     	av_st_if_v.valid         <= 1;
					    av_st_if_v.startofpacket <= 0;
						i_send_pack              = i_send_pack + 64;
				  	  end
				    else
				      begin
					    av_st_if_v.data          <= 1;
					    av_st_if_v.valid         <= 1;
					    av_st_if_v.startofpacket <= 1;
						if( i_size_pack > (i_send_pack + 64))
						  i_send_pack = i_send_pack + 64;
						else
						  begin
						    i_send_pack            <= i_send_pack + i_size_pack;
							av_st_if_v.endofpacket <= 0;
                            av_st_if_v.empty       <= i_send_pack + 64 - i_size_pack;
							flag_b                 = 1;
						  end
					  end
				  end
                else if( i_send_pack == 128 ) 
                  begin
			        if((i_size_pack > 192)&&(flag_word > 4))
				      begin
			            av_st_if_v.data          <= [63:0]pack_to_send;
				     	av_st_if_v.valid         <= 1;
					    av_st_if_v.startofpacket <= 0;
						i_send_pack              = i_send_pack + 64;
				  	  end
				    else
				      begin
					    av_st_if_v.data          <= 1;
					    av_st_if_v.valid         <= 1;
					    av_st_if_v.startofpacket <= 0;
						if( i_size_pack > (i_send_pack + 64))
						  i_send_pack = i_send_pack + 64;
						else
						  begin
						    i_send_pack            <= i_send_pack + i_size_pack;
							av_st_if_v.endofpacket <= 0;
                            av_st_if_v.empty       <= i_send_pack + 64 - i_size_pack;
							flag_b                 = 1;
						  end
					  end
				  end
				else if( i_send_pack > size_max ) 
                  begin
					i_send_pack            <= i_send_pack + i_size_pack;
					av_st_if_v.endofpacket <= 0;
                    av_st_if_v.empty       <= 6;
					flag_b                 = 1;
				  end	
                else if( i_send_pack >= 192 ) 
                  begin
				    av_st_if_v.data          <= 1;
					av_st_if_v.valid         <= 1;
				    av_st_if_v.startofpacket <= 0;
					if( i_size_pack > (i_send_pack + 64))
					  i_send_pack = i_send_pack + 64;
					else
					  begin
					    i_send_pack            <= i_send_pack + i_size_pack;
						av_st_if_v.endofpacket <= 0;
                        av_st_if_v.empty       <= i_send_pack + 64 - i_size_pack;
						flag_b                 = 1;
					  end
				  end				  
					
			  else( av_st_if_v.ready == 0 )
			     begin
			       av_st_if_v.valid <= 1;
			     end
			        
		    end
          if ( flag_b == 1 )
              break;
        end
	
  endtask	
		
endclass
		
/*  NOT END
logic rdreq_i;     //вход данные
logic [(DWIDTH-1):0] data_i;
logic wrreq_i;

logic empty_o;
logic full_o;
logic [(DWIDTH-1):0] q_o;
logic [7:0] usedw_o;

logic empty_o_a;
logic full_o_a;
logic [(DWIDTH-1):0] q_o_a;
logic [7:0] usedw_o_a;

int count_send;

logic rdreq_i_temp;     //send
logic [(DWIDTH-1):0] data_i_temp;
logic wrreq_i_temp;

logic [(DWIDTH-1):0] result_queue_q [$];
logic [(DWIDTH-1):0] result_queue_usedw [$];
logic [(DWIDTH-1):0] result_queue_q_alter [$];
logic [(DWIDTH-1):0] result_queue_usedw_alter [$];

initial
  begin
    #300;
    @(posedge clk)
    begin
    reset<=1'b1;
    end
    @(posedge clk)
    reset<=1'b0;
	#600;
  end
  
// send data ------------
task send ( logic value_1,logic value_2, logic [(DWIDTH-1):0] value_3 ); //read, write, data
  @(posedge clk)
  rdreq_i = value_1;
  wrreq_i = value_2;
  data_i  = value_3;
  count_send = count_send + 1;
  
  $display( "Send№ %d 1)rdreq %b, 2)wrreq %b, 3)data %d",count_send, value_1, value_2, value_3 );
endtask

// get data ---------
task get (  );
  $display( "get  Test_q/Altera_q= %d/ %d. Test_u/Altera_u= %d/ %d " , q_o, q_o_a, usedw_o, usedw_o_a );
			
  result_queue_q.push_back( q_o );
  result_queue_q_alter.push_back( q_o_a );
			
  result_queue_usedw.push_back( usedw_o );
  result_queue_usedw_alter.push_back( usedw_o_a );

endtask

//compare data ------------
task compare ( [(DWIDTH-1):0] result_queue_q [$], [(DWIDTH-1):0] result_queue_q_alter [$], [(DWIDTH-1):0] result_queue_usedw, [(DWIDTH-1):0] result_queue_usedw_alter );

logic [(DWIDTH-1):0] ref_result_q;
logic [(DWIDTH-1):0] ref_result_q_alter;
logic [(DWIDTH-1):0] ref_result_usedw;
logic [(DWIDTH-1):0] ref_result_usedw_alter;

while( result_queue_q.size() != 0 )
  begin
    if( ref_queue_q.size() == 0 )
       $error("Extra data from DUT");
    else
      begin
        ref_result_q       = result_queue_q.pop_front();
        ref_result_q_alter = result_queue_q_alter.pop_front();   
		ref_result_usedw       = result_queue_usedw.pop_front();
        ref_result_usedw_alter = result_queue_usedw_alter.pop_front(); 
       // $display( "send %b, get %b ", ref_result, result  );
        if(( ref_result_q != ref_result_q_alter ) && ( ref_result_usedw != ref_result_usedw_alter ))
          $error("Data mismatch");
      end
  end
endtask

initial
  begin
 //$monitor( "Value: 1)data_i:%d 2)rdreq:%b 3)wrreq_i:%b 4)empty_o:%b 5)full_o:%b 6)q_o:%d 7)usedw_o:%d 8) %d ns",data_i, rdreq_i, wrreq_i, empty_o, full_o, q_o, usedw_o, $time);
  count_send = 0;
  flag_b     = 0;
     fork
      begin                                  // send
        for( int i = 0; i < ( 3*(2**AWIDTH_EXP) ); i++ )
          begin  
				if( empty_o_a == 1 )
                  wrreq_i_temp = 1;
				  else if( full_o_a == 1 ) 
				  wrreq_i_temp = 0;
				if( full_o_a == 1 )  
				 rdreq_i_temp = 1;
				else if( empty_o_a == 1 )  
				 rdreq_i_temp = 0;
				 
				 data_i_temp  = $urandom%(2**DWIDTH-1);
				 
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
        compare( ref_queue, result_queue );
        $display( "end ------- " );
      end 
  
        $display( "end ------- " );
   
   #5000; 
   $stop;
  end  
  
  
  fifo	        fifoshka_1 (
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
				
  fifo_alter	fifoshka_2 (
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

