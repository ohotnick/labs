module bit_population_counter #(
parameter WIDTH = 5
)
(
input clk_i,
input srst_i,

input [WIDTH-1:0]data_i,
input data_val_i,

output [($clog2(WIDTH)+1):0]data_o,
output data_val_o
);


logic [($clog2(WIDTH)+1):0]data_o_p;
logic data_val_o_p;
logic [WIDTH-1:0]data_i_p_b;
logic [WIDTH-1:0]data_i_p_b2;
logic [WIDTH-1:0]data_i_p;



always_ff @(posedge clk_i)		//по клоку---------------------
begin
if(srst_i)
begin
data_val_o_p<=0;
data_i_p<=0;
end
else									//else начало
begin

data_i_p <= data_i;
if(data_val_i==1)
data_val_o_p <=1;
else
data_val_o_p <=0;
end   //else
end   //always_ff

always_comb					
begin

if(data_val_o_p==1)
begin
// рабочая левый бит
for (int i = 0; i < (WIDTH);i++)
	begin
if(i==0)	
begin	
data_i_p_b2 =1;	
data_o_p =0;
end		
data_i_p_b = (data_i_p_b2) << i;
if( (data_i_p & data_i_p_b) >= 1 )
data_o_p = data_o_p+1;
end
end
else
data_o_p=0;

end

assign data_o = data_o_p;
assign data_val_o = data_val_o_p;


endmodule