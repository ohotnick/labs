
interface avalon_st_if #(parameter DATA_WIDTH = 64)(input logic clk);
  logic ready;
  logic [(DATA_WIDTH-1):0]data;
  logic valid;
  logic startofpacket;
  logic endofpacket;
  logic [($clog2(DATA_WIDTH/8)-1):0]empty;
  logic channel;
  
  
  clocking sb_1 @(posedge clk);
    input ready;

    output valid;
	output data;
    output startofpacket;
    output endofpacket;
    output empty;
    output channel;
	
    property  err_2ep; endofpacket ## 1 endofpacket;
   // @(posedge clk) endofpacket ## 1 endofpacket;
    endproperty
	
  endclocking
  
  
  clocking sb_2 @(posedge clk);
    input ready;

    output data;
    output valid;
    output startofpacket;
    output endofpacket;
    output empty;
	
    property  err_2ep; endofpacket ## 1 endofpacket;
   // @(posedge clk) endofpacket ## 1 endofpacket;
    endproperty
	
  endclocking
  
  modport av_st_snk (input data,
                     input valid,
                     input startofpacket,
                     input endofpacket,
                     input empty,
					 input clk,

                     output ready);
  
  modport av_st_snk_c (input data,
                       input valid,
                       input startofpacket,
                       input endofpacket,
                       input empty,
					   input clk,
				       input channel,

                       output ready);
  modport av_st_src_c (clocking sb_1);
					   
  modport av_st_src   (clocking sb_2);
/*					
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
					 */
					 
					 
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
	  begin
	    if( startofpacket_tv == 1 )
	      i_count = DATA_WIDTH/8;
	    else if( endofpacket_tv == 1 )
	      i_count = i_count + empty_tv;
	    else 
	      i_count = i_count + DATA_WIDTH/8;
	
        if( 1514 < i_count < 60 )
          $error("Wrong size packet");
	  end
	  
  endtask
  
endinterface
		
		
class AVClassPackGen;

  virtual avalon_st_if.av_st_snk  av_st_if_v;

  function new( virtual avalon_st_if.av_st_snk  av_st_if_v_new );
    av_st_if_v = av_st_if_v_new;
  endfunction
  
  task send_pack( integer size_max, integer size_min, integer flag_set_word );
	logic [191:0] pack_to_send;
	logic [31:0]  wrd_N1;
	logic [31:0]  wrd_N2;
	logic [31:0]  wrd_N3;
	logic flag_b;
	
	
	integer flag_word;
	integer i_size_pack = 0;
	integer i_send_pack = 0;
	integer slide_word  = 0;
	
	//wrd_N1 = 32'b01101000011001010110110001101100;  //hell h - 01101000
	wrd_N1 = 32'b01101100011011000110010101101000;
	//wrd_N2 = 32'b01101111001011000111011101101111;  //o,wo
	wrd_N2 = 32'b01101111011101110010110001101111;
	//wrd_N3 = 32'b01110010011011000110010000100001;  //rld!
	wrd_N3 = 32'b00100001011001000110110001110010;
	pack_to_send        = 0;
	//$display( "pack_to_send = %b, time %d ns ", pack_to_send, $time  );
	pack_to_send[95:0]  = {wrd_N1[31:0],wrd_N2[31:0],wrd_N3[31:0]}; 
	$display( "pack_to_send = %b, time %d ns ", pack_to_send, $time  );
	//pack_to_send        = pack_to_send << (8*$random_range(7,0));
	slide_word          = 8*($urandom%7);
	//pack_to_send        = pack_to_send << 8*8;
	//$display( "slide_word = %d, time %d ns ", slide_word, $time  );
	pack_to_send        = pack_to_send << slide_word;
	$display( "pack_to_send = %b, time %d ns ", pack_to_send, $time  );
	
	$display( "pack_to_send = %b, time %d ns ", pack_to_send[191:128], $time  );
	$display( "pack_to_send = %b, time %d ns ", pack_to_send[127:64], $time  );
	$display( "pack_to_send = %b, time %d ns ", pack_to_send[63:0], $time  );
	//flag_set_word       = 0;
	
	//i_size_pack = $random_range(size_max,size_min); //$random_range(1514,60)
	i_size_pack = $urandom%size_max;
	i_send_pack = 0;
	//flag_word   = $urandom%10+5;
	flag_word   = flag_set_word;
	//$display( "flag_word = %d, i_size_pack = %d, time %d ns ", flag_word, i_size_pack, $time  );
	//$display( "pack_to_send = %b, time %d ns ", pack_to_send, $time  );
	$display( "flag_word = %d, time %d ns ", flag_word, $time  );
	/*
	if( (i_size_pack > 192)&&(flag_word > 4) )
	  flag_set_word     = 1;
	  */
	  
	  
	  
	av_st_if_v.data          = 0;
    av_st_if_v.valid         = 0;
    av_st_if_v.startofpacket = 0;
    av_st_if_v.endofpacket   = 0;
    av_st_if_v.empty         = 0;
	flag_b                   = 0;
	//av_st_if_v.clk
    //av_st_if_v. ready
	/*
	@(posedge av_st_if_v.clk);
	@(posedge av_st_if_v.clk);
	@(posedge av_st_if_v.clk);
	@(posedge av_st_if_v.clk);
	*/
	
	  forever
        begin
          @(posedge av_st_if_v.clk)
            begin
			  //$display( "i_send_pack = %d, i_size_pack = %d, time %d ns ", i_send_pack,i_size_pack, $time  );
			  //#195;
			  if( av_st_if_v.ready == 0 )
			    av_st_if_v.startofpacket <= 0;
			  
			  if ( flag_b == 1 )
		        begin
			      if( av_st_if_v.endofpacket == 1 )
			        av_st_if_v.endofpacket <= 0;
		          //$display( "break, time %d ns ", $time  );
		          break;
			    end
			  else if( av_st_if_v.ready == 1 )
			  
		        if( i_send_pack == 0 )
				  begin
				    
			        if((i_size_pack > 192)&&(flag_word > 4))
				      begin
					    
			            av_st_if_v.data          <= pack_to_send[191:128];
				     	av_st_if_v.valid         <= 1;
					    av_st_if_v.startofpacket <= 1;
						i_send_pack              = i_send_pack + 64;
						//$display( "i_send_pack = %d, time %d ns ", i_send_pack, $time  );
				  	  end
				    else
				      begin
					    av_st_if_v.data          <= $urandom;
					    av_st_if_v.valid         <= 1;
					    av_st_if_v.startofpacket <= 1;
						//$display( "i_send_pack = %d, time %d ns ", i_send_pack, $time  );
						if( i_size_pack > (i_send_pack + 64))
						  i_send_pack = i_send_pack + 64;
						else
						  begin
						    //i_send_pack            = i_send_pack + i_size_pack;
							av_st_if_v.endofpacket <= 1;
                            av_st_if_v.empty       <= i_size_pack - i_send_pack;
							flag_b                 = 1;
						  end
					  end
				  end
				else if( i_send_pack == 64 ) 
                  begin
			        if((i_size_pack > 192)&&(flag_word > 4))
				      begin
			            av_st_if_v.data          <= pack_to_send[127:64];
				     	av_st_if_v.valid         <= 1;
					    av_st_if_v.startofpacket <= 0;
						i_send_pack              = i_send_pack + 64;
				  	  end
				    else
				      begin
					    av_st_if_v.data          <= $urandom;
					    av_st_if_v.valid         <= 1;
					    av_st_if_v.startofpacket <= 0;
						if( i_size_pack > (i_send_pack + 64))
						  i_send_pack = i_send_pack + 64;
						else
						  begin
						    //i_send_pack            = i_send_pack + i_size_pack;
							av_st_if_v.endofpacket <= 1;
                            av_st_if_v.empty       <= i_size_pack - i_send_pack;
							flag_b                 = 1;
						  end
					  end
				  end
                else if( i_send_pack == 128 ) 
                  begin
			        if((i_size_pack > 192)&&(flag_word > 4))
				      begin
			            av_st_if_v.data          <= pack_to_send[63:0];
				     	av_st_if_v.valid         <= 1;
					    av_st_if_v.startofpacket <= 0;
						i_send_pack              = i_send_pack + 64;
				  	  end
				    else
				      begin
					    av_st_if_v.data          <= $urandom;
					    av_st_if_v.valid         <= 1;
					    av_st_if_v.startofpacket <= 0;
						if( i_size_pack > (i_send_pack + 64))
						  i_send_pack = i_send_pack + 64;
						else
						  begin
						    //i_send_pack            = i_send_pack + i_size_pack;
							av_st_if_v.endofpacket <= 1;
                            av_st_if_v.empty       <= i_size_pack - i_send_pack;
							flag_b                 = 1;
						  end
					  end
				  end
				else if( i_send_pack > size_max ) 
                  begin
					//i_send_pack            = i_send_pack + i_size_pack;
					av_st_if_v.endofpacket <= 1;
                    av_st_if_v.empty       <= 6;
					flag_b                 = 1;
					//$display( "+++++++i_size_pack - i_send_pack =  %d, av_st_if_v.empty %d, time %d ns ",(i_size_pack - i_send_pack), av_st_if_v.empty , $time  );
				  end	
                else if( i_send_pack >= 192 ) 
                  begin
				    av_st_if_v.data          <= $urandom;
					av_st_if_v.valid         <= 1;
				    av_st_if_v.startofpacket <= 0;
					if( i_size_pack > (i_send_pack + 64))
					  i_send_pack = i_send_pack + 64;
					else
					  begin
					   // i_send_pack            = i_send_pack + i_size_pack;
						av_st_if_v.endofpacket <= 1;
                        av_st_if_v.empty       <=   i_size_pack - i_send_pack;
						flag_b                 = 1;
						//$display( "!!!!!!!!!i_size_pack - i_send_pack =  %d, av_st_if_v.empty %d, time %d ns ",(i_size_pack - i_send_pack), av_st_if_v.empty , $time  );
					  end
				  end				  
					
			  else if( av_st_if_v.ready == 0 )
			     begin
			       av_st_if_v.valid <= 1;
				   if( av_st_if_v.endofpacket == 1 )
			         av_st_if_v.endofpacket <= 0;
			     end
			   // $display( "flag_b %d, time %d ns ",flag_b , $time  );     
		    end
			/*
          if ( flag_b == 1 )
		    begin
			  if( av_st_if_v.endofpacket == 1 )
			    av_st_if_v.endofpacket <= 0;
		      $display( "break, time %d ns ", $time  );
		      break;
			end 
			*/
        end
	
  endtask	
		
endclass




		
module top_tb_lab4;
  bit clk;
  bit reset;
 
//parameter DWIDTH = 8;
 
  initial 
    forever 
        #100 clk=!clk;
		
		
  //Avalon-MM Slave
  logic [1:0]csr_address_i;
  logic csr_write_i;
  logic [31:0]csr_writedata_i;
  logic csr_read_i;
  
  logic [31:0]csr_readdata_o;
  logic csr_readdatavalid_o;
  logic csr_waitrequest_o;
  
  	integer size_max = 1500;
	integer size_min = 100;
	integer   flag_set_word;
		
/*
int count_send;

logic rdreq_i_temp;     //send
logic [(DWIDTH-1):0] data_i_temp;
logic wrreq_i_temp;

logic [(DWIDTH-1):0] result_queue_q [$];
logic [(DWIDTH-1):0] result_queue_usedw [$]; */

  avalon_st_if  av_infs_in(clk);
  avalon_st_if  av_infs_between(clk);
  avalon_st_if  av_infs_out(clk);
  
  


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
/*  
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
*/

initial
  begin
    //$monitor( "Value: 1)data_i:%d 2)rdreq:%b 3)wrreq_i:%b 4)empty_o:%b 5)full_o:%b 6)q_o:%d 7)usedw_o:%d 8) %d ns",data_i, rdreq_i, wrreq_i, empty_o, full_o, q_o, usedw_o, $time);
    


    AVClassPackGen dut_class;
    dut_class = new( av_infs_in );
	#1000;

    csr_address_i   = 0;
    csr_write_i     = 0;
    csr_writedata_i = 0;
    csr_read_i      = 0;
	flag_set_word   = 0;

	
	//size_max = 1500;
	//size_min = 100;
	
	
	//$monitor( "av_infs_in: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7) %d ns",av_infs_in.data, av_infs_in.valid, av_infs_in.startofpacket, av_infs_in.endofpacket, av_infs_in.empty, av_infs_in.ready, $time);
    //$monitor( "av_infs_between: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7)channel:%d 8) %d ns",av_infs_between.sb_1.data, av_infs_between.sb_1.valid, av_infs_between.sb_1.startofpacket, av_infs_between.sb_1.endofpacket, av_infs_between.sb_1.empty, av_infs_between.sb_1.ready, av_infs_between.sb_1.channel, $time);
    $monitor( "av_infs_out: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7) %d ns",av_infs_out.sb_2.data, av_infs_out.sb_2.valid, av_infs_out.sb_2.startofpacket, av_infs_out.sb_2.endofpacket, av_infs_out.sb_2.empty, av_infs_out.sb_2.ready, $time);
    
	//$monitor( "av_infs_in: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7) %d ns /n av_infs_between: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7)channel:%d 8) %d ns",av_infs_in.data, av_infs_in.valid, av_infs_in.startofpacket, av_infs_in.endofpacket, av_infs_in.empty, av_infs_in.ready, $time ,av_infs_between.sb_1.data, av_infs_between.sb_1.valid, av_infs_between.sb_1.startofpacket, av_infs_between.sb_1.endofpacket, av_infs_between.sb_1.empty, av_infs_between.sb_1.ready, av_infs_between.sb_1.channel, $time);
	
    av_infs_out.ready = 1;
	dut_class.send_pack( size_max, size_min, 7 );
    dut_class.send_pack( size_max, size_min, 5 );
	dut_class.send_pack( size_max, size_min, 1 );
	dut_class.send_pack( size_max, size_min, 5 );
/*
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
		
   */
   
   
   #10000; 
   $stop;
  end  
  

				
  packet_classer   packet_classer_dut(
                   .clk_i  (clk),
                   .srst_i (reset),

                   //Avalon-MM Slave
                   .csr_address_i       (csr_address_i),
                   .csr_write_i         (csr_write_i),
                   .csr_writedata_i     (csr_writedata_i),
                   .csr_read_i          (csr_read_i),

                   .csr_readdata_o      (csr_readdata_o),
                   .csr_readdatavalid_o (csr_readdatavalid_o),
                   .csr_waitrequest_o   (csr_waitrequest_o),

                   //Avalon-ST Sink
                   .ast_data_i          (av_infs_in.data),
                   .ast_valid_i         (av_infs_in.valid),
                   .ast_startofpacket_i (av_infs_in.startofpacket),
                   .ast_endofpacket_i   (av_infs_in.endofpacket),
                   .ast_empty_i         (av_infs_in.empty),

                   .ast_ready_o         (av_infs_in.ready),

                   //Avalon-ST Source
                   .ast_ready_i         (av_infs_between.sb_1.ready),

                   .ast_data_o          (av_infs_between.sb_1.data),
                   .ast_valid_o         (av_infs_between.sb_1.valid),
                   .ast_startofpacket_o (av_infs_between.sb_1.startofpacket),
                   .ast_endofpacket_o   (av_infs_between.sb_1.endofpacket),
                   .ast_empty_o         (av_infs_between.sb_1.empty),
                   .ast_channel_o       (av_infs_between.sb_1.channel)
);
				
  packet_resolver  packet_resolver_dut(
                   .clk_i    (clk),
                   .srst_i   (reset),

                   //Avalon-ST Sink
                   .ast_data_i          (av_infs_between.data),
                   .ast_valid_i         (av_infs_between.valid),
                   .ast_startofpacket_i (av_infs_between.startofpacket),
                   .ast_endofpacket_i   (av_infs_between.endofpacket),
                   .ast_empty_i         (av_infs_between.empty),
                   .ast_channel_i       (av_infs_between.channel),

                   .ast_ready_o         (av_infs_between.ready),

                   //Avalon-ST Source
                   .ast_ready_i         (av_infs_out.sb_2.ready),

                   .ast_data_o          (av_infs_out.sb_2.data),
                   .ast_valid_o         (av_infs_out.sb_2.valid),
                   .ast_startofpacket_o (av_infs_out.sb_2.startofpacket),
                   .ast_endofpacket_o   (av_infs_out.sb_2.endofpacket),
                   .ast_empty_o         (av_infs_out.sb_2.empty)
);
  
endmodule

