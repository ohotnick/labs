
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
  
  
  
  task send_pack( integer size_max, integer size_min, integer flag_set_word );  // (>5) - word, (<2) - wrog word, (2-5) no word
    logic [191:0] pack_to_send;
    logic [31:0]  wrd_N1;
    logic [31:0]  wrd_N2;
    logic [31:0]  wrd_N3;
    logic flag_b;
    
    
    integer flag_word;
    integer i_size_pack    = 0;
    integer i_send_pack    = 0;
    integer slide_word     = 0;
    integer x_send_pack    = 0;
    integer flag_word_send = 0;
    
    //wrd_N1 = 32'b01101000011001010110110001101100;  //hell h - 01101000
    wrd_N1 = 32'b01101100011011000110010101101000;
    //wrd_N2 = 32'b01101111001011000111011101101111;  //o,wo
    wrd_N2 = 32'b01101111011101110010110001101111;
    //wrd_N3 = 32'b01110010011011000110010000100001;  //rld!
    wrd_N3 = 32'b00100001011001000110110001110010;
    pack_to_send        = 0;
    //$display( "pack_to_send = %b, time %d ns ", pack_to_send, $time  );
    pack_to_send[95:0]  = {wrd_N1[31:0],wrd_N2[31:0],wrd_N3[31:0]}; 
    //$display( "pack_to_send = %b, time %d ns ", pack_to_send, $time  );
    //pack_to_send        = pack_to_send << (8*$random_range(7,0));
    slide_word          = 8*($urandom%7);
    //pack_to_send        = pack_to_send << 8*8;
    //$display( "slide_word = %d, time %d ns ", slide_word, $time  );
    pack_to_send        = pack_to_send << slide_word;
    //$display( "pack_to_send = %b, time %d ns ", pack_to_send, $time  );
    
    $display( "pack_to_send = %b, time %d ns ", pack_to_send[191:128], $time  );
    $display( "pack_to_send = %b, time %d ns ", pack_to_send[127:64], $time  );
    $display( "pack_to_send = %b, time %d ns ", pack_to_send[63:0], $time  );
    
    //flag_set_word       = 0;
    
    //i_size_pack = $random_range(size_max,size_min); //$random_range(1514,60)
    i_size_pack = $urandom%size_max;
    if(i_size_pack <= size_min)
      i_size_pack = size_min;
    i_send_pack = 0;
    //flag_word   = $urandom%10+5;
    flag_word   = flag_set_word;
    //$display( "flag_word = %d, i_size_pack = %d, time %d ns ", flag_word, i_size_pack, $time  );
    //$display( "pack_to_send = %b, time %d ns ", pack_to_send, $time  );
    $display( "flag_word = %d, time %d ns ", flag_word, $time  );
    x_send_pack = $urandom%( i_size_pack - ( 12 + 16 ));
    if(flag_word > 5)
      flag_word_send = 0;
    else if(flag_word < 2)
      flag_word_send = 8;
    else
      flag_word_send = 20;
      
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
                begin
                //$display( "1)i_send_pack = %d, 2)flag_word_send = %d, 3)x_send_pack %d, 4)i_size_pack %d,  time %d ns ", i_send_pack, flag_word_send, x_send_pack, i_size_pack, $time  );
                if( i_size_pack > (i_send_pack + 8) )
                  begin
                    if((i_send_pack >= x_send_pack) && (flag_word_send <= 2))
                      begin
                        if( flag_word_send == 0 )
                          av_st_if_v.data <= pack_to_send[191:128];
                        if( flag_word_send == 1 )
                          av_st_if_v.data <= pack_to_send[127:64];
                        if( flag_word_send == 2 )
                          begin
                            av_st_if_v.data <= pack_to_send[63:0];
                            flag_word_send = flag_word_send+ 20;
                          end
                        flag_word_send = flag_word_send + 1;
                      end
                    else if((i_send_pack >= x_send_pack) &&(flag_word_send <= 10))
                      begin
                        if( flag_word_send == 8 )
                          av_st_if_v.data <= pack_to_send[191:128] + $urandom%300;
                        if( flag_word_send == 9 )
                          av_st_if_v.data <= pack_to_send[127:64]  + $urandom%300;
                        if( flag_word_send == 10 )
                          av_st_if_v.data <= pack_to_send[63:0]    + $urandom%300;
                        flag_word_send = flag_word_send + 1;
                      end
                    else
                      av_st_if_v.data          <= $urandom;
                        
                    av_st_if_v.valid           <= 1;
                    if(i_send_pack == 0)
                      av_st_if_v.startofpacket <= 1;
                    else
                      av_st_if_v.startofpacket <= 0;
                    //$display( "i_send_pack = %d, time %d ns ", i_send_pack, $time  );
                    i_send_pack = i_send_pack + 8;
                  end
                else
                  begin
                    //i_send_pack            = i_send_pack + i_size_pack;
                    av_st_if_v.data          <= $urandom;
                    av_st_if_v.endofpacket   <= 1;
                    av_st_if_v.startofpacket <= 0;
                    av_st_if_v.empty         <= i_size_pack - i_send_pack;
                    flag_b                   = 1;
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
  
    integer size_max = 150;
    integer size_min = 60;
    integer   flag_brk = 0;
        

  integer count_send = 0;
  logic flag_get_sw = 0;
  logic flag_get_ow = 0;
  
  logic [63:0] ref_queue [$];
  logic [63:0] result_queue [$];
  
  integer flag_set_word   = 0;
/*
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

// send data ------------
task send (  ); 
  
  //integer flag_set_word   = 0;
  flag_set_word   = $urandom%12;
  //$display( "flag_set_word %d, time %d ns ",flag_set_word , $time  );
  if(flag_set_word > 5)
    begin
      //count_send = count_send + 1;
      $display( "!!!!!!!!!!!!1)count_send = %d, 2)flag_set_word = %d time %d ns ",count_send, flag_set_word , $time  );
    end
  //dut_class.send_pack( size_max, size_min, flag_set_word );
  
endtask


// get data ---------
task get (  );
        
  @(posedge clk)
    begin  
      //$display( "!!!get: av_infs_in: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7) %d ns",av_infs_in.data, av_infs_in.valid, av_infs_in.startofpacket, av_infs_in.endofpacket, av_infs_in.empty, av_infs_in.ready, $time);
      //$display( "!!!!1)count_send:%d, %d ns",count_send, $time);
      //if( count_send >= 1 )
      if(( flag_set_word > 5 )&&( av_infs_in.valid == 1 ))
      //if( av_infs_in.valid == 1 )
      if( av_infs_in.startofpacket == 1 )
        begin
          flag_get_sw = 1;
          ref_queue.push_back( av_infs_in.data );   
          //$display( "???get sop: av_infs_in: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7) %d ns",av_infs_in.data, av_infs_in.valid, av_infs_in.startofpacket, av_infs_in.endofpacket, av_infs_in.empty, av_infs_in.ready, $time);
        end
      else if(( flag_get_sw == 1 )&&(av_infs_in.endofpacket != 1))
        ref_queue.push_back( av_infs_in.data );
      else if( av_infs_in.endofpacket == 1 )
        begin
          flag_get_sw = 0;
          ref_queue.push_back( av_infs_in.data );
          count_send = count_send + 1;
          //$display( "+++get eop: av_infs_in: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7) %d ns",av_infs_in.data, av_infs_in.valid, av_infs_in.startofpacket, av_infs_in.endofpacket, av_infs_in.empty, av_infs_in.ready, $time);
        end
         
      if(( av_infs_out.sb_2.valid == 1 ) && ( count_send >= 1 ))
      begin
      
      if( av_infs_out.sb_2.startofpacket == 1 )
        begin
          flag_get_ow = 1;
          result_queue.push_back( av_infs_out.sb_2.data );
          //$display( "!!!get: av_infs_out: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7) %d ns",av_infs_out.sb_2.data, av_infs_out.sb_2.valid, av_infs_out.sb_2.startofpacket, av_infs_out.sb_2.endofpacket, av_infs_out.sb_2.empty, av_infs_out.sb_2.ready, $time);
        end
      else if(( flag_get_ow == 1 )&&(av_infs_out.sb_2.endofpacket != 1))
        begin
        result_queue.push_back( av_infs_out.sb_2.data );
        //$display( "???get: av_infs_out: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7) %d ns",av_infs_out.sb_2.data, av_infs_out.sb_2.valid, av_infs_out.sb_2.startofpacket, av_infs_out.sb_2.endofpacket, av_infs_out.sb_2.empty, av_infs_out.sb_2.ready, $time);
        end
      else if( av_infs_out.sb_2.endofpacket == 1 )
        begin
          result_queue.push_back( av_infs_out.sb_2.data );
          flag_get_ow = 0;
          count_send = count_send - 1;
          //$display( "+++get: av_infs_out: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7) %d ns",av_infs_out.sb_2.data, av_infs_out.sb_2.valid, av_infs_out.sb_2.startofpacket, av_infs_out.sb_2.endofpacket, av_infs_out.sb_2.empty, av_infs_out.sb_2.ready, $time);
        end
        //$display( "++++++1)count_send:%d, %d ns",count_send, $time);
      end
    end   

endtask

//compare data ------------
task compare ( logic [63:0] ref_queue [$], logic [63:0] result_queue [$] );

  logic [63:0] result;
  logic [63:0] ref_result;

while( result_queue.size() != 0 )
  begin
    if( ref_queue.size() == 0 )
       $error("Extra data from DUT");
    else
      begin
        result       = ref_queue.pop_front();
        ref_result   = result_queue.pop_front(); 
        $display( "1)result     = %d \n2)ref_result = %d 3)time %d ns ",result,ref_result,  $time  );
        
        if( result != ref_result )
          $error("Data mismatch");
      end
  end
endtask



initial
  begin

    AVClassPackGen dut_class;
    dut_class = new( av_infs_in );
    #1000;

    csr_address_i   = 0;
    csr_write_i     = 0;
    csr_writedata_i = 0;
    csr_read_i      = 0;
    //flag_set_word   = 0;   // (>5) - word, (<2) - wrog word, (2-5) no word
    
    //size_max = 1500;
    //size_min = 100;
    
    
    //$monitor( "av_infs_in: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7) %d ns",av_infs_in.data, av_infs_in.valid, av_infs_in.startofpacket, av_infs_in.endofpacket, av_infs_in.empty, av_infs_in.ready, $time);
    //$monitor( "av_infs_between: 1)data_i:%d 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7)channel:%d 8) %d ns",av_infs_between.sb_1.data, av_infs_between.sb_1.valid, av_infs_between.sb_1.startofpacket, av_infs_between.sb_1.endofpacket, av_infs_between.sb_1.empty, av_infs_between.sb_1.ready, av_infs_between.sb_1.channel, $time);
    //$monitor( "av_infs_out: 1)data_i:%d 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7) %d ns",av_infs_out.sb_2.data, av_infs_out.sb_2.valid, av_infs_out.sb_2.startofpacket, av_infs_out.sb_2.endofpacket, av_infs_out.sb_2.empty, av_infs_out.sb_2.ready, $time);
    
    //$monitor( "av_infs_in: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7) %d ns /n av_infs_between: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7)channel:%d 8) %d ns",av_infs_in.data, av_infs_in.valid, av_infs_in.startofpacket, av_infs_in.endofpacket, av_infs_in.empty, av_infs_in.ready, $time ,av_infs_between.sb_1.data, av_infs_between.sb_1.valid, av_infs_between.sb_1.startofpacket, av_infs_between.sb_1.endofpacket, av_infs_between.sb_1.empty, av_infs_between.sb_1.ready, av_infs_between.sb_1.channel, $time);
    
    av_infs_out.ready = 1;
    //dut_class.send_pack( size_max, size_min, 7 );
    //dut_class.send_pack( size_max, size_min, 5 );
    //dut_class.send_pack( size_max, size_min, 1 );
    //dut_class.send_pack( size_max, size_min, 5 );
    
    flag_brk = 0;
    //send( size_min, size_max );

     fork
      begin                                  // send
        for( int i = 0; i < 10 ; i++ )
          begin     
                send( ); 
                dut_class.send_pack( size_max, size_min, flag_set_word );
          end   
        flag_brk = 1;
      end
      begin                                     //get
        forever
          begin
          if (( flag_brk == 1 ) && ( count_send == 0 ))
          //if ( $time >= 10000 )
              break;
              begin
                get();
                //$display( "1)count_send = %d, 2) flag_brk = %d time %d ns ",count_send, flag_brk , $time  );
              end           
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

