# ECE260B Project Report — local build

## Requirements

`pdflatex` and `bibtex` (TeX Live or MiKTeX). Optional: `latexmk`.

## Build

```bash
cd workspace/report
make compile
```

Output: `src/main.pdf`

```bash
make clean       # remove aux files, keep PDF
make distclean   # remove aux files and PDF
LATEXMK=1 make compile   # use latexmk if installed
```

## Project layout

| Path | Contents |
|------|----------|
| `src/` | LaTeX sources (`main.tex`, figures, `references.bib`, …) |
| `Makefile` | Build rules |

Edit files under `src/` as needed; keep `references.bib` and `\bibliography{...}` in `main.tex` in sync.

The repo adds `src/references.bib` and a small `\nocite{...}` block in `main.tex` (not in the upstream project export) so BibTeX builds cleanly.

`src/temp.png` is a single placeholder image for figures not yet exported; replace `\includegraphics{temp.png}` with real PNG/PDF paths as you finalize each milestone.

## Figures (paths without spaces)

Image folders are named `Step1_images/`, `Step3_images/`, `Step4_images/` (no spaces) so `pdflatex` does not warn about missing PNGs. If you replace `src/` from another export that still has `Step N images/`, run `make fiximgpaths` and update `\includegraphics{...}` paths in `main.tex` to match (`Step1_images/`, etc.).
