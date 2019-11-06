
typedef struct {
  int a;
  int b;
} DpiStructGEN;

import "DPI-C" context gen_init_python = function gen_init_sv();
import "DPI-C" context gen_set_param = function gen_sv_set_param (inout DpiStructGEN dpiStruct);
import "DPI-C" context Somador_8_bits = function int gen_sv_sum(inout DpiStructGEN dpiStruct);

DpiStructGEN dpiStruct;

class exemplo_soma_refmod extends uvm_component;
  `uvm_component_utils(exemplo_soma_refmod)

  typedef exemplo_soma_transaction_i tr_type_in;
  typedef exemplo_soma_transaction_o tr_type_out;

  tr_type_in tr_in;
  tr_type_out tr_out;

  uvm_analysis_imp #(tr_type_in, exemplo_soma_refmod) refmod_exemplo_soma_i_tr_analysis_imp;
  uvm_analysis_port #(tr_type_out) refmod_exemplo_soma_o_tr_analysis_port;
  
  event begin_record, end_record, begin_refmodtask;

  
//======================= Construtor =======================================
  function new(string name = "exemplo_soma_refmod", uvm_component parent);
    super.new(name, parent);
    refmod_exemplo_soma_i_tr_analysis_imp = new("refmod_exemplo_soma_i_tr_analysis_imp", this);
    refmod_exemplo_soma_o_tr_analysis_port = new("refmod_exemplo_soma_o_tr_analysis_port", this);

    void'(gen_init_sv());
  endfunction

//====================== Build Phase =======================================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction: build_phase

//======================= Run Phase ========================================
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    fork

      refmod_task();
      record_tr_out();
    join
  endtask: run_phase

//============ Função para copiar transações do agent ======================
  virtual function write ( tr_type_in t);
    tr_in = tr_type_in::type_id::create("tr_in", this);
    tr_in.copy(t);
    $display("data1: %h e data2: %h",tr_in.data1_i, tr_in.data2_i);

   -> begin_refmodtask;
  endfunction

//============ Função para analisar leitura/escrita ========================
  task refmod_task();
    forever 
    begin
      @begin_refmodtask;
      tr_out = tr_type_out::type_id::create("tr_out", this);
      -> begin_record;
        dpiStruct.a = tr_in.data1_i;
        dpiStruct.b = tr_in.data2_i;
        tr_out.data_out_o = gen_sv_sum(dpiStruct);
      -> end_record;
      refmod_exemplo_soma_o_tr_analysis_port.write(tr_out);
    end
  endtask

//================= Função para gravar as transações ========================
  virtual task record_tr_out();
    forever begin
      @(begin_record);
      begin_tr(tr_out, "rfm");
      @(end_record);
      end_tr(tr_out);
    end
  endtask

endclass: exemplo_soma_refmod
