module counter  #(
parameter WIDTH = 4
)(
input                     clk      ,
input                     rst_n    ,
input [WIDTH-1:0]         reset_value,
input                     enable_i ,
input                     up_down_i,
input                     load_i   ,
input [WIDTH-1:0]         data_i   ,
output reg                overflow ,
output reg  [WIDTH-1:0]   cnt_o
);
  

always @(posedge clk or negedge rst_n)
if (~rst_n)              cnt_o <= reset_value; else       // pune toti bitii 0
if (enable_i)                                             // daca en e 1 numara counterul, else nu mai trebuie
if (up_down_i) begin 
  if (load_i)            cnt_o <= data_i       ; else     // counterul numara crescator
                         cnt_o <= cnt_o + 1 ;             // daca avem o data de incarcat
end else begin                                            // counterul numara descrescator
  if (load_i)            cnt_o <= data_i       ; else
                         cnt_o <= cnt_o - 1 ;

end
  
always @(*)
  if (cnt_o=={WIDTH{1'b1}})     overflow <= 1'b1; else   // cand ajunge counterul sa aiba toti bitii 1 atunci apare overflow
                                overflow <= 0;          

endmodule // counter
