//prin coverage, putem vedea ce situatii (de exemplu, ce tipuri de tranzactii) au fost generate in simulare; astfel putem masura stadiul la care am ajuns cu verificarea
//`include "transaction.sv"
class coverage #(parameter DATA_WIDTH = 8);
  
  transaction trans_covered;
  
  localparam int MAX_VAL = (1 << DATA_WIDTH) - 1; 
  localparam int MID_VAL = MAX_VAL / 2;
  //pentru a se putea vedea valoarea de coverage pentru fiecare element trebuie create mai multe grupuri de coverage, sau trebuie creata o functie de afisare proprie
  covergroup transaction_cg;
    //linia de mai jos este adaugata deoarece, daca sunt mai multe instante pentru care se calculeaza coverage-ul, noi vrem sa stim pentru fiecare dintre ele, separat, ce valoare avem.
    option.per_instance = 1;
    valid_cp: coverpoint trans_covered.valid;
    ready_cp: coverpoint trans_covered.ready;
    
    // adaugati adresele tuturor registrilor pe care ii aveti in DUT (sunt documentati in specificatie)
    // bin-ul other_addresses este important deoarece vrem sa vedem ca au fost trimise tranzactii si la adrese care nu apartin unor registrii (in acest caz DUT-ul trebuie sa aserteze semnalul pslverr)
     tx_cp: coverpoint trans_covered.tx{
      bins bins_start = {1};
      bins bins_date = {2};
      bins bins_paritate = {3};
      bins bins_stop ={4};
    }
    
    data_i_cp: coverpoint trans_covered.data_i {
      bins lowest_value  = {0};
      bins highest_value = {MAX_VAL};
      bins low_values    = {[1 : MID_VAL/2]};
      bins medium_values = {[MID_VAL/2 + 1 : MID_VAL]};
      bins big_values    = {[MID_VAL + 1 : MAX_VAL - 1]};
    }

    // counter_cp: coverpoint trans_covered.counter {
    //   bins pachet_complet[] = {[0 : DATA_WIDTH-1]}; 
    // }
    // handshake_cross: cross valid_cp, ready_cp;
  endgroup
  
  //se creaza grupul de coverage; ATENTIE! Fara functia de mai jos, grupul de coverage nu va putea esantiona niciodata date deoarece pana acum el a fost doar declarat, nu si creat
  function new();
    transaction_cg = new();
  endfunction
  
  task sample_function(transaction trans_covered); 
  	this.trans_covered = trans_covered; 
  	transaction_cg.sample(); 
  endtask: sample_function   
  
  function print_coverage();
    $display ("Valid coverage = %.2f%%", transaction_cg.valid_cp.get_coverage());
    $display ("Ready coverage = %.2f%%", transaction_cg.ready_cp.get_coverage());
    $display ("TX line coverage = %.2f%%", transaction_cg.tx_cp.get_coverage());
    $display ("Data in coverage = %.2f%%", transaction_cg.data_i_cp.get_coverage());
    //$display ("Counter coverage = %.2f%%", transaction_cg.counter_cp.get_coverage());
    $display ("Overall coverage = %.2f%%", transaction_cg.get_coverage());
  endfunction
  
  //o alta modalitate de a incheia declaratia unei clase este sa se scrie "endclass: numele_clasei"; acest lucru este util mai ales cand se declara mai multe clase in acelasi fisier; totusi, se recomanda ca fiecare fisier sa nu contina mai mult de o declaratie a unei clase
endclass: coverage

