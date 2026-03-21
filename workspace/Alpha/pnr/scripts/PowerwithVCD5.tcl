restoreDesign route.enc.dat fullchip

read_activity_file \
    -format VCD \
    -scope  fullchip_tb.fullchip_instance \
    -start  50ns \
    -end    300ns \
    ../../gls/waveform/fullchip.vcd

report_power -outfile ./power_step5_vcd.rpt