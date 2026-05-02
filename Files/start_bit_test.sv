`timescale 1ns/1ns
`ifndef START_BIT_TEST_SV
`define START_BIT_TEST_SV
`include "enviroment.sv"

program start_bit_test(intf_uart uart, intf_valid_ready intf_valid_ready);

  class my_trans extends transaction;
    constraint c_valid { valid == 1'b1; }
    constraint c_data  { data_i inside {[8'h20 : 8'h7E]}; }
    constraint c_delay { delay == 0; }
  endclass

  localparam int CICLI_PER_BIT = 29;
  localparam int NR_TRANS      = 5;
  localparam int HAS_PARITY    = 0;

  environment  env;
  my_trans     my_tr;

  bit [7:0] sent_queue[$];

  initial begin
    @(posedge intf_valid_ready.clk);
    wait(intf_valid_ready.reset === 1'b1);
    forever begin
      @(posedge intf_valid_ready.clk);
      if (intf_valid_ready.valid === 1'b1 && intf_valid_ready.ready === 1'b1)
        sent_queue.push_back(intf_valid_ready.data_i);
    end
  end

  initial begin
    bit [7:0] data_asteptata;
    bit [7:0] rx_data;
    bit [7:0] rx_reversed;
    int       i, b;
    int       ok_count, fail_count;

    ok_count  = 0;
    fail_count = 0;

    env   = new(uart, intf_valid_ready);
    my_tr = new();
    env.gen.repeat_count = NR_TRANS;
    env.gen.trans        = my_tr;

    fork env.run(); join_none

    wait(intf_valid_ready.reset === 1'b0);
    wait(intf_valid_ready.reset === 1'b1);
    @(posedge intf_valid_ready.clk);

    $display("\n=== [start_bit_test] START ===\n");

    for (i = 0; i < NR_TRANS; i++) begin
      rx_data = 8'h00;

      @(negedge uart.tx);
      $display("[%0d] START detectat la %0t", i+1, $time);

      wait(sent_queue.size() > 0);
      data_asteptata = sent_queue.pop_front();
      $display("[%0d] Date asteptate: 8'h%0h", i+1, data_asteptata);


      repeat(CICLI_PER_BIT + CICLI_PER_BIT/2) @(posedge uart.clk);
      rx_data[0] = uart.tx;

      for (b = 1; b <= 7; b++) begin
        repeat(CICLI_PER_BIT) @(posedge uart.clk);
        rx_data[b] = uart.tx;
      end

      rx_reversed = {rx_data[0], rx_data[1], rx_data[2], rx_data[3],
                     rx_data[4], rx_data[5], rx_data[6], rx_data[7]};

      if (rx_reversed === data_asteptata) begin
        $display("[%0d] DATE OK:   rx=8'h%0h == trimis=8'h%0h",
                 i+1, rx_reversed, data_asteptata);
        ok_count++;
      end else begin
        $error("[%0d] DATE FAIL: rx=8'h%0h != trimis=8'h%0h",
               i+1, rx_reversed, data_asteptata);
        fail_count++;
      end

      if (HAS_PARITY == 1) begin
        repeat(CICLI_PER_BIT) @(posedge uart.clk);
        if (uart.tx === ^data_asteptata)
          $display("[%0d] PARITATE OK", i+1);
        else
          $error("[%0d] PARITATE FAIL: tx=%0b, exp=%0b",
                 i+1, uart.tx, ^data_asteptata);
      end

      repeat(CICLI_PER_BIT) @(posedge uart.clk);
      $display("[%0d] STOP: tx=%0b\n", i+1, uart.tx);
    end

    $display("=== RAPORT FINAL ===");
    $display("  DATE OK  : %0d / %0d", ok_count,   NR_TRANS);
    $display("  DATE FAIL: %0d / %0d", fail_count, NR_TRANS);
    if (fail_count == 0)
      $display("*** TEST PASSED ***");
    else
      $display("*** TEST FAILED ***");
      
  end

endprogram
`endif
