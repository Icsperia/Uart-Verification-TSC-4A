`ifndef PARITY_BIT_SIMULATION
`define PARITY_BIT_SIMULATION 0
`endif

`ifndef BAUDRATE_MODE_SIMULATOR
`define BAUDRATE_MODE_SIMULATOR 2
`endif 

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
`include "fifo_test.sv"
`include "wait_trans.sv"
`include "stop_bit.sv"
`include "send_data_with_delay.sv"
`include "test_reset.sv"
//----------------------------------------------------------------


module testbench;
  
  //clock and reset signal declaration
logic clk;
 logic reset;
  
  //clock generation
  always #5 clk = ~clk;
  
  //reset Generation
  initial begin
    clk = 0;
    reset = 0;
    #15 reset = 1;
  end
  
  
  //creatinng instance of interface, inorder to connect DUT and testcase
  intf_uart intf_uart(clk,reset);
  intf_valid_ready intf_valid_ready(clk,reset);
  //Testcase instance, interface handle is passed to test as an argument
  //test t1(intf_uart, intf_valid_ready);
  fifo_test t2(intf_uart, intf_valid_ready);
  //wait_trans t3(intf_uart, intf_valid_ready);
  //stop_bit t4(intf_uart, intf_valid_ready);

 //send_data_with_delay t5(intf_uart, intf_valid_ready);
//reset_test t6(intf_uart, intf_valid_ready);
 //start_bit_test t5(intf_uart, intf_valid_ready);
  //DUT instance, interface signals are connected to the DUT ports

uart #(
  .DATA_WIDTH(8),
  .FIFO_DEPTH(16),
  .BOUD_RATE(`BAUDRATE_MODE_SIMULATOR), 
  .HAS_PARITY(`PARITY_BIT_SIMULATION),
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