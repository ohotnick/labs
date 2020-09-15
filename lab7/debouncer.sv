module debouncer #(
parameter CLK_FREQ_MHZ = 20,
parameter GLITCH_TIME_NS = 50
)
(
input clk_i,

input key_i,

output key_pressed_stb_o
);

parameter CLK_TIME = 1/CLK_FREQ_MHZ;		//50ns и меньше идет в 1 такт
parameter WIDTH = CLK_TIME/GLITCH_TIME_NS;

logic key_pressed_stb_o_p;
logic per;
logic [($clog2(WIDTH)+1):0]data_o_p;		//колличество тактов
logic key_i_p;


always_ff @(posedge clk_i)		//по клоку---------------------
begin

key_i_p=key_i;

if(key_i_p != 1)
begin
key_pressed_stb_o_p <= 0;
per<=0;
data_o_p<=0;
key_pressed_stb_o_p<=0;
end 

if(key_i_p == 1 && per==0)
begin
data_o_p <= data_o_p +1;
end 

if(per==1)
key_pressed_stb_o_p<=0;
else
begin
if(data_o_p >=(WIDTH+1))
begin
key_pressed_stb_o_p<=1;
per<=1;
end
end


end   //always_ff

assign key_pressed_stb_o = key_pressed_stb_o_p;

endmodule