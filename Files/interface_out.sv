//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
interface mem_intf(input logic clk,reset);
  
  //declaring the signals
  logic [1:0] addr;
  logic wr_en;
  logic rd_en;
  logic [7:0] wdata;
  logic [7:0] rdata;
  
  //semnalele din clocking block sunt sincrone cu frontul crescator de ceas
  //driver clocking block
  clocking driver_cb @(posedge clk);
    //semnalele de intrare sunt citite o unitate de timp inainte frontului de ceas, iar semnalele de iesire sunt citite o unitate de timp dupa frontul de ceas; astfel se elimina situatiile in care se fac scrieri sau citiri in acelasi timp
    default input #1 output #1;
    output addr;
    output wr_en;
    output rd_en;
    output wdata;
    input  rdata;  
  endclocking
  
  //monitor clocking block
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
    input addr;
    input wr_en;
    input rd_en;
    input wdata;
    input rdata;  
  endclocking
  
  //driver modport
  modport DRIVER  (clocking driver_cb,input clk,reset);
  
  //monitor modport  
  modport MONITOR (clocking monitor_cb,input clk,reset);
  
endinterface