`ifndef FIFO_TRANS_SV
`define FIFO_TRANS_SV

program fifo_test(intf_uart uart, intf_valid_ready intf_valid_ready);
  

class my_trans extends transaction;
    parameter DATA_WIDTH = 8;
    
    int cnt = 0;
    rand bit valid;
    rand bit ready;

    function void pre_randomize(); 
      valid.rand_mode(0); 
      ready.rand_mode(0);
      
     if(cnt % 4 != 3) begin 
        valid = 1;
    end else begin
        valid = 0;
    end
    
    cnt++;
    endfunction


    function void post_randomize();

      $display("[TRANS] valid = %0b  | ready = %0b | cnt = %0d", 
                valid, ready, cnt-1);
    endfunction
    


  endclass
  environment env;
  my_trans my_tr; 
  
  initial begin
    env = new(uart, intf_valid_ready);
    my_tr = new();
    repeat(5) begin
    my_tr.randomize();
    $display(" Valid generat manual este %0b", my_tr.valid);
  end
    env.gen.repeat_count = 30;
    env.gen.trans = my_tr;
    
    env.run();
$display("\n[DEBUG] Afisare continut FIFO din testbench.dut:");
    

    $display("FIFO complet: %p", testbench.dut.fifo);


    for (int i = 0; i < 30; i++) begin
        $display("Index [%0d] = %b", i, testbench.dut.fifo[i]);
        $display("Current_state: %d", testbench.dut.current_state);
    end
  end

endprogram

`endif