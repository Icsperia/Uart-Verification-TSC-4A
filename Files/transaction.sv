//-------------------------------------------------------------------------
//						www.verificationguide.com 
//-------------------------------------------------------------------------

//aici se declara tipul de data folosit pentru a stoca datele vehiculate intre generator si driver; monitorul, de asemenea, preia datele de pe interfata, le recompune folosind un obiect al acestui tip de data, si numai apoi le proceseaza
class transaction;
  parameter DATA_WIDTH = 8;
  
  //se declara atributele clasei
  //campurile declarate cu cuvantul cheie rand vor primi valori aleatoare la aplicarea functiei randomize()

   bit [DATA_WIDTH-1:0] data_i; 
  rand bit valid;
       bit ready;
       bit tx;
  rand int unsigned delay;
  
  //constrangerile reprezinta un tip de membru al claselor din SystemVerilog, pe langa atribute si metode
  //aceasta constrangere specifica faptul ca se executa fie o scriere, fie o citire
  //constrangerile sunt aplicate de catre compilator atunci cand atributele clasei primesc valori aleatoare in urma folosirii functiei randomize

  //aceasta functie este apelata dupa aplicarea functiei randomize() asupra obiectelor apartinand acestei clase
  //aceasta functie afiseaza valorile aleatorizate ale atributelor clasei

  
    function void post_randomize();
    $display("--------- [Trans] post_randomize ------");
    if(valid) $display("\t valid = %0h\t data_i = %0h\t delay = %0h",valid,data_i,delay);
    $display("-----------------------------------------");
  endfunction
  //operator de copiere a unui obiect intr-un alt obiect (deep copy)
  //modificam cu

    function transaction do_copy();
    transaction trans;
    trans = new();
    trans.valid   = this.valid;
    trans.data_i  = this.data_i;
    trans.delay   = this.delay;
    return trans;
  endfunction
endclass


