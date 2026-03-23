//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//monitorul urmareste traficul de pe interfetele DUT-ului, preia datele verificate si recompune tranzactiile (folosind obiecte ale clasei transaction); in implementarea de fata, datele preluate de pe interfete sunt trimise scoreboardului pentru verificare
//Samples the interface signals, captures into transaction packet and send the packet to scoreboard.

//in macro-ul MON_IF se retine blocul de semnale de unde monitorul extrage datele
`define MON_IF uart_vif.MONITOR.monitor_cb 
class mon_uart;
  parameter DATA_LENGTH = 9;
  //creating virtual interface handle
  bit [DATA_LENGTH-1:0] uart_data;
  int                   i;           
  bit                   has_parity;
  
  //se creaza portul prin care monitorul trimite scoreboardului datele colectate de pe interfata DUT-ului sub forma de tranzactii 
  //creating mailbox handle
  mailbox mon2scb;
  
  //cand se creaza obiectul de tip monitor (in fisierul environment.sv), interfata de pe care acesta colecteaza date este conectata la interfata reala a DUT-ului
  //constructor
  function new(virtual intf_uart uart_vif, mailbox mon2scb, bit has_parity = 0);
    this.uart_vif    = uart_vif;
    this.mon2scb     = mon2scb;
    this.has_parity  = has_parity;
  endfunction
  
  //Samples the interface signal and send the sample packet to scoreboard
  task main;
    forever begin // tot timpul se uita pe intefata
        //se declara si se creaza obiectul de tip tranzactie care va contine datele preluate de pe interfata
        transaction trans; // not used for now
        trans = new();

        //datele sunt citite pe frontul de ceas, informatiile preluate de pe semnale fiind retinute in oboiectul de tip tranzactie
        //@(posedge mem_vif.MONITOR.clk);
	    @(negedge uart_vif.MONITOR.monitor_cb.tx); // transaction started on tx line
        @(posedge uart_vif.MONITOR.clk);// Lungimea unui bit pe uart - conform baud rate
	     //start bit passed
		 
        for (i = DATA_LENGTH-1; i >= 0; i--) begin
          @(posedge uart_vif.MONITOR.clk);
          uart_data[i] = `MON_IF.tx;
        end
		
	    if(has_parity == 1)
             @(posedge uart_vif.MONITOR.clk);
	     // parity bit passed 
		end
		
	    @(posedge uart_vif.MONITOR.clk);
	    // stop bit passed
	    //enter idle state
  
		trans.data_i = uart_data;
        // dupa ce s-au retinut informatiile referitoare la o tranzactie, continutul obiectului trans se trimite catre scoreboard
        mon2scb.put(trans);
    end
  endtask
  
endclass