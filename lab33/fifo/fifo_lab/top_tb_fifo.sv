module top_tb_fifo;
bit clk;
bit reset;
 
initial 
    forever 
        #100 clk=!clk;




logic rdreq_i;     //вход данные
logic [7:0] data_i;
logic wrreq_i;

logic empty_o;
logic full_o;
logic [7:0] q_o;
logic [7:0] usedw_o;


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


initial
  begin
 $monitor( "Value: 1)data_i:%d 2)rdreq:%b 3)wrreq_i:%b 4)empty_o:%b 5)full_o:%b 6)q_o:%d 7)usedw_o:%d 8) %d ns",data_i, rdreq_i, wrreq_i, empty_o, full_o, q_o, usedw_o, $time);
   #200;            // set rdreq 0/wrreq x
   wrreq_i = 0;
   //$display( "Value: 1)data_i:%d 2)rdreq:%b 3)wrreq_i:%b 4)empty_o:%b 5)full_o:%b 6)q_o:%d 7)usedw_o:%d ",data_i, rdreq_i, wrreq_i, empty_o, full_o, q_o, usedw_o);
   #300;
    data_i  = 1;
	rdreq_i = 0;
   // $display( "Value: 1)data_i:%d 2)rdreq:%b 3)wrreq_i:%b 4)empty_o:%b 5)full_o:%b 6)q_o:%d 7)usedw_o:%d ",data_i, rdreq_i, wrreq_i, empty_o, full_o, q_o, usedw_o);
	#300;			// set rdreq 0/wrreq 1
	data_i  = 2;
	wrreq_i = 1;
	//$display( "Value: 1)data_i:%d 2)rdreq:%b 3)wrreq_i:%b 4)empty_o:%b 5)full_o:%b 6)q_o:%d 7)usedw_o:%d ",data_i, rdreq_i, wrreq_i, empty_o, full_o, q_o, usedw_o);
	//rdreq_i = 1;
	#300;
	data_i  = 3;
	#300;
	data_i  = 4;
	#300;
	data_i  = 5;
	#300;
	data_i  = 6;
	#300;
	data_i  = 7;
	#300;
	data_i  = 8;
	#300;
	data_i  = 9;
	#300;
	data_i  = 10;
	#300;
	data_i  = 11;
	//$display( "Value: 1)data_i:%d 2)rdreq:%b 3)wrreq_i:%b 4)empty_o:%b 5)full_o:%b 6)q_o:%d 7)usedw_o:%d ",data_i, rdreq_i, wrreq_i, empty_o, full_o, q_o, usedw_o);
	#300;			// set rdreq 1/wrreq 1
	data_i  = 12;
	rdreq_i = 1;
	wrreq_i = 1;
	//$display( "Value: 1)data_i:%d 2)rdreq:%b 3)wrreq_i:%b 4)empty_o:%b 5)full_o:%b 6)q_o:%d 7)usedw_o:%d ",data_i, rdreq_i, wrreq_i, empty_o, full_o, q_o, usedw_o);
	//wrreq_i = 1'bX;
	#300;
	data_i  = 13;
	//$display( "Value: 1)data_i:%d 2)rdreq:%b 3)wrreq_i:%b 4)empty_o:%b 5)full_o:%b 6)q_o:%d 7)usedw_o:%d ",data_i, rdreq_i, wrreq_i, empty_o, full_o, q_o, usedw_o);
	#300;			// set rdreq 1/wrreq 0
	data_i  = 14;
	rdreq_i = 1;
	wrreq_i = 0;
	//$display( "Value: 1)data_i:%d 2)rdreq:%b 3)wrreq_i:%b 4)empty_o:%b 5)full_o:%b 6)q_o:%d 7)usedw_o:%d ",data_i, rdreq_i, wrreq_i, empty_o, full_o, q_o, usedw_o);
	#300;
	data_i  = 15;
	//$display( "Value: 1)data_i:%d 2)rdreq:%b 3)wrreq_i:%b 4)empty_o:%b 5)full_o:%b 6)q_o:%d 7)usedw_o:%d ",data_i, rdreq_i, wrreq_i, empty_o, full_o, q_o, usedw_o);
    
  
        $display( "end ------- " );
   
   #5000; 
   $stop;
  end  
  
  
	fifo	fifoshka (
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
  
endmodule

