//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
`include "uart.v"
interface intf_uart(input logic clk,reset);
  
    //declaring the signals
    logic tx;
    //logic [1:0] current_state;
    //logic wr_en;
    //logic rd_en;
    //logic [7:0] wdata;
    //logic [7:0] rdata;
    //semnalele din clocking block sunt ncrone cu frontul crescator de ceas
    //driver clocking block
    
    //nu avem driver la uart
    //monitor clocking block
    clocking monitor_cb @(posedge clk);
      default input #1 output #1;
      input tx; 
    endclocking
    
    //monitor modport  
    modport MONITOR (clocking monitor_cb,input clk,reset);
    
	//nu avem voie sa avem si read si write in acelai timp
   
// WAIT_TRANSACTION 0
// START            1
// DATA             2
// PARITY           3
// STOP             4

//verificare tx dupa reset
    property tx_invalid;
      @(posedge clk) disable iff (reset==0)//daca avem reset, nu se executa asertia
      !$isunknown(tx);
    endproperty
    
    asertia_tx_invalid: assert property (tx_invalid) 
     else $error("UART_ERR: tx in Z sau X");
    TX_invalid: cover property (tx_invalid);
    
//verificare tx in starea de repaus == 1
	property tx_repaus;
      @(posedge clk) disable iff (!reset)
      (uart.current_state == `WAIT_TRANSACTION) |-> (tx == 1'b1);
    endproperty
	
    asertia_tx_repaus: assert property (tx_repaus) 
	  else $error("UART_ERR: tx nu este HIGH in WAIT_TRANSACTION");
    
//verificare bit de start == 0 
    property tx_bit_start;
      @(posedge clk) disable iff (reset==0)
      (uart.current_state == `START && uart.boud_rate_counter>1) |-> (tx==1'b0);
    endproperty
    
    asertia_tx_bit_start: assert property (tx_bit_start) 
     else $error("UART_ERR: bit de start invalid");
    TX_bit_start: cover property (tx_bit_start);
	
//verificare integritate date -> daca tx == bitul selectat din fifo
	property tx_data_integrity;
      @(posedge clk) disable iff (!reset)
      (uart.current_state == `DATA && uart.boud_rate_counter>0) |-> (tx == uart.fifo[uart.r_counter][uart.bit_cnt]);
    endproperty
	
    asertia_tx_data_integrity: assert property (tx_data_integrity) 
	  else $error("UART_ERR: Datele de pe tx nu corespund cu bitul curent din FIFO");
    
//avem bit de paritate
    property tx_parity_bit;
        @(posedge clk) disable iff (!reset || uart.HAS_PARITY == 0)
        (uart.current_state == `PARITY) |-> (tx == ^(uart.fifo[uart.r_counter]));
    endproperty
	
    asertia_tx_parity_bit: assert property (tx_parity_bit) 
	    else $error("UART_ERR: Bit de paritate calculat gresit");
	
//biti de stop
    property tx_bit_stop;
      @(posedge clk) disable iff (reset==0)
      (uart.current_state == `STOP && uart.boud_rate_counter>0) |-> (tx==1'b1);
    endproperty
    
    asertia_tx_bit_stop: assert property (tx_bit_stop) 
     else $error("UART_ERR: bit de stop invalid");
    TX_bit_stop: cover property (tx_bit_stop);
	
//stabilitatea bitului pe durata boud_rate_counter
    property tx_bit_stability;
        @(posedge clk) disable iff (!reset)
        (uart.current_state != `WAIT_TRANSACTION && uart.boud_rate_counter > 2) |-> $stable(tx);
    endproperty
	
    asertia_tx_bit_stability: assert property (tx_bit_stability) 
	   else $error("UART_ERR: Semnalul tx s-a schimbat inainte de finalizarea baud rate");

// always @(posedge clk) begin
//     if (uart.current_state == `DATA) begin
//         $strobe("[%0t ns] |DEBUG: tx=%b | FIFO_bit=%b  | Bit_cnt=%0d",
//                  $time, tx, uart.fifo[uart.r_counter][uart.bit_cnt], 
//                 uart.bit_cnt);
//     end
// end

// always @(posedge clk) begin
//     if (uart.current_state == `START) begin
//         $strobe("[%0t ns] START_DEBUG: tx=%b, counter=%0d", 
//                  $time, tx, uart.boud_rate_counter);
//     end
// end
endinterface
