//-------------------------------------------------------------------------
//            www.verificationguide.com 
//-------------------------------------------------------------------------

class transaction;
  // Parametru care defineste latimea datelor (implicit 8 biti)
  parameter DATA_WIDTH = 8;
  
  // --- Atributele clasei (Variabile) ---

  // Cuvantul cheie 'rand' permite simulatorului sa genereze valori 
  // aleatorii pentru aceste campuri la apelarea functiei .randomize()
  rand bit [DATA_WIDTH-1:0] data_i; // Datele de intrare paralele
  rand bit valid;                   // Semnalul de validare a datelor
       bit ready;                   // Semnal primit de la DUT (nu este aleatoriu)
       bit tx;                      // Pinul serial de iesire monitorizat
  
  // 'delay' este folosit pentru a introduce pauze intre pachete
  rand int unsigned delay;
  
  bit parity; // Bitul de paritate calculat pentru verificare


  // Functia 'post_randomize' este executata automat de SystemVerilog 
  // imediat dupa ce valorile rand au fost generate. 
  // Este utila pentru afisarea log-urilor sau calcule automate.
  function void post_randomize();
    $display("--------- [Trans] post_randomize ------");
    // Afisaza detaliile tranzactiei in consola daca pachetul este valid
    if(valid) 
      $display("\t valid = %0h\t data_i = %0h\t delay = %0d", valid, data_i, delay);
    $display("-----------------------------------------");
  endfunction

  // Metoda 'do_copy' realizeaza o copie profunda a obiectului.
  // In SystemVerilog, obiectele sunt transmise prin referinta (pointer). 
  // Fara aceasta copie, Generatorul ar modifica datele pe care Driverul 
  // inca incearca sa le trimita.
  function transaction do_copy();
    transaction trans;
    trans = new(); // Creeaza o instanta noua 
    
    // Copiaza manual fiecare atribut din obiectul curent (this) in cel nou (trans)
    trans.valid   = this.valid;
    trans.data_i  = this.data_i;
    trans.delay   = this.delay;
    //trans.parity  = this.parity;
    
    return trans; // Returneaza noul obiect care este o copie fidela a celui original
  endfunction

endclass