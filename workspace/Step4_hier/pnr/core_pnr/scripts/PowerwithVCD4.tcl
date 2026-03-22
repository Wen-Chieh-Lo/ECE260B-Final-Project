restoreDesign route.enc.dat fullchip

read_activity_file \
    -format VCD \
    -scope  fullchip_tb.fullchip_instance \
    -start  50ns \
    -end    300ns \
    ../../gls/waveform/fullchip_lockstep_tb.vcd

report_power -outfile ./power_step4_lockstep_vcd.rpt