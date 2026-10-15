class SerialVirtualSequencer extends uvm_sequencer;
  `uvm_component_utils(SerialVirtualSequencer)
  SerialEnvCfg cfg;
  uvm_sequencer #(SerialCtrlItem) ctrlSeqr;
  uvm_sequencer #(SpiItem) spiSeqr;
  uvm_sequencer #(I2cItem) i2cSeqr;
  SerialScoreboard scoreboard;
  SerialObservationFilter observationFilter;
  virtual serial_ctrl_if vif_ctrl;
  virtual spi_if vif_spi;
  virtual i2c_if vif_i2c;
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
endclass
