#!/bin/bash

# Python Benchmark
# Tests: Naive Search, Suffix Array, FM-Index

# Configuration
DATA_DIR="./data"
SRC_DIR="./src"

# Create results directory
mkdir -p results/python

# Print system information
echo "System Information" | tee results/python/system_info.txt
lscpu | grep -E "^CPU\(s\)|^Model name" | tee -a results/python/system_info.txt
free -h | grep Mem | tee -a results/python/system_info.txt
python3 --version | tee -a results/python/system_info.txt
echo "" | tee -a results/python/system_info.txt
#Naive Search Benchmark
echo "Naive Search Benchmark (100 querries of length 100):"
cd "$SRC_DIR"
/usr/bin/time -v python3 naive_search.py > ../results/python/naive_search_100.txt 2>&1
cd ..
echo "Done. Results: results/python/naive_search_100.txt"
echo ""

#Query Count Benchmarks (Runtime + Memory)

# FM-Index Construction
echo "FM-Index Construction" > results/python/fmindex_construction.txt
cd "$SRC_DIR"
echo "" >> ../results/python/fmindex_construction.txt
/usr/bin/time -v python3 fmindex_construct.py >> ../results/python/fmindex_construction.txt 2>&1
cd ..
echo ""


echo "Query Count Benchmarks"
echo "Testing 10^3, 10^4, 10^5, 10^6 queries (length 100)"
echo ""


# Define query counts
query_counts=(1000 10000 100000)


# Suffix Array (Query Counts)
echo "Suffix Array - Query Count Benchmark" > results/python/task4_suffix_counts.txt
echo "" >> results/python/task4_suffix_counts.txt

for count in "${query_counts[@]}"; do
    echo "Running Suffix Array with $count queries..."
    echo "--- Query Count: $count ---" >> results/python/task4_suffix_counts.txt
    cd "$SRC_DIR"
    /usr/bin/time -v python3 suffixarray_search.py $count >> ../results/python/task4_suffix_counts.txt 2>&1
    cd ..
    echo "" >> results/python/task4_suffix_counts.txt
done
echo ""

# FM-Index (Query Counts)
echo "FM-Index - Query Count Benchmark" > results/python/task4_fmindex_counts.txt
echo "" >> results/python/task4_fmindex_counts.txt

for count in "${query_counts[@]}"; do
    echo "Running FM-Index with $count queries..."
    echo "--- Query Count: $count ---" >> results/python/task4_fmindex_counts.txt

    cd "$SRC_DIR"
    /usr/bin/time -v python3 fmindex_search_querrycount.py $count >> ../results/python/task4_fmindex_counts.txt 2>&1
    cd ..
    echo "" >> results/python/task4_fmindex_counts.txt
done

# Query length benchmarks (Runtime Only)
echo "Query Length Benchmarks"
echo "Testing lengths 40, 60, 80, 100 with 10,000 queries each"
echo ""

# Suffix Array
echo "Running Suffix Array (query lengths):"
cd "$SRC_DIR"
python3 suffixarray_search.py > ../results/python/task5_suffix_lengths.txt 2>&1
cd ..
echo "Done. Results: /results/python/task5_suffix_lengths.txt"
echo ""

# FM-Index
echo "Running FM-Index (query lengths):"
cd "$SRC_DIR"
python3 fmindex_querrylength.py > ../results/python/task5_fmindex_lengths.txt 2>&1
cd ..
echo "Done. Results: /results/python/task5_fmindex_lengths.txt"
echo ""


echo "Benchmarking complete. Results saved in /results/python/"