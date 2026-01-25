#!/bin/bash

# Python Benchmark
# Tests: Naive Search, Suffix Array, FM-Index

set -e

# Configuration
DATA_DIR="./data"
SRC_DIR="./src"

# Argument parsing
RUN_NAIVE=0
RUN_SUFFIX=0
RUN_FM=0
RUN_COUNTS=0
RUN_QL=0
RUN_CONSTRUCT=1   

usage () {
  cat <<EOF
Usage: $0 [options]

If no options are given, runs everything (suffix+fm counts + query-lengths + fm construction).

Methods:
  --naive           Run naive benchmark (currently commented in script, but supported)
  --suffix          Run suffix array benchmarks
  --fm              Run FM-index benchmarks

Tests:
  --counts          Run query-count benchmarks (time -v)
  --ql              Run query-length benchmarks (runtime only)

Other:
  --no-construct    Skip FM-index construction step
  --all-except-naive    Run everything except naive search
  -h, --help        Show this help

Examples:
  $0
  $0 --suffix --counts
  $0 --fm --ql
  $0 --counts
  $0 --suffix --fm --counts --no-construct
EOF
}

if [ $# -eq 0 ]; then
  # default: run everything
  RUN_NAIVE=1
  RUN_SUFFIX=1
  RUN_FM=1
  RUN_COUNTS=1
  RUN_QL=1
else
  for arg in "$@"; do
    case "$arg" in
      --naive) RUN_NAIVE=1 ;;
      --suffix) RUN_SUFFIX=1 ;;
      --fm) RUN_FM=1 ;;
      --counts) RUN_COUNTS=1 ;;
      --ql) RUN_QL=1 ;;
      --no-construct) RUN_CONSTRUCT=0 ;;
      --all-except-naive)
        RUN_SUFFIX=1; RUN_FM=1; RUN_COUNTS=1; RUN_QL=1; RUN_CONSTRUCT=1
        ;;
      -h|--help) usage; exit 0 ;;
      *)
        echo "Unknown option: $arg"
        echo ""
        usage
        exit 1
        ;;
    esac
  done

  # If user chose tests but no methods -> run both suffix+fm by default
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
fi

# Create results directory
mkdir -p results/python

# Print system information
echo "System Information" | tee results/python/system_info.txt
lscpu | grep -E "^CPU\(s\)|^Model name" | tee -a results/python/system_info.txt
free -h | grep Mem | tee -a results/python/system_info.txt
python3 --version | tee -a results/python/system_info.txt
echo "" | tee -a results/python/system_info.txt

# Naive Search Benchmark
if [ $RUN_NAIVE -eq 1 ]; then
  echo "Naive Search Benchmark (100 queries of length 100):"
  cd "$SRC_DIR"
  /usr/bin/time -v python3 naive_search.py > ../results/python/naive_search_100.txt 2>&1
  cd ..
  echo "Done. Results: results/python/naive_search_100.txt"
  echo ""
fi

# FM-Index Construction
if [ $RUN_FM -eq 1 ] && [ $RUN_CONSTRUCT -eq 1 ]; then
  echo "FM-Index Construction" > results/python/fmindex_construction.txt
  cd "$SRC_DIR"
  echo "" >> ../results/python/fmindex_construction.txt
  /usr/bin/time -v python3 fmindex_construct.py >> ../results/python/fmindex_construction.txt 2>&1
  cd ..
  echo ""
fi

# Query Count Benchmarks (Runtime + Memory)
if [ $RUN_COUNTS -eq 1 ]; then
  echo "Query Count Benchmarks"
  echo "Testing 10^3, 10^4, 10^5 queries (length 100)"
  echo ""

  # Define query counts
  query_counts=(1000 10000 100000)

  if [ $RUN_SUFFIX -eq 1 ]; then
    echo "Suffix Array - Query Count Benchmark" > results/python/suffix_querycounts.txt
    echo "" >> results/python/suffix_querycounts.txt

    for count in "${query_counts[@]}"; do
      echo "Running Suffix Array with $count queries..."
      echo "--- Query Count: $count ---" >> results/python/suffix_querycounts.txt
      cd "$SRC_DIR"
      /usr/bin/time -v python3 suffixarray_search.py "$count" >> ../results/python/suffix_querycounts.txt 2>&1
      cd ..
      echo "" >> results/python/suffix_querycounts.txt
    done
    echo ""
  fi

  if [ $RUN_FM -eq 1 ]; then
    echo "FM-Index - Query Count Benchmark" > results/python/fmindex_querycounts.txt
    echo "" >> results/python/fmindex_querycounts.txt

    for count in "${query_counts[@]}"; do
      echo "Running FM-Index with $count queries..."
      echo "--- Query Count: $count ---" >> results/python/fmindex_querycounts.txt
      cd "$SRC_DIR"
      /usr/bin/time -v python3 fmindex_search_querrycount.py "$count" >> ../results/python/fmindex_querycounts.txt 2>&1
      cd ..
      echo "" >> results/python/fmindex_querycounts.txt
    done
    echo ""
  fi
fi

# Query length benchmarks (Runtime only)
if [ $RUN_QL -eq 1 ]; then
  echo "Query Length Benchmarks"
  echo "Testing lengths 40, 60, 80, 100 with 10,000 queries each"
  echo ""

  if [ $RUN_SUFFIX -eq 1 ]; then
    echo "Running Suffix Array (query lengths):"
    cd "$SRC_DIR"
    python3 suffixarray_search.py > ../results/python/suffix_querylengths.txt 2>&1
    cd ..
    echo "Done. Results: /results/python/suffix_querylengths.txt"
    echo ""
  fi

  if [ $RUN_FM -eq 1 ]; then
    echo "Running FM-Index (query lengths):"
    cd "$SRC_DIR"
    python3 fmindex_querrylength.py > ../results/python/fmindex_querylengths.txt 2>&1
    cd ..
    echo "Done. Results: /results/python/fmindex_querylengths.txt"
    echo ""
  fi
fi

echo "Benchmarking complete. Results saved in /results/python/"