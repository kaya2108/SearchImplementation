# SearchImplementation (Naive, Suffix Array, FM-Index)

This repository contains **C++ and Python implementations** of different string search approaches for genome sequence searching, which includes :

- **Naive search** - brute-force pattern matching
- **Suffix array search** - efficient indexed pattern matching
- **FM-index** - compressed full-text index with search capabilities

The C++ implementation uses **SeqAn3** (vendored inside `lib/seqan3`) and **libdivsufsort** (vendored inside `lib/libdivsufsort`).

---

## Repository Structure

```txt
.
├── CMakeLists.txt
├── LICENSE.md
├── README.md
├── benchmark_cpp.sh      # C++ benchmarking script
├── benchmark_py.sh       # Python benchmarking script
├── data/                 # input datasets (FASTA files, compressed)
├── lib/                  # SeqAn3 + libdivsufsort
├── src/                  # C++ and Python implementations
└── results/              # benchmark output (created automatically)
    ├── cpp/
    └── python/
```

---

## Prerequisites

### For C++ Implementation
- **CMake** 3.14 or higher
- **g++** with C++20 support
- **SeqAn3** (included in `lib/seqan3`)
- **libdivsufsort** (included in `lib/libdivsufsort`)

### For Python Implementation
- **Python 3.x**
- Required libraries (install via pip if needed)

### System Requirements
- Linux/Unix environment (for `/usr/bin/time -v` command)
- Sufficient memory for genome data processing
- Input data files in `data/` directory

---

## Input Data

The benchmarks expect the following files in the `data/` directory:

- `hg38_partial.fasta.gz` - Reference genome (partial human genome)
- `illumina_reads_40.fasta.gz` - Query sequences (length 40)
- `illumina_reads_60.fasta.gz` - Query sequences (length 60)
- `illumina_reads_80.fasta.gz` - Query sequences (length 80)
- `illumina_reads_100.fasta.gz` - Query sequences (length 100)

---

## Running Benchmarks

### Python Benchmarks

```bash
chmod +x benchmark_py.sh
./benchmark_py.sh
```

**What it does:**
1. Records system information (CPU, memory, Python version)
2. Runs naive search (100 queries of 100 bp length)
2. Constructs FM-index from reference genome
3. Runs query count benchmarks (1K, 10K, 100K queries of 100bp)
   - Suffix array search
   - FM-index search
4. Runs query length benchmarks (40, 60, 80, 100 bp with 10K queries each)
   - Suffix array search
   - FM-index search

**Output:** Results saved in `results/python/`

### C++ Benchmarks

```bash
chmod +x benchmark_cpp.sh
./benchmark_cpp.sh
```

**What it does:**
1. Records system information (CPU, memory, g++ version)
2. Builds C++ project using CMake
3. Runs naive search (100 queries of 100bp )
4. Constructs FM-index and saves to `hg38_partial.index`
5. Runs query count benchmarks (1K, 10K, 100K queries)
   - Suffix array search
   - FM-index search
6. Runs query length benchmarks (40, 60, 80, 100 bp with 10K queries each)
   - Suffix array search
   - FM-index search

**Output:** Results saved in `results/cpp/`

---

## Benchmark Results

After running the benchmarks, you'll find detailed results in the `results/` directory:

### Python Results (`results/python/`)
- `system_info.txt` - System specifications
- `naive_search_100.txt` - Naive search baseline (100 queries)
- `fmindex_construction.txt` - FM-index construction time and memory
- `task4_suffix_counts.txt` - Suffix array performance vs query count
- `task4_fmindex_counts.txt` - FM-index performance vs query count
- `task5_suffix_lengths.txt` - Suffix array performance vs query length
- `task5_fmindex_lengths.txt` - FM-index performance vs query length

### C++ Results (`results/cpp/`)
- `system_info.txt` - System specifications
- `naive_search_100.txt` - Naive search baseline (100 queries)
- `fmindex_construction.txt` - FM-index construction time and memory
- `task4_suffix_counts.txt` - Suffix array performance vs query count
- `task4_fmindex_counts.txt` - FM-index performance vs query count
- `task5_suffix_lengths.txt` - Suffix array performance vs query length
- `task5_fmindex_lengths.txt` - FM-index performance vs query length

---

## Building C++ Project Manually

```bash
mkdir -p build
cd build
cmake ..
cmake --build .
cd ..
```

Executables will be in `build/bin/`:
- `naive_search`
- `suffixarray_search`
- `fmindex_construct`
- `fmindex_search`

---

## Performance Metrics

The benchmarks measure:

1. **Construction Time** - Time to build FM-index from reference genome
2. **Query Scalability** - Performance with varying numbers of queries (10³, 10⁴, 10⁵)
3. **Query Length Sensitivity** - Performance with different query lengths (40, 60, 80, 100 bp)
4. **Memory Usage** - Peak memory consumption during execution
5. **CPU Efficiency** - System vs user time, CPU utilization
