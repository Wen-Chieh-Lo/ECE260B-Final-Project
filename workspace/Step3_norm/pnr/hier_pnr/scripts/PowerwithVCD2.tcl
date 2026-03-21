restoreDesign /home/linux/ieng6/ECE260B_WI26_A00/sabhonsle/ECE260BProject/ECE260B-Final-Project/workspace/Step3_norm/pnr/hier_pnr/scripts/route.enc.dat core

read_activity_file -format VCD -scope  core_tb.core_instance -start  50ns -end 250ns \
    ../../../gls/waveform/core.vcd

report_power -outfile ./power_step3_vcd.rpt