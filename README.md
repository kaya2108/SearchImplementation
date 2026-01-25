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

## Notes on Large Files (Full Genome)

This repository also supports running the **C++ FM-index pipeline on the full GRCh38 human genome** (RefSeq assembly **GCF_000001405.26**). Since the full genome FASTA is large, it is **not included** in the repository and must be downloaded separately.

### 1) Download GRCh38 (GCF_000001405.26) from NCBI

Download the genome from the NCBI Datasets page:

* https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001405.26/


### 2) Compress the genome FASTA

From the repository root:

```bash
gzip -c GCF_000001405.26_GRCh38_genomic.fna > data/hg38_full_genome.fna.gz
```

### 3) Run the C++ benchmarks on the full genome

Run the C++ benchmark script as normal.


Typical full-genome runs will take longer and require significantly more memory than the partial-genome benchmarks.

---


## Running Benchmarks

Both benchmark scripts support command-line flags so you can run only specific methods/tests.
If no options are given, the scripts run **everything** by default.

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

#### Python Benchmark Options

**Methods**
- `--naive` : Run naive search benchmark
- `--suffix` : Run suffix array benchmarks
- `--fm` : Run FM-index benchmarks

**Tests**
- `--counts` : Run query-count benchmarks (runtime + memory via `/usr/bin/time -v`)
- `--ql` : Run query-length benchmarks (runtime only)

**Other**
- `--no-construct` : Skip FM-index construction step
- `--all-except-naive` : Run everything except naive search
- `-h, --help` : Show help

#### Examples

Run everything (default):
```bash
./benchmark_py.sh
```

Run only suffix query-count benchmark:
```bash
./benchmark_py.sh --suffix --counts
```

Run only FM-index query-length benchmark:
```bash
./benchmark_py.sh --fm --ql
```

Run query-count benchmarks for both suffix + FM:
```bash
./benchmark_py.sh --counts
```

Skip FM-index construction:
```bash
./benchmark_py.sh --fm --counts --no-construct
```

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

#### C++ Benchmark Options

**Methods**
- `--naive` : Run naive search benchmark
- `--suffix` : Run suffix array benchmarks
- `--fm` : Run FM-index benchmarks

**Tests**
- `--counts` : Run query-count benchmarks (runtime + memory via `/usr/bin/time -v`)
- `--ql` : Run query-length benchmarks

**Index scope (FM only)**
- `--partial` : Only run partial genome index/queries
- `--full` : Only run full genome index/queries (only FM query-length benchmark)

**Build / construct**
- `--no-build` : Skip CMake build step
- `--no-construct` : Skip FM-index construction steps (assumes `.index` exists)

**Other**
- `-h, --help` : Show help

#### Examples

Run everything (default):
```bash
./benchmark_cpp.sh
```

Run only suffix query-count benchmark:
```bash
./benchmark_cpp.sh --suffix --counts
```

Run FM-index query-length benchmarks only on partial genome:
```bash
./benchmark_cpp.sh --fm --ql --partial
```

Run FM-index full genome query-length benchmarks without rebuilding index:
```bash
./benchmark_cpp.sh --fm --ql --full --no-construct
```

Skip building the C++ project:
```bash
./benchmark_cpp.sh --no-build --counts
```


**Output:** Results saved in `results/cpp/`

---

## Benchmark Results

After running the benchmarks, you'll find detailed results in the `results/` directory:

### Python Results (`results/python/`)
- `system_info.txt` - System specifications
- `naive_search_100.txt` - Naive search baseline (100 queries)
- `fmindex_construction.txt` - FM-index construction time and memory
- `suffix_querycounts.txt` - Suffix array performance vs query count
- `fmindex_querycounts.txt` - FM-index performance vs query count
- `suffix_querylengths.txt` - Suffix array performance vs query length
- `fmindex_querylengths.txt` - FM-index performance vs query length

### C++ Results (`results/cpp/`)
- `system_info.txt` - System specifications
- `naive_search_100.txt` - Naive search baseline (100 queries)
- `fmindex_construction.txt` - FM-index construction time and memory (partial genome)
- `fmindex_construction_full_genome.txt` - FM-index construction time and memory (full genome)
- `suffix_querycounts.txt` - Suffix array performance vs query count
- `fmindex_querycounts.txt` - FM-index performance vs query count (partial genome)
- `suffix_querylengths.txt` - Suffix array performance vs query length
- `fmindex_querylengths.txt` - FM-index performance vs query length (partial genome)
- `fmindex_querylengths_full_genome.txt` - FM-index performance vs query length (full genome)

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
