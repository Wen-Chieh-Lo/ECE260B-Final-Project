# ── Step 1 Power with VCD ──
restoreDesign route.enc.dat core
set_analysis_view -setup WC_VIEW -hold BC_VIEW

# Run power with VCD:
set_power_analysis_mode \
    -reset

read_activity_file \
    -format VCD \
    -scope  step1_tb.step1_instance \
    -start  50ns \
    -end    250ns \
    ../../gls/waveform/step1.vcd

report_power -outfile ./power_step1_vcd.rpt