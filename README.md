# SearchImplementation (Naive, Suffix Array, FM-Index)

This repository contains **C++ and Python implementations** of different string search approaches, including:

- Naive search
- Suffix array search
- FM-index construction and search

The C++ implementation uses **SeqAn3** (vendored inside `lib/seqan3`) and **libdivsufsort** (vendored inside `lib/libdivsufsort`).

---

## Repository Structure

```txt
.
├── CMakeLists.txt
├── LICENSE.md
├── README.md
├── data/                 # input datasets (compressed)
├── lib/                  # SeqAn3 + libdivsufsort
└── src/                  # C++ and Python implementations
