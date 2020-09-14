module bit_population_counter #(
  parameter WIDTH = 5
)(
  input                        clk_i,
  input                        srst_i,

  input  [WIDTH-1:0]           data_i,
  input                        data_val_i,

  output [($clog2(WIDTH)+1):0] data_o,
  output                       data_val_o
);


logic [($clog2(WIDTH)+1):0] data_o_p;
logic                       data_val_o_p;

logic [WIDTH-1:0]           data_i_p_b;
logic [WIDTH-1:0]           data_i_p;

always_ff @( posedge clk_i )		// ---------------------
  begin
    if( srst_i )
      begin
        data_val_o_p <= 0;
        data_i_p     <= 0;
      end
    else									
      begin
       data_i_p     <= data_i;
	   data_val_o_p <= data_val_i;
      end   								
  end   							// always_ff

always_comb					
  begin
    data_o_p = 0;
    for(int i = 0; i < ( WIDTH ); i++ )
      if( data_i_p[i])
        data_o_p += 1;
  end

assign data_o     = data_o_p;
assign data_val_o = data_val_o_p;


endmodule