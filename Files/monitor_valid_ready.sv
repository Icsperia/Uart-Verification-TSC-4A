//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//monitorul urmareste traficul de pe interfetele DUT-ului, preia datele verificate si recompune tranzactiile (folosind obiecte ale clasei transaction); in implementarea de fata, datele preluate de pe interfete sunt trimise scoreboardului pentru verificare
//Samples the interface signals, captures into transaction packet and send the packet to scoreboard.
`include "coverage_valid_ready.sv"
//in macro-ul MON_IF se retine blocul de semnale de unde monitorul extrage datele
`define MON_IF valid_ready_vif.MONITOR.monitor_cb
class mon_valid_ready;
  
  //creating virtual interface handle
  virtual intf_valid_ready valid_ready_vif;
  
  //se creaza portul prin care monitorul trimite scoreboardului datele colectate de pe interfata DUT-ului sub forma de tranzactii 
  //creating mailbox handle
  mailbox mon2scb;
  //declar cnt
  int cnt_dly;
  coverage_valid_ready cov;
  //cand se creaza obiectul de tip monitor (in fisierul environment.sv), interfata de pe care acesta colecteaza date este conectata la interfata reala a DUT-ului
  //constructor
  function new(virtual intf_valid_ready valid_ready_vif,mailbox mon2scb, int cnt_dly=0, coverage_valid_ready cov);
    //getting the interface
    this.valid_ready_vif = valid_ready_vif;
    //getting the mailbox handles from  environment 
    this.mon2scb = mon2scb;
	this.cnt_dly= cnt_dly;
  this.cov = cov;
  endfunction
  
  //Samples the interface signal and send the sample packet to scoreboard
  task main;
    forever begin//tot timpul se uita pe interfata
      //se declara si se creaza obiectul de tip tranzactie care va contine datele preluate de pe interfata
      transaction trans;
      trans = new();

      //datele sunt citite pe frontul de ceas, informatiile preluate de pe semnale fiind retinute in oboiectul de tip tranzactie
      @(posedge valid_ready_vif.MONITOR.clk);
	  //conditia de transfer a datelor
      wait(`MON_IF.valid && `MON_IF.ready);
        trans.valid  = `MON_IF.valid;
        trans.ready = `MON_IF.ready;
        trans.data_i = `MON_IF.data_i;
		
    cov.sample_function(trans);
      // dupa ce s-au retinut informatiile referitoare la o tranzactie, continutul obiectului trans se trimite catre scoreboard
        mon2scb.put(trans);
    end
  endtask
//control de cicluri de ceas sa se vada ca functioneaza
  task delay_cnt();
	 forever begin
		@(posedge valid_ready_vif.MONITOR.clk);
		cnt_dly++;
	end
  endtask 
endclass