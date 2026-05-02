`timescale 1ns/1ns
`ifndef START_BIT_TEST_SV
`define START_BIT_TEST_SV
`include "enviroment.sv"

program start_bit_test(intf_uart uart, intf_valid_ready intf_valid_ready);

  // Extindem tranzactia pentru a forta anumite scenarii
  class my_trans extends transaction;
    constraint c_valid { valid == 1'b1; } // Trimitem doar date valide
    constraint c_data  { data_i inside {[8'h20 : 8'h7E]}; } // Doar caractere ASCII printabile
    constraint c_delay { delay == 0; } // Fara pauze intre tranzactii (stress test)
  endclass

  // Parametri de configurare ai protocolului
  localparam int CICLI_PER_BIT = 28; // Durata unui bit in perioade de ceas
  localparam int NR_TRANS       = 2000; // Numarul total de tranzactii de verificat
  localparam int HAS_PARITY     = 0; // 0 daca nu avem bit de paritate

  environment  env;
  my_trans     my_tr;
  bit [7:0] sent_queue[$]; // Coada pentru a stoca ce date au intrat in DUT

  // Bloc initial 1: Monitorizeaza intrarea DUT-ului
  initial begin
    @(posedge intf_valid_ready.clk);
    wait(intf_valid_ready.reset === 1'b1); // Asteapta terminarea resetului
    forever begin
      @(posedge intf_valid_ready.clk);
      // Daca handshake-ul (valid & ready) e OK, salvam data in coada pentru comparatie laterala
      if (intf_valid_ready.valid === 1'b1 && intf_valid_ready.ready === 1'b1)
        sent_queue.push_back(intf_valid_ready.data_i);
    end
  end

  // Bloc initial 2: Verifica iesirea UART (pinul tx)
  initial begin
    bit [7:0] data_asteptata;
    bit [7:0] rx_data;
    bit [7:0] rx_reversed;
    int       i, b;
    int       ok_count, fail_count;

    ok_count   = 0;
    fail_count = 0;

    // Configurare mediu
    env   = new(uart, intf_valid_ready);
    my_tr = new();
    env.gen.repeat_count = NR_TRANS; // Setam numarul de tranzactii in generator
    env.gen.trans        = my_tr;    // Injectam tipul nostru de tranzactie

    // Pornim mediul in fundal (non-blocking)
    fork env.run(); join_none

    // Sincronizare cu hardware-ul
    wait(intf_valid_ready.reset === 1'b0);
    wait(intf_valid_ready.reset === 1'b1);
    @(posedge intf_valid_ready.clk);

    $display("\n=== [start_bit_test] START ===\n");

    for (i = 0; i < NR_TRANS; i++) begin
      rx_data = 8'h00;

      // 1. Detectare START BIT (tranzitie de la 1 la 0 pe firul TX)
      $display("[%0d] Astept semnal START (negedge TX)...", i+1);
      @(negedge uart.tx); 
      
      $display("[%0d] START detectat. Verific coada de date...", i+1);
      
      // 2. Timeout de siguranta pentru a nu bloca simularea daca coada e goala
      fork
        begin
          wait(sent_queue.size() > 0);
        end
        begin
          #10ms; 
          $error("TIMEOUT: Datele nu au ajuns in sent_queue!");
          $finish;
        end
      join_any
      disable fork;

      data_asteptata = sent_queue.pop_front(); // Luam prima data intrata
      $display("[%0d] Date asteptate: 8'h%0h", i+1, data_asteptata);

      // 3. Esantionare date (Sampling)
      // Sarim peste bitul de START si ne pozitionam in mijlocul primului bit de date
      repeat(CICLI_PER_BIT + CICLI_PER_BIT/2) @(posedge uart.clk);
      rx_data[0] = uart.tx; // Citim primul bit (LSB)

      // Citim restul de 7 biti, sarind cate o durata de bit intre citiri
      for (b = 1; b <= 7; b++) begin
        repeat(CICLI_PER_BIT) @(posedge uart.clk);
        rx_data[b] = uart.tx;
      end

      // 4. Reconstructie octet (UART trimite LSB-ul primul)
      rx_reversed = {rx_data[7], rx_data[6], rx_data[5], rx_data[4],
                     rx_data[3], rx_data[2], rx_data[1], rx_data[0]};
      

      // 5. Verificare Date
      if (rx_data === data_asteptata) begin // UART trimite LSB primul, deci rx_data e deja ordonat corect
        $display("[%0d] DATE OK: 8'h%0h", i+1, rx_data);
        ok_count++;
      end else begin
        $error("[%0d] DATE FAIL: rx=8'h%0h != exp=8'h%0h", i+1, rx_data, data_asteptata);
        fail_count++;
      end

      // 6. Verificare Paritate (daca este activata)
      if (HAS_PARITY == 1) begin
        repeat(CICLI_PER_BIT) @(posedge uart.clk);
        // Verificam daca bitul de paritate de pe fir coincide cu XOR-ul datelor
        if (uart.tx === ^data_asteptata)
          $display("[%0d] PARITATE OK", i+1);
        else
          $error("[%0d] PARITATE FAIL", i+1);
      end

      // 7. Asteptare STOP BIT (firul trebuie sa revina in 1)
      repeat(CICLI_PER_BIT) @(posedge uart.clk);
      $display("[%0d] STOP: tx=%0b\n", i+1, uart.tx);
    end

    // Afisare rezultate finale
    $display("=== RAPORT FINAL ===");
    $display("  DATE OK  : %0d / %0d", ok_count,   NR_TRANS);
    $display("  DATE FAIL: %0d / %0d", fail_count, NR_TRANS);
    
    if (fail_count == 0) $display("*** TEST PASSED ***");
    else                 $display("*** TEST FAILED ***");

    #100ns;
    $finish; // Inchide simularea fortat (opreste si bucla forever)
  end

endprogram
`endif
