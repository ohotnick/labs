
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
  virtual avalon_st_if            av_st_if_v_get;

  function new( virtual avalon_st_if.av_st_snk  av_st_if_v_new, virtual avalon_st_if  av_st_if_v_get_new );
    av_st_if_v     = av_st_if_v_new;
    av_st_if_v_get = av_st_if_v_get_new;
  endfunction
  
  
  task send_pack( logic [7:0] data_queue [$], integer length_packs_queue [$] );  
    
    logic [11:0][7:0] data_to_send = "hello,world!";
    
    logic   flag_b, flag_a;
    logic [63:0]  send_data;
    integer size_pack;
    
    flag_b = 0;
    flag_a = 0;
    
      forever
        begin
          //$display( "Start send %d ns ", $time  );
          @(posedge av_st_if_v.clk)
            begin
              
              
              if(( length_packs_queue.size() == 0)&&(flag_b == 0))
                begin
                  av_st_if_v.valid       <= 0;
                  av_st_if_v.endofpacket <= 0;
                  break;
                end
              
            
              if( flag_b == 0 )
                begin
                  av_st_if_v.data          = 0;
                  av_st_if_v.valid         = 0;
                  av_st_if_v.startofpacket = 0;
                  av_st_if_v.endofpacket   = 0;
                  av_st_if_v.empty         = 0;
                  flag_b                   = 1;
                  send_data                = 0;
                  $display( "number of pack %d, %d ns ", length_packs_queue.size(), $time  );
                  size_pack                = length_packs_queue.pop_front();
                  $display( "Start pack!!! size of pack %d, %d ns ", size_pack, $time  );
                end
              else if( flag_b == 1 )
                begin
                
                  if( flag_a == 0 )
                    begin
                      av_st_if_v.startofpacket <= 1;
                      
                      send_data[63:56]         = data_queue.pop_front();
                      send_data[55:48]         = data_queue.pop_front();
                      send_data[47:40]         = data_queue.pop_front();
                      send_data[39:32]         = data_queue.pop_front();
                      send_data[31:24]         = data_queue.pop_front();
                      send_data[23:16]         = data_queue.pop_front();
                      send_data[15:8]          = data_queue.pop_front();
                      send_data[7:0]           = data_queue.pop_front();

                      av_st_if_v.data          <= send_data;
                      av_st_if_v.valid         <= 1;
                      flag_a                    = 1;
                      size_pack                 = size_pack - 8;
                      $display( "SOP size of pack %d, %d ns ", size_pack, $time  );
                    end
                  else if( flag_a == 1 )
                    begin
                    
                      if( av_st_if_v.ready == 1 )
                        begin
                       
                          av_st_if_v.startofpacket <= 0;
                          if( size_pack <= 8 )
                            begin
                              av_st_if_v.endofpacket <= 1;
                              av_st_if_v.empty       = 8 - size_pack;
                              $display( "av_st_if_v.empty %d, %d ns ", av_st_if_v.empty, $time  );
                              flag_a = 0;
                              flag_b = 0;
                              
                              send_data = 0;
                              
                              if((8 - size_pack) < 8 )
                                send_data[63:56]         = data_queue.pop_front();
                              if((8 - size_pack) < 7 )
                                send_data[55:48]         = data_queue.pop_front();
                              if((8 - size_pack) < 6 )
                                send_data[47:40]         = data_queue.pop_front();
                              if((8 - size_pack) < 5 )
                                send_data[39:32]         = data_queue.pop_front();
                              if((8 - size_pack) < 4 )
                                send_data[31:24]         = data_queue.pop_front();
                              if((8 - size_pack) < 3 )
                                send_data[23:16]         = data_queue.pop_front();
                              if((8 - size_pack) < 2 )
                                send_data[15:8]          = data_queue.pop_front();
                              if((8 - size_pack) < 1 )
                                send_data[7:0]           = data_queue.pop_front();
                              
                             // $display( "Total size 1)data_queue %d, 2)send_data %b ,3) %d %d ns ", data_queue.size(),send_data,(8 - size_pack), $time  );
                              
                            end
                          else
                            begin
                              size_pack = size_pack - 8;
                             // $display( "size of pack %d, %d ns ", size_pack, $time  );
                           
                              send_data[63:56]         = data_queue.pop_front();
                              send_data[55:48]         = data_queue.pop_front();
                              send_data[47:40]         = data_queue.pop_front();
                              send_data[39:32]         = data_queue.pop_front();
                              send_data[31:24]         = data_queue.pop_front();
                              send_data[23:16]         = data_queue.pop_front();
                              send_data[15:8]          = data_queue.pop_front();
                              send_data[7:0]           = data_queue.pop_front();
                          
                            end

                          av_st_if_v.data          <= send_data;
                       
                        end
                   
                    end
                
                end
            end
        end
      $display( "End send %d ns ", $time  );    
  endtask   
  
  
  logic [7:0] result_queue [$];
  
  task get_pack(  );  
    
    integer three_packs;
    integer size_pack_get;
    logic   flag_get;
    three_packs = 561;
    size_pack_get = 0;
    flag_get    = 0;
    $display( "Start get!!!! %d ns ", $time  );
     forever
       begin
         @(posedge av_st_if_v.clk)
           three_packs = three_packs - 1;
           //$display( "GET: three_packs %d, %d ns ",three_packs, $time  );
           //$display( "GET: 1)three_packs %d, 2)av_st_if_v_get.startofpacket %d, 3)av_st_if_v_get.valid %d 4)av_st_if_v_get.data %s %d ns ",three_packs,av_st_if_v_get.startofpacket, av_st_if_v_get.valid, av_st_if_v_get.data, $time  );
         if((av_st_if_v_get.startofpacket == 1)&&(av_st_if_v_get.valid == 1)&&(flag_get == 0))
           begin
             //three_packs   = 561;
             flag_get      = 1;
             size_pack_get = size_pack_get + 1;
             
             //$display( "GET 1)Data SOP , 2)result_queue.size() %d,  %d ns ",result_queue.size(), $time  );
             
             result_queue.push_back(av_st_if_v_get.data[63:56]);
             result_queue.push_back(av_st_if_v_get.data[55:48]);
             result_queue.push_back(av_st_if_v_get.data[47:40]);
             result_queue.push_back(av_st_if_v_get.data[39:32]);
             result_queue.push_back(av_st_if_v_get.data[31:24]);
             result_queue.push_back(av_st_if_v_get.data[23:16]);
             result_queue.push_back(av_st_if_v_get.data[15:8]);
             result_queue.push_back(av_st_if_v_get.data[7:0]);
             
             
           end
         else if((flag_get == 1)&&(av_st_if_v_get.valid == 1)&&(av_st_if_v_get.endofpacket != 1))
           begin
             three_packs   = 561;
             
             result_queue.push_back(av_st_if_v_get.data[63:56]);
             result_queue.push_back(av_st_if_v_get.data[55:48]);
             result_queue.push_back(av_st_if_v_get.data[47:40]);
             result_queue.push_back(av_st_if_v_get.data[39:32]);
             result_queue.push_back(av_st_if_v_get.data[31:24]);
             result_queue.push_back(av_st_if_v_get.data[23:16]);
             result_queue.push_back(av_st_if_v_get.data[15:8]);
             result_queue.push_back(av_st_if_v_get.data[7:0]);
             
            //$display( "GET 1)Data mid , 2)result_queue.size() %d,  %d ns ",result_queue.size(), $time  );
             
           end
         else if((av_st_if_v_get.endofpacket == 1)&&(av_st_if_v_get.valid == 1)&&(flag_get == 1))
           begin
             flag_get = 0;
             
             if( 7 >= av_st_if_v_get.empty )
               result_queue.push_back(av_st_if_v_get.data[63:56]);
             if( 6 >= av_st_if_v_get.empty )
               result_queue.push_back(av_st_if_v_get.data[55:48]);
             if( 5 >= av_st_if_v_get.empty )
               result_queue.push_back(av_st_if_v_get.data[47:40]);
             if( 4 >= av_st_if_v_get.empty )
               result_queue.push_back(av_st_if_v_get.data[39:32]);
             if( 3 >= av_st_if_v_get.empty )
               result_queue.push_back(av_st_if_v_get.data[31:24]);
             if( 2 >= av_st_if_v_get.empty )
               result_queue.push_back(av_st_if_v_get.data[23:16]);
             if( 1 >= av_st_if_v_get.empty )
               result_queue.push_back(av_st_if_v_get.data[15:8]);
             if( 0 >= av_st_if_v_get.empty )
               result_queue.push_back(av_st_if_v_get.data[7:0]);
               
             $display( "GET 1)Data EOF , 2)result_queue.size() %d,  %d ns ",result_queue.size(), $time  );
           
           end
           
         if(three_packs <= 0)
           begin
             $display( "End get!!!!!! %d ns ", $time  );
             break;
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
  
    integer size_max = 1500;
    integer size_min = 60;
    integer   flag_brk = 0;
        

  integer count_send = 0;
  logic flag_get_sw = 0;
  logic flag_get_ow = 0;
  

  logic [7:0] ref_queue_v [$];
  logic [7:0] result_queue_v [$];
  logic [7:0] data_queue_v [$];
  integer length_packs_queue_v [$];
  
 // integer flag_set_word   = 0;

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
  
  
// packet generator
task packet_gen(  integer quantity_pack );
   //integer length_packs_queue [$]
   //logic [7:0] data_queue [$]
   //logic [7:0] ref_queue [$]
  //logic [11:0][7:0] data_to_send = "hello,world!";
  logic [11:0][7:0] data_to_send = "!dlrow,olleh";
  //integer i;
  integer flag_word;
  integer flag_wrong_word, wrong_word_num;
  integer flag_quant_word;
  integer size_max = 1500;
  integer size_min = 60;
  integer place_word;
  integer i, j, i_size_pack;
  
  //quantity_ref_pack = 0;
  
  for( i = 0; i < quantity_pack; i = i + 1 )
    begin
      flag_word       = $urandom%10;           //word in pack?
      flag_wrong_word = $urandom%10;           //wrong word?
      wrong_word_num  = $urandom%11;
      flag_quant_word = $urandom%10;
      
      i_size_pack = $urandom%size_max;
      if(i_size_pack <= size_min)
        i_size_pack = size_min;
      length_packs_queue_v.push_back( i_size_pack );
      $display( "Gen size %d, %d ns ", length_packs_queue_v.size(), $time  );
      
      place_word = $urandom%(i_size_pack-12);
      
    //  if((flag_word > 3)&&(flag_wrong_word <= 8))
    //    quantity_ref_pack = quantity_ref_pack + 1;
      $display( "IF flag_wrong_word %d, wrong_word_num %d, flag_word %d, %d ns ", flag_wrong_word,wrong_word_num,flag_word, $time  );
        
      for( j = 0; j < i_size_pack  ; j = j + 1 )
        begin
          if((( j >= place_word )&&( j < (place_word + 12)))&&(flag_word > 3))
            if((flag_wrong_word > 8)&&(wrong_word_num == (j - place_word) ))
              begin
                data_queue_v.push_back( (((data_to_send[11:0] ) >> (8 * ( j - place_word ))) + $urandom%250 + 1) );
              $display( "Wrong char!!!!!! j %d, %d ns ",j, $time  );
              end
            else
              begin
                data_queue_v.push_back( (data_to_send[11:0] >> (8 * ( j - place_word ))) );
                //$display( "Gen data_to_send %s, %d ns ", (data_to_send[11:0] >> (8 * ( j - place_word ))), $time  );
                $display( "Gen word pack i_size_pack %d, %d ns ", i_size_pack, $time  );
                if((flag_word > 3)&&((flag_wrong_word <= 8)))
                  ref_queue_v.push_back(data_queue_v[$]);
                
              end
          else
            begin
              data_queue_v.push_back( $urandom%255 );
              if((flag_word > 3)&&((flag_wrong_word <= 8)))
                begin
                  ref_queue_v.push_back(data_queue_v[$]);
               //$display( "Gen data_queue_v[$] %s, %d ns ", data_queue_v[$], $time  );
                end
            end
            
            if((flag_word > 3)&&((flag_wrong_word <= 8)))
              $display( "Wrd ref_queue_v [$] %s, %d ns ", ref_queue_v[$], $time  );
              $display( "Gen data_queue_v[$] %s, %d ns ", data_queue_v[$], $time  );
            /*
          if((flag_word > 3)&&((flag_wrong_word <= 8)))
            begin
              ref_queue_v.push_back(data_queue_v[$]);
              //$display( "Gen data_queue_v[$] %s, %d ns ", data_queue_v[$], $time  );
            end
            */
        end
    end
  
endtask  
  
//compare data ------------
task compare ( logic [7:0] ref_queue [$], logic [7:0] result_queue [$] );

  logic [7:0] result;
  logic [7:0] ref_result;
  
  $display( "Compare ref_queue_v   %d, %d ns ", ref_queue.size(), $time  );
  $display( "Compare result_queue  %d, %d ns ", result_queue.size(), $time  );

while( result_queue.size() != 0 )
  begin
    if( ref_queue.size() == 0 )
       $error("Extra data from DUT");
    else
      begin
        result       = ref_queue.pop_front();
        ref_result   = result_queue.pop_front(); 
        $display( "1)result     = %S \n2)ref_result = %S 3)time %d ns ",result,ref_result,  $time  );
        
        if( result != ref_result )
          $error("Data mismatch");
      end
  end
endtask

logic [31:0]test_word;
logic [11:0][7:0] mem_word = "!dlrow,olleh";

initial
  begin

    AVClassPackGen dut_class;
    dut_class = new( av_infs_in, av_infs_out );
    #1000;

    csr_address_i   = 0;
    csr_write_i     = 0;
    csr_writedata_i = 0;
    csr_read_i      = 0;
    
    test_word       =    mem_word[64:0] >> 32;
    
    //$monitor( "av_infs_in: 1)data_i:%d 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7) %d ns",av_infs_in.data, av_infs_in.valid, av_infs_in.startofpacket, av_infs_in.endofpacket, av_infs_in.empty, av_infs_in.ready, $time);
    //$monitor( "av_infs_between: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7)channel:%d 8) %d ns",av_infs_between.sb_1.data, av_infs_between.sb_1.valid, av_infs_between.sb_1.startofpacket, av_infs_between.sb_1.endofpacket, av_infs_between.sb_1.empty, av_infs_between.sb_1.ready, av_infs_between.sb_1.channel, $time);
    //$monitor( "av_infs_out: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7) %d ns",av_infs_out.sb_2.data, av_infs_out.sb_2.valid, av_infs_out.sb_2.startofpacket, av_infs_out.sb_2.endofpacket, av_infs_out.sb_2.empty, av_infs_out.sb_2.ready, $time);
    
    //$monitor( "av_infs_in: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7) %d ns /n av_infs_between: 1)data_i:%b 2)valid:%d 3)startofpacket:%d 4)endofpacket:%d 5)empty:%d 6)ready:%d 7)channel:%d 8) %d ns",av_infs_in.data, av_infs_in.valid, av_infs_in.startofpacket, av_infs_in.endofpacket, av_infs_in.empty, av_infs_in.ready, $time ,av_infs_between.sb_1.data, av_infs_between.sb_1.valid, av_infs_between.sb_1.startofpacket, av_infs_between.sb_1.endofpacket, av_infs_between.sb_1.empty, av_infs_between.sb_1.ready, av_infs_between.sb_1.channel, $time);
    
    av_infs_out.ready = 1;
    
    flag_brk = 0;
    //send( size_min, size_max );
    $display( "Size before gen %d, %d ns ", length_packs_queue_v.size(), $time  );
    packet_gen( 10 );
    $display( "Size after gen %d, %d ns ", length_packs_queue_v.size(), $time  );
    $display( "Size data_queue_v after gen %d, %d ns ", data_queue_v.size(), $time  );
    $display( "Size ref_queue_v after gen %d, %d ns ", ref_queue_v.size(), $time  );

     fork
      begin                                  // send
        //for( int i = 0; i < 10 ; i++ )
          begin     
            dut_class.send_pack( data_queue_v, length_packs_queue_v  );
          end   
       // flag_brk = 1;
        $display( "break point ------- " );
      end
      begin                                     //get
        //forever
          begin
         // if (( flag_brk == 1 ) && ( count_send == 0 ))
          //if ( $time >= 10000 )
            //  break;
              begin
                dut_class.get_pack(  );
                $display( "!!!Get dut_class.result_queue  %d, %d ns ", dut_class.result_queue.size(), $time  );
                //$display( "1)count_send = %d, 2) flag_brk = %d time %d ns ",count_send, flag_brk , $time  );
              end           
          end
      end         
    join
      begin
        $display( "start compare ------- " );
        //compare( ref_queue_v, result_queue_v );
        compare( dut_class.result_queue, ref_queue_v );
        $display( "end ------- " );
      end 
  
        $display( "end ------- %s", test_word );
 
   
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

