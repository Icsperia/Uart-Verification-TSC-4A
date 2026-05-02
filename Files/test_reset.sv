`ifndef RESET_TEST_SV
`define RESET_TEST_SV

program reset_test(intf_uart uart, intf_valid_ready intf_valid_ready);
  
  // Constringem tranzactia pentru a trimite date fixe si rapide
  class reset_trans extends transaction;
    constraint c_valid { valid == 1'b1; }      // Fortam valid pe 1
    constraint c_data  { data_i == 8'hAA; }    // Folosim o data usor de recunoscut (10101010)
    constraint c_delay { delay == 2; }         // Delay mic intre pachete
  endclass

  environment env;
  reset_trans r_tr;

  initial begin
    // Instantiem mediul si tranzactia custom
    env = new(uart, intf_valid_ready);
    r_tr = new();
    
    // Injectam tranzactia in generator
    env.gen.trans = r_tr; 
    env.gen.repeat_count = 1000; 
    
    $display("\n[%0t] [TEST] 1. Asteptam ca sistemul sa iasa din reset", $time);
    
    // Bloc pentru detectarea iesirii din reset cu timeout de siguranta
    begin : wait_reset_block
      fork
        begin 
          wait(intf_valid_ready.reset === 1'b1); // Asteptam ca reset sa devina inactiv (1)
        end
        begin 
          #5000; // Daca dupa 5000 unitati de timp resetul e tot 0, oprim testul
          $error("\n!!!Semnalul de RESET nu s-a facut 1!"); 
          $finish; 
        end
      join_any
      disable wait_reset_block; // Oprim procesul de timeout daca resetul a venit la timp
    end
    
    $display("[%0t] [TEST] Sistem activ. Pornim mediul", $time);
    
    // Pornim componentele mediului in paralel (non-blocking)
    fork
      env.gen.main();
      env.driv_valid_ready.main();
      env.mon_valid_ready.main();
      env.mon_uart.main();
    join_none

    #10;

    $display("[%0t] [TEST] 2. Mediul ruleaza. Asteptam ca Driverul sa trimita primul pachet.", $time);
    
    // Verificam daca driverul incepe transmisia corect
    begin : wait_valid_block
      fork
        begin wait(intf_valid_ready.valid === 1'b1); end // Asteptam primul semnal VALID
        begin 
          #5000; 
          $error("\n!!!Driverul nu a ridicat VALID."); 
          $finish; 
        end
      join_any
      disable wait_valid_block;
    end
    
    $display("[%0t] [TEST] 3. VALID este pe 1! Asteptam ca FIFO/Counter sa raspunda cu READY = 1.", $time);
    
    // Verificam daca DUT-ul raspunde (handshake complet)
    begin : wait_ready_block
      fork
        begin wait(intf_valid_ready.valid === 1'b0); end // Valid 0 inseamna ca transferul s-a consumat
        begin 
          #5000; 
          $error("\n Modulul tau (DUT/FIFO) nu ridica niciodata READY la 1. "); 
          $finish; 
        end
      join_any
      disable wait_ready_block;
    end

    $display("[%0t] [TEST] PRIMUL TRANSFER A AVUT SUCCES! Pandim urmatorul pachet pentru a declansa resetul.", $time);

    // Asteptam inceputul urmatoarei transmisii
    wait(intf_valid_ready.valid === 1'b1);
    #2; // Lasam transmisia sa inceapa putin
    
    $display("[%0t] [TEST] TAIEM RESET-UL ACUM IN MIJLOCUL TRANSMISIEI!", $time);

    // Asteptam niste activitate pe linia seriala (TX) inainte de a reseta
    @(negedge uart.tx); 
    // @(posedge uart.tx); @(negedge uart.tx); #500;
    
    // Fortam semnalul de reset pe 0 (activ) folosind comanda 'force'
    force testbench.reset = 0; 
    
    // Verificam daca driverul si mediul reactioneaza corect la reset (trebuie sa opreasca VALID)
    begin : wait_valid_reset_block
      fork
        begin wait(intf_valid_ready.valid === 1'b0); end 
        begin 
          #5000; 
          $error("\n!!! Driverul nu a coborit VALID la 0 desi am fortat resetul. "); 
          $finish; 
        end
      join_any
      disable wait_valid_reset_block;
    end

    $display("[%0t] [TEST] SUCCESS: Driverul a oprit transmisia fortat. Eliberam Resetul.", $time);
    #10;
    
    // Eliberam forta de pe semnal si il readucem in starea inactiva 
    release testbench.reset;
    force testbench.reset = 1; 
    #2;
    release testbench.reset;

    // Lasam sistemul sa respire dupa reset inainte de a inchide simularea
    #1000;
    $display("[%0t] [TEST] TEST CURAT. OPRIRE.", $time);
    $finish; 
  end

endprogram
`endif