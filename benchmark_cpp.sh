#!/bin/bash

# C++ Benchmark
# Tests: Naive Search, Suffix Array, FM-Index

set -e

# Argument parsing

RUN_NAIVE=0
RUN_SUFFIX=0
RUN_FM=0

RUN_COUNTS=0
RUN_QL=0

DO_BUILD=1
DO_CONSTRUCT=1

DO_PARTIAL=1
DO_FULL=1

usage () {
  cat <<EOF
Usage: $0 [options]

If no options are given, runs everything (build + naive + suffix + fm + counts + ql + construct partial+full).

Methods:
  --naive           Run naive benchmark
  --suffix          Run suffix array benchmarks
  --fm              Run FM-index benchmarks

Tests:
  --counts          Run query-count benchmarks (time -v)
  --ql              Run query-length benchmarks

Index scope (FM only):
  --partial         Only run partial genome index/queries
  --full            Only run full genome index/queries (only FM index query lengths)

Build / construct:
  --no-build        Skip cmake build step
  --no-construct    Skip FM-index construction steps (assumes index exists)

Other:
  -h, --help        Show help

Examples:
  $0
  $0 --suffix --counts
  $0 --fm --ql --partial
  $0 --fm --full --no-construct
  $0 --counts                 # counts for suffix + fm
EOF
}

if [ $# -eq 0 ]; then
  RUN_NAIVE=1
  RUN_SUFFIX=1
  RUN_FM=1
  RUN_COUNTS=1
  RUN_QL=1
  DO_BUILD=1
  DO_CONSTRUCT=1
  DO_PARTIAL=1
  DO_FULL=1
else
  # start with nothing selected; infer defaults based on what user gave
  DO_PARTIAL=0
  DO_FULL=0

  for arg in "$@"; do
    case "$arg" in
      --naive) RUN_NAIVE=1 ;;
      --suffix) RUN_SUFFIX=1 ;;
      --fm) RUN_FM=1 ;;
      --counts) RUN_COUNTS=1 ;;
      --ql) RUN_QL=1 ;;
      --no-build) DO_BUILD=0 ;;
      --no-construct) DO_CONSTRUCT=0 ;;
      --partial) DO_PARTIAL=1 ;;
      --full) DO_FULL=1 ;;
      -h|--help) usage; exit 0 ;;
      *)
        echo "Unknown option: $arg"
        echo ""
        usage
        exit 1
        ;;
    esac
  done

  # If user did not specify partial/full -> do both
  if [ $DO_PARTIAL -eq 0 ] && [ $DO_FULL -eq 0 ]; then
    DO_PARTIAL=1
    DO_FULL=1
  fi

  # If user chose tests but no methods -> run suffix+fm by default
  if [ $RUN_COUNTS -eq 1 ] || [ $RUN_QL -eq 1 ]; then
    if [ $RUN_SUFFIX -eq 0 ] && [ $RUN_FM -eq 0 ]; then
      RUN_SUFFIX=1
      RUN_FM=1
    fi
  fi

  # If user chose methods but no tests -> run both tests by default
  if [ $RUN_SUFFIX -eq 1 ] || [ $RUN_FM -eq 1 ]; then
    if [ $RUN_COUNTS -eq 0 ] && [ $RUN_QL -eq 0 ]; then
      RUN_COUNTS=1
      RUN_QL=1
    fi
  fi

  # If user specified only scope (partial/full) but no method/test, run defaults
    if [ $RUN_SUFFIX -eq 0 ] && [ $RUN_FM -eq 0 ] && [ $RUN_COUNTS -eq 0 ] && [ $RUN_QL -eq 0 ]; then
        RUN_SUFFIX=1
        RUN_FM=1
        RUN_COUNTS=1
        RUN_QL=1
    fi

fi

# Setup + system info
mkdir -p results/cpp

echo "System Information" | tee results/cpp/system_info.txt
lscpu | grep -E "^CPU\(s\)|^Model name" | tee -a results/cpp/system_info.txt
free -h | grep Mem | tee -a results/cpp/system_info.txt
g++ --version | head -n1 | tee -a results/cpp/system_info.txt
echo "" | tee -a results/cpp/system_info.txt

# Build
if [ $DO_BUILD -eq 1 ]; then
  echo "Building C++ project..."
  if [ ! -d "build" ]; then
    mkdir -p build
    cd build
    cmake ..
    cd ..
  fi

  cd build
  cmake --build .
  cd ..
  echo "Build complete."
  echo ""
else
  echo "Skipping build (--no-build)"
  echo ""
fi

# Naive Search Benchmark
if [ $RUN_NAIVE -eq 1 ]; then
  echo "Running Naive Search (100 queries):"
  ./build/bin/naive_search \
    --reference data/hg38_partial.fasta.gz \
    --query data/illumina_reads_100.fasta.gz \
    --query_ct 100 \
    > results/cpp/naive_search_100.txt 2>&1
  echo "Done. Results: results/cpp/naive_search_100.txt"
  echo ""
fi

# FM-Index Construction
if [ $RUN_FM -eq 1 ] && [ $DO_CONSTRUCT -eq 1 ]; then
  if [ $DO_PARTIAL -eq 1 ]; then
    echo "FM-Index Construction" > results/cpp/fmindex_construction.txt
    echo "" >> results/cpp/fmindex_construction.txt
    /usr/bin/time -v ./build/bin/fmindex_construct \
      --reference data/hg38_partial.fasta.gz \
      --index data/hg38_partial.index \
      >> results/cpp/fmindex_construction.txt 2>&1
    echo ""
  fi

  if [ $DO_FULL -eq 1 ]; then
    echo "FM-Index Construction (full genome .fna.gz)" > results/cpp/fmindex_construction_full_genome.txt
    echo "" >> results/cpp/fmindex_construction_full_genome.txt
    /usr/bin/time -v ./build/bin/fmindex_construct \
      --reference data/hg38_full_genome.fna.gz \
      --index data/hg38_full_genome.index \
      >> results/cpp/fmindex_construction_full_genome.txt 2>&1
    echo ""
  fi
elif [ $RUN_FM -eq 1 ] && [ $DO_CONSTRUCT -eq 0 ]; then
  echo "Skipping FM-index construction (--no-construct)"
  echo ""
fi

# Query Count Benchmarks (Runtime + Memory)
if [ $RUN_COUNTS -eq 1 ]; then
  echo "Query Count Benchmarks"
  echo "Testing 10^3, 10^4, 10^5 queries (length 100)"
  echo ""

  query_counts=(1000 10000 100000)

  if [ $RUN_SUFFIX -eq 1 ]; then
    echo "Suffix Array - Query Count Benchmark" > results/cpp/suffix_querycounts.txt
    echo "" >> results/cpp/suffix_querycounts.txt

    for count in "${query_counts[@]}"; do
      echo "Running Suffix Array with $count queries..."
      echo "--- Query Count: $count ---" >> results/cpp/suffix_querycounts.txt
      /usr/bin/time -v ./build/bin/suffixarray_search \
        --reference data/hg38_partial.fasta.gz \
        --query data/illumina_reads_100.fasta.gz \
        --query_ct "$count" \
        >> results/cpp/suffix_querycounts.txt 2>&1
      echo "" >> results/cpp/suffix_querycounts.txt
    done
    echo ""
  fi

  if [ $RUN_FM -eq 1 ]; then
    if [ $DO_PARTIAL -eq 1 ]; then
      echo "FM-Index - Query Count Benchmark" > results/cpp/fmindex_querycounts.txt
      echo "" >> results/cpp/fmindex_querycounts.txt

      for count in "${query_counts[@]}"; do
        echo "Running FM-Index (partial) with $count queries..."
        echo "--- Query Count: $count ---" >> results/cpp/fmindex_querycounts.txt
        /usr/bin/time -v ./build/bin/fmindex_search \
          --index data/hg38_partial.index \
          --query data/illumina_reads_100.fasta.gz \
          --query_ct "$count" \
          --errors 0 \
          >> results/cpp/fmindex_querycounts.txt 2>&1
        echo "" >> results/cpp/fmindex_querycounts.txt
      done
      echo ""
    fi
  fi
fi

# Query length benchmarks (Runtime Only)
if [ $RUN_QL -eq 1 ]; then
  echo "Query Length Benchmarks"
  echo "Testing lengths 40, 60, 80, 100 with 10,000 queries each"
  echo ""

  if [ $RUN_SUFFIX -eq 1 ]; then
    echo "Running Suffix Array (query lengths):"
    echo "" > results/cpp/suffix_querylengths.txt

    ./build/bin/suffixarray_search --reference data/hg38_partial.fasta.gz --query data/illumina_reads_40.fasta.gz  --query_ct 10000 >> results/cpp/suffix_querylengths.txt 2>&1
    echo "" >> results/cpp/suffix_querylengths.txt
    ./build/bin/suffixarray_search --reference data/hg38_partial.fasta.gz --query data/illumina_reads_60.fasta.gz  --query_ct 10000 >> results/cpp/suffix_querylengths.txt 2>&1
    echo "" >> results/cpp/suffix_querylengths.txt
    ./build/bin/suffixarray_search --reference data/hg38_partial.fasta.gz --query data/illumina_reads_80.fasta.gz  --query_ct 10000 >> results/cpp/suffix_querylengths.txt 2>&1
    echo "" >> results/cpp/suffix_querylengths.txt
    ./build/bin/suffixarray_search --reference data/hg38_partial.fasta.gz --query data/illumina_reads_100.fasta.gz --query_ct 10000 >> results/cpp/suffix_querylengths.txt 2>&1

    echo "Done. Results: results/cpp/suffix_querylengths.txt"
    echo ""
  fi

  if [ $RUN_FM -eq 1 ]; then
    if [ $DO_PARTIAL -eq 1 ]; then
      echo "Running FM-Index (query lengths) [partial]:"
      echo "=== Query length 40 ===" > results/cpp/fmindex_querylengths.txt
      /usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_partial.index --query data/illumina_reads_40.fasta.gz  --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths.txt 2>&1
      echo "" >> results/cpp/fmindex_querylengths.txt

      echo "=== Query length 60 ===" >> results/cpp/fmindex_querylengths.txt
      /usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_partial.index --query data/illumina_reads_60.fasta.gz  --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths.txt 2>&1
      echo "" >> results/cpp/fmindex_querylengths.txt

      echo "=== Query length 80 ===" >> results/cpp/fmindex_querylengths.txt
      /usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_partial.index --query data/illumina_reads_80.fasta.gz  --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths.txt 2>&1
      echo "" >> results/cpp/fmindex_querylengths.txt

      echo "=== Query length 100 ===" >> results/cpp/fmindex_querylengths.txt
      /usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_partial.index --query data/illumina_reads_100.fasta.gz --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths.txt 2>&1
      echo "" >> results/cpp/fmindex_querylengths.txt

      echo "Done. Results: results/cpp/fmindex_querylengths.txt"
      echo ""
    fi

    if [ $DO_FULL -eq 1 ]; then
      echo "Running FM-Index (query lengths) [full genome]:"
      echo "=== Query length 40 ===" > results/cpp/fmindex_querylengths_full_genome.txt
      /usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_full_genome.index --query data/illumina_reads_40.fasta.gz  --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths_full_genome.txt 2>&1
      echo "" >> results/cpp/fmindex_querylengths_full_genome.txt

      echo "=== Query length 60 ===" >> results/cpp/fmindex_querylengths_full_genome.txt
      /usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_full_genome.index --query data/illumina_reads_60.fasta.gz  --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths_full_genome.txt 2>&1
      echo "" >> results/cpp/fmindex_querylengths_full_genome.txt

      echo "=== Query length 80 ===" >> results/cpp/fmindex_querylengths_full_genome.txt
      /usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_full_genome.index --query data/illumina_reads_80.fasta.gz  --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths_full_genome.txt 2>&1
      echo "" >> results/cpp/fmindex_querylengths_full_genome.txt

      echo "=== Query length 100 ===" >> results/cpp/fmindex_querylengths_full_genome.txt
      /usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_full_genome.index --query data/illumina_reads_100.fasta.gz --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths_full_genome.txt 2>&1
      echo "" >> results/cpp/fmindex_querylengths_full_genome.txt

      echo "Done. Results: results/cpp/fmindex_querylengths_full_genome.txt"
      echo ""
    fi
  fi
fi

echo "Benchmarking complete. Results saved in results/cpp/"


