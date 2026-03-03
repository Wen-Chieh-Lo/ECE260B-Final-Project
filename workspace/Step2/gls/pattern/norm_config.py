# Config for norm_algorithm.py (edit this file to change default behavior)
# Command-line args override these values when provided.

# Input matrix file (tab/space separated integers)
INPUT = "./mac_out.txt"

# Axis to normalize: 0 = each column, 1 = each row
AXIS = 1

# Output file for normalized float matrix. None = only print to console
OUTPUT = "./norm_out.txt"

# Also save quantized version (as <OUTPUT>_q<N>.txt when OUTPUT is set)
QUANTIZE = True
# Quantization bit width (output range 0 .. 2^N - 1)
QUANTIZE_BITS = 8
