module priority_encoder #(
parameter WIDTH = 5
)
(
input clk_i,
input srst_i,

input [WIDTH-1:0]data_i,

output [WIDTH-1:0]data_left_o,
output [WIDTH-1:0]data_right_o
);

logic [WIDTH-1:0]data_i_p;
logic [WIDTH-1:0]data_i_p_br;
logic [WIDTH-1:0]data_i_p_br2;
logic [WIDTH-1:0]data_i_p_bl;
logic [WIDTH-1:0]data_i_p_bl2;
logic [WIDTH-1:0]data_left_o_p;
logic [WIDTH-1:0]data_right_o_p;


always_ff @(posedge clk_i)		//по клоку---------------------
begin
if(srst_i)
begin
data_i_p <= 0;

end
else									//else начало
begin
data_i_p <= data_i;

/*
data_i_p_br <= (data_i_p_br +16)>> 2;

if( (data_i_p & 1) == 1 )
data_left_o_p <= 1;
if( (data_i_p & 2) == 2 )
data_left_o_p <= 2;
if( (data_i_p & 4) == 4 )
data_left_o_p <= 4;
if( (data_i_p & 8) == 8 )
data_left_o_p <= 8;
if( (data_i_p & 16) == 16 )
data_left_o_p <= 16;
*/	
	
//data_left_o_p <= data_i_p & 2;
	


//data_i_p_bl <= ~(data_i_p_bl>>1);


end   //else
end   //always_ff


always_comb					
begin

// рабочая левый бит
for (int i = 0; i < (WIDTH);i++)
	begin
if(i==0)	
begin	
data_i_p_bl2 =1;	
end		
data_i_p_bl = (data_i_p_bl2) << i;
if( (data_i_p & data_i_p_bl) >= 1 )
data_left_o_p = data_i_p_bl;
	end
if(data_i_p==0)
data_left_o_p = 0;	
	

//правый бит	
for (int j = 0; j < (WIDTH);j++)
	begin
if(j==0)	
begin	
data_i_p_br2 =0;
data_i_p_br2 = (~data_i_p_br2)>>1;
data_i_p_br = ~data_i_p_br2;	
end	
data_i_p_br = (~data_i_p_br2) >> j;
if( (data_i_p & data_i_p_br) >= 1 )
data_right_o_p = data_i_p_br;
	end
if(data_i_p==0)
data_right_o_p = 0;

end





assign data_left_o = data_left_o_p;
assign data_right_o = data_right_o_p;

endmodule