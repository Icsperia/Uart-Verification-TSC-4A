//-------------------------------------------------------------------------
//				www.verificationguide.com   testbench.sv
//-------------------------------------------------------------------------
//tbench_top or testbench top, this is the top most file, in which DUT(Design Under Test) and Verification environment are connected. 
//-------------------------------------------------------------------------

//including interfcae and testcase files
//`include "interface.sv"
`include "interface_valid_ready.sv"
`include "interface_uart.sv"

//-------------------------[NOTE]---------------------------------
//Particular testcase can be run by uncommenting, and commenting the rest
//`include "random_test.sv"
//`include "wr_rd_test.sv"
`include "default_test.sv"
//----------------------------------------------------------------


module testbench;
  
  //clock and reset signal declaration
  bit clk;
  bit reset;
  
  //clock generation
  always #5 clk = ~clk;
  
  //reset Generation
  initial begin
    reset = 1;
    #15 reset =0;
  end
  
  
  //creatinng instance of interface, inorder to connect DUT and testcase
  intf_uart intf_uart(clk,reset);
  intf_valid_ready intf_valid_ready(clk,reset);
  //Testcase instance, interface handle is passed to test as an argument
    test t1(intf_uart, intf_valid_ready);
  
  //DUT instance, interface signals are connected to the DUT ports

uart #(
  .DATA_WIDTH(8),
  .FIFO_DEPTH(16),
  .BOUD_RATE(1), 
  .HAS_PARITY(0),
  .NO_BITS_STOP(0)
) dut (
  .clk     (intf_valid_ready.clk),
  .rst_n   (intf_valid_ready.reset),
  .data_i  (intf_valid_ready.data_i),
  .valid   (intf_valid_ready.valid), // Matches 'input valid' in uart.v
  .ready   (intf_valid_ready.ready), // Matches 'output ready' in uart.v
  .tx      (intf_uart.tx)
);
  //enabling the wave dump
  initial begin 
    $dumpfile("dump.vcd"); $dumpvars;
  end
endmodule