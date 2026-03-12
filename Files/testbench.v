`timescale 1ns/1ns
module testbench;

parameter DATA_WIDTH   = 4;
parameter FIFO_DEPTH   = 8;
parameter BOUD_RATE    = 3;
parameter HAS_PARITY   = 1;
parameter NO_BITS_STOP = 2;

reg                   clk   ;
reg                   rst_n ;
              
reg [DATA_WIDTH-1:0]  data_i;
reg                   valid ;
wire                  ready ;

wire                  tx    ;   //cip enable/slave select

// 5 GHz clock generator
initial begin
  clk <= 0;
  forever #5 clk <= ~clk;
end


  
//reset generator
initial begin
  rst_n <= 0;
  repeat (20) @(posedge clk);
  rst_n <= 1;
end




initial begin
  
  valid  <= 0;
  data_i <= 0;
  @(negedge rst_n);
  @(posedge rst_n);
  @(posedge clk);
  
  write(15,0);
  write(0,0);
  write(5,3);
  write(15,5);
  write(0,1);
  write(15,0);
  write(5,0);
  write(10,3);
  write(7,5);
  write(3,1);
  
  //repeat(300)@(posedge clk);
  wait(i_uart.fifo_empty);
  repeat(10)@(posedge clk);
  $stop;

end

uart#(
  .DATA_WIDTH  (DATA_WIDTH  ),
  .FIFO_DEPTH  (FIFO_DEPTH  ),
  .BOUD_RATE   (BOUD_RATE   ),
  .NO_BITS_STOP(NO_BITS_STOP)
)i_uart(
  .clk    (clk   ),
  .rst_n  (rst_n ),

  .valid  (valid ),
  .ready  (ready ),
  .data_i (data_i),

  .tx     (tx    )
);


task write;
  input [DATA_WIDTH-1:0] data ;
  input [5         -1:0] delay;
begin
  valid <= 1   ;
  data_i <= data;
  @(posedge clk);
  
  while (~ready) @(posedge clk);
  
  valid <= 0;
  repeat (delay) @(posedge clk);
end
endtask

endmodule