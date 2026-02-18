"""
Read MAC output matrix from file, then L1-normalize along a chosen axis.

  axis=0: normalize each column  (each column / sum(|column|))
  axis=1: normalize each row     (each row / sum(|row|))

Config: edit norm_config.py to set INPUT, AXIS, OUTPUT, QUANTIZE.
Command-line args override config when provided.
"""

import argparse
import os
import numpy as np

# Load config (same directory as this script)
_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
_CONFIG_PATH = os.path.join(_SCRIPT_DIR, "norm_config.py")


def _load_config():
    """Load norm_config.py; use defaults if file missing."""
    defaults = {
        "INPUT": "mac_out.txt",
        "AXIS": 1,
        "OUTPUT": None,
        "QUANTIZE": False,
        "QUANTIZE_BITS": 20,
    }
    if os.path.isfile(_CONFIG_PATH):
        with open(_CONFIG_PATH) as f:
            code = f.read()
        exec(compile(code, _CONFIG_PATH, "exec"), defaults)
    return defaults


def load_matrix(path: str) -> np.ndarray:
    rows = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            row = [int(x) for x in line.replace("\t", " ").split()]
            rows.append(row)
    return np.array(rows, dtype=np.int64)


def save_matrix(path: str, M: np.ndarray, sep: str = "\t", fmt: str = "%.6f") -> None:
    with open(path, "w") as f:
        for row in M:
            if np.issubdtype(M.dtype, np.floating):
                f.write(sep.join(fmt % x for x in row) + "\n")
            else:
                f.write(sep.join(map(str, row)) + "\n")


def normalize_l1_along_axis(M: np.ndarray, axis: int) -> np.ndarray:
    """
    L1 normalize along the given axis.
    axis=0: each column / sum(|column|)
    axis=1: each row / sum(|row|)
    """
    M = np.abs(np.asarray(M, dtype=np.float64))
    sum_abs = M.sum(axis=1, keepdims=True)
    return M / sum_abs


def quantize_to_bits(norm_float: np.ndarray, bits: int = 20) -> np.ndarray:
    """Map values in [-1, 1] to N-bit 2's complement signed integers [-2^(N-1), 2^(N-1)-1]."""
    x = np.clip(norm_float, -1, 1)
    half = 1 << (bits - 1)  # 2^(N-1)
    levels = (1 << bits) - 1  # 2^N - 1
    # (x+1)/2 in [0,1] -> scale to [0, levels] then shift to [-half, half-1]
    q = np.round((x + 1) / 2 * levels - half).astype(np.int64)
    return np.clip(q, -half, half - 1)


def signed_to_unsigned_twos_complement(signed_arr: np.ndarray, bits: int) -> np.ndarray:
    """Convert 2's complement signed values to unsigned bit pattern [0, 2^N-1] for file output."""
    mask = (1 << bits) - 1
    return (signed_arr.astype(np.int64) & mask).astype(np.int64)


def main():
    cfg = _load_config()
    parser = argparse.ArgumentParser(
        description="L1-normalize MAC output matrix. Config: norm_config.py (INPUT, AXIS, OUTPUT, QUANTIZE)."
    )
    parser.add_argument(
        "--input", "-i",
        default=None,
        help="Input matrix file (overrides config INPUT)",
    )
    parser.add_argument(
        "--axis", "-a",
        type=int,
        choices=[0, 1],
        default=None,
        help="Axis to normalize: 0=column, 1=row (overrides config AXIS)",
    )
    parser.add_argument(
        "--output", "-o",
        default=None,
        help="Output file (overrides config OUTPUT)",
    )
    parser.add_argument(
        "--quantize",
        action="store_true",
        help="Also output quantized to N bits (overrides config QUANTIZE)",
    )
    parser.add_argument(
        "--quantize-bits",
        type=int,
        default=None,
        metavar="N",
        help="Quantization bit width (default: 20, overrides config QUANTIZE_BITS)",
    )
    parser.add_argument(
        "--no-config",
        action="store_true",
        help="Ignore norm_config.py and use script defaults",
    )
    args = parser.parse_args()

    if args.no_config:
        cfg = {"INPUT": "mac_out.txt", "AXIS": 1, "OUTPUT": None, "QUANTIZE": False, "QUANTIZE_BITS": 20}
    else:
        cfg = _load_config()

    input_path = args.input if args.input is not None else cfg["INPUT"]
    axis = args.axis if args.axis is not None else cfg["AXIS"]
    output_path = args.output if args.output is not None else cfg["OUTPUT"]
    quantize = args.quantize or cfg["QUANTIZE"]
    quantize_bits = args.quantize_bits if args.quantize_bits is not None else cfg.get("QUANTIZE_BITS", 20)

    M = load_matrix(input_path)
    print(f"Loaded {input_path}: shape {M.shape}")
    print(f"Normalize along axis={axis} ({'column' if axis == 0 else 'row'})")

    norm_float = normalize_l1_along_axis(M, axis)
    print("\nNormalized (float):")
    print(norm_float)

    if output_path:
        save_matrix(output_path, norm_float)
        print(f"\nSaved float result to {output_path}")
        if quantize:
            q_signed = quantize_to_bits(norm_float, bits=quantize_bits)
            q_unsigned = signed_to_unsigned_twos_complement(q_signed, quantize_bits)
            out_q = output_path.rsplit(".", 1)
            out_q = (out_q[0] + f"_q{quantize_bits}.txt") if len(out_q) > 1 else output_path + f"_q{quantize_bits}.txt"
            save_matrix(out_q, q_unsigned, fmt="%d")
            print(f"Saved quantized ({quantize_bits}-bit 2's complement as unsigned 0..{2**quantize_bits - 1}) to {out_q}")
            print(f"Quantized (unsigned bit pattern):")
            print(q_unsigned)
    elif quantize:
        q_signed = quantize_to_bits(norm_float, bits=quantize_bits)
        q_unsigned = signed_to_unsigned_twos_complement(q_signed, quantize_bits)
        print(f"\nQuantized ({quantize_bits}-bit 2's complement as unsigned 0..{2**quantize_bits - 1}):")
        print(q_unsigned)


if __name__ == "__main__":
    main()
