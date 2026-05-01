//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//monitorul urmareste traficul de pe interfetele DUT-ului, preia datele verificate si recompune tranzactiile (folosind obiecte ale clasei transaction); in implementarea de fata, datele preluate de pe interfete sunt trimise scoreboardului pentru verificare
//Samples the interface signals, captures into transaction packet and send the packet to scoreboard.
`include "coverage_uart.sv"
//in macro-ul MON_IF se retine blocul de semnale de unde monitorul extrage datele
`define MON_IF uart_vif.MONITOR.monitor_cb 
//`include "transaction.sv"
class mon_uart;
virtual intf_uart uart_vif; 
  parameter DATA_LENGTH = 9;
  //creating virtual interface handle
  bit [DATA_LENGTH-1:0] uart_data;
  int                   i;           
  bit                   has_parity;
  
  coverage_uart cov;
  //se creaza portul prin care monitorul trimite scoreboardului datele colectate de pe interfata DUT-ului sub forma de tranzactii 
  //creating mailbox handle
  mailbox mon2scb;
  
  //cand se creaza obiectul de tip monitor (in fisierul environment.sv), interfata de pe care acesta colecteaza date este conectata la interfata reala a DUT-ului
  //constructor
  function new(virtual intf_uart uart_vif, mailbox mon2scb, bit has_parity = 0, coverage_uart cov);
    this.uart_vif    = uart_vif;
    this.mon2scb     = mon2scb;
    this.has_parity  = has_parity;
    this.cov  = cov;
  endfunction
  
  //Samples the interface signal and send the sample packet to scoreboard
  task main;
    forever begin // tot timpul se uita pe intefata
        //se declara si se creaza obiectul de tip tranzactie care va contine datele preluate de pe interfata
        transaction trans; // not used for now
        trans = new();

        //datele sunt citite pe frontul de ceas, informatiile preluate de pe semnale fiind retinute in oboiectul de tip tranzactie
        //@(posedge mem_vif.MONITOR.clk);
        while(uart_vif.MONITOR.monitor_cb.tx)begin
          @(posedge uart_vif.MONITOR.clk);
          trans.delay++;
        end
	   // @(negedge uart_vif.MONITOR.monitor_cb.tx); 
     
    cov.sample_tx_function(trans);//s-a apelat aici inregistrarea tranzactiei pentru a obtine coverage 100% pe linia tx;
        @(posedge uart_vif.MONITOR.clk);// Lungimea unui bit pe uart - conform baud rate
	     //start bit passed
		 
        for (i = DATA_LENGTH-1; i >= 0; i--) begin
          @(posedge uart_vif.MONITOR.clk);
          uart_data[i] = `MON_IF.tx;
        end
		
	    if(has_parity == 1)begin
             @(posedge uart_vif.MONITOR.clk);
	     // parity bit passed 
		end
		
	    @(posedge uart_vif.MONITOR.clk);
	    // stop bit passed
	    //enter idle state
  
		trans.data_i = uart_data;
    cov.sample_function(trans);
        // dupa ce s-au retinut informatiile referitoare la o tranzactie, continutul obiectului trans se trimite catre scoreboard
       mon2scb.put(trans);
    end
  endtask
  
endclass