`ifndef COVERAGE_UART_SV
`define COVERAGE_UART_SV

class coverage_uart #(parameter DATA_WIDTH = 8);
  transaction trans_covered;
  
  localparam int MAX_VAL = (1 << DATA_WIDTH) - 1; 
  localparam int MID_VAL = MAX_VAL / 2;



  covergroup tx_cg;
    tx_cp: coverpoint trans_covered.tx;
  endgroup

  covergroup transaction_cg;
    option.per_instance = 1;
    
    data_i_cp: coverpoint trans_covered.data_i {
      bins lowest_value  = {0};
      bins highest_value = {MAX_VAL};
      bins low_values    = {[1 : MID_VAL/2]};
      bins medium_values = {[MID_VAL/2 + 1 : MID_VAL]};
      bins big_values    = {[MID_VAL + 1 : MAX_VAL - 1]};
    }

    delay_cp: coverpoint trans_covered.delay {
      bins zero         = {0};
      bins small_values        = {[1 : 99]};
      bins medium_values       = {[100 : 999]};
      bins large_min    = {[1000 : 2500]};
      bins large_max    = {[2501 : $]};
    }

    // parity_cp: coverpoint trans_covered.parity {
    //   bins odd  = {1};
    //   bins even = {0};
    // }
  endgroup

  function new();
    transaction_cg = new();
    tx_cg = new();
  endfunction
  
  task sample_function(transaction trans_covered); 
    this.trans_covered = trans_covered; 
    transaction_cg.sample(); 
  endtask: sample_function   

  task sample_tx_function(transaction trans_covered); 
    this.trans_covered = trans_covered; 
    tx_cg.sample(); 
  endtask: sample_tx_function  
  
  function void print_coverage();
    $display ("--- Raport Coverage UART ---");
    $display ("TX line coverage   = %.2f%%", tx_cg.tx_cp.get_coverage());
    $display ("Data in coverage   = %.2f%%", transaction_cg.data_i_cp.get_coverage());
    $display ("Delay in coverage  = %.2f%%", transaction_cg.delay_cp.get_coverage());
    //$display ("Parity in coverage = %.2f%%", transaction_cg.parity_cp.get_coverage());
    $display ("Overall coverage   = %.2f%%", transaction_cg.get_coverage());
  endfunction

endclass: coverage_uart
`endif