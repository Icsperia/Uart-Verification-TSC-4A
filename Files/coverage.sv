//prin coverage, putem vedea ce situatii (de exemplu, ce tipuri de tranzactii) au fost generate in simulare; astfel putem masura stadiul la care am ajuns cu verificarea
class coverage;
  
  transaction trans_covered;
  
  //pentru a se putea vedea valoarea de coverage pentru fiecare element trebuie create mai multe grupuri de coverage, sau trebuie creata o functie de afisare proprie
  covergroup transaction_cg;
    //linia de mai jos este adaugata deoarece, daca sunt mai multe instante pentru care se calculeaza coverage-ul, noi vrem sa stim pentru fiecare dintre ele, separat, ce valoare avem.
    option.per_instance = 1;
    wr_enable_cp: coverpoint trans_covered.wr_en;
    rd_enable_cp: coverpoint trans_covered.rd_en;
    
    // adaugati adresele tuturor registrilor pe care ii aveti in DUT (sunt documentati in specificatie)
    // bin-ul other_addresses este important deoarece vrem sa vedem ca au fost trimise tranzactii si la adrese care nu apartin unor registrii (in acest caz DUT-ul trebuie sa aserteze semnalul pslverr)
     address_cp: coverpoint trans_covered.addr{
      bins addr_reg_config = {0};
      bins addr_reg_status = {1};
      bins other_addresses = default;
    }
    
    write_data_cp: coverpoint trans_covered.wdata {
      bins big_values = {[191:254]};
      bins medium_values = {[127:190]};
      bins low_values = {[1:126]};
      bins lowest_value = {0};
      bins highest_value = {255};
    }
    read_data_cp: coverpoint trans_covered.rdata {
      //prin linia de mai jos am impartit intervalul de valori in 4 intervale egale
      bins range[4] = {[0:$]};
      bins lowest_value = {0};
      bins highest_value = {255};
    }
    
  endgroup
  //se creaza grupul de coverage; ATENTIE! Fara functia de mai jos, grupul de coverage nu va putea esantiona niciodata date deoarece pana acum el a fost doar declarat, nu si creat
  function new();
    transaction_cg = new();
  endfunction
  
  task sample(transaction trans_covered); 
  	this.trans_covered = trans_covered; 
  	transaction_cg.sample(); 
  endtask:sample   
  
  function print_coverage();
    $display ("Address coverage = %.2f%%", transaction_cg.address_cp.get_coverage());
    $display ("Write data coverage = %.2f%%", transaction_cg.write_data_cp.get_coverage());
    $display ("Read data coverage = %.2f%%", transaction_cg.read_data_cp.get_coverage());
    $display ("Overall coverage = %.2f%%", transaction_cg.get_coverage());
  endfunction
  
  //o alta modalitate de a incheia declaratia unei clase este sa se scrie "endclass: numele_clasei"; acest lucru este util mai ales cand se declara mai multe clase in acelasi fisier; totusi, se recomanda ca fiecare fisier sa nu contina mai mult de o declaratie a unei clase
endclass: coverage

