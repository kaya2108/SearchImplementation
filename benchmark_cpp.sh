#!/bin/bash

# C++ Benchmark
# Tests: Naive Search, Suffix Array, FM-Index


# Create results directory
mkdir -p results/cpp

# Print system information
echo "System Information" | tee results/cpp/system_info.txt
lscpu | grep -E "^CPU\(s\)|^Model name" | tee -a results/cpp/system_info.txt
free -h | grep Mem | tee -a results/cpp/system_info.txt
g++ --version | head -n1 | tee -a results/cpp/system_info.txt
echo "" | tee -a results/cpp/system_info.txt

# Build the project
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


#Naive Search Benchmark
echo "Running Naive Search (100 queries):"
./build/bin/naive_search --reference data/hg38_partial.fasta.gz --query data/illumina_reads_100.fasta.gz --query_ct 100 > results/cpp/naive_search_100.txt 2>&1
echo "Done. Results: results/cpp/naive_search_100.txt"


# FM-Index Construction
echo "FM-Index Construction" > results/cpp/fmindex_construction.txt
echo "" >> results/cpp/fmindex_construction.txt
/usr/bin/time -v ./build/bin/fmindex_construct --reference data/hg38_partial.fasta.gz --index data/hg38_partial.index >> results/cpp/fmindex_construction.txt 2>&1
echo ""

#FM-Index Construction (full genome)
echo "FM-Index Construction (full genome .fna.gz)" > results/cpp/fmindex_construction_full_genome.txt
echo "" >> results/cpp/fmindex_construction_full_genome.txt

/usr/bin/time -v ./build/bin/fmindex_construct \
  --reference data/hg38_full_genome.fna.gz \
  --index data/hg38_full_genome.index \
  >> results/cpp/fmindex_construction_full_genome.txt 2>&1

echo ""

# Query Count Benchmarks (Runtime + Memory)
echo "Query Count Benchmarks"
echo "Testing 10^3, 10^4, 10^5, 10^6 queries (length 100)"
echo ""

# Define query counts
query_counts=(1000 10000 100000)

# Suffix Array (Query Counts)
echo "Suffix Array - Query Count Benchmark" > results/cpp/suffix_querycounts.txt
echo "" >> results/cpp/suffix_querycounts.txt

for count in "${query_counts[@]}"; do
    echo "Running Suffix Array with $count queries..."
    echo "--- Query Count: $count ---" >> results/cpp/suffix_querycounts.txt
    /usr/bin/time -v ./build/bin/suffixarray_search --reference data/hg38_partial.fasta.gz --query data/illumina_reads_100.fasta.gz --query_ct $count >> results/cpp/suffix_querycounts.txt 2>&1
    echo "" >> results/cpp/suffix_querycounts.txt
done
echo ""

# FM-Index (Query Counts)
echo "FM-Index - Query Count Benchmark" > results/cpp/fmindex_querycounts.txt
echo "" >> results/cpp/fmindex_querycounts.txt

for count in "${query_counts[@]}"; do
    echo "Running FM-Index with $count queries..."
    echo "--- Query Count: $count ---" >> results/cpp/fmindex_querycounts.txt
    /usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_partial.index --query data/illumina_reads_100.fasta.gz --query_ct $count --errors 0 >> results/cpp/fmindex_querycounts.txt 2>&1
    echo "" >> results/cpp/fmindex_querycounts.txt
done
echo ""

# Query length benchmarks (Runtime Only)
echo "Query Length Benchmarks"
echo "Testing lengths 40, 60, 80, 100 with 10,000 queries each"
echo ""

# Suffix Array (Query Lengths)
echo "Running Suffix Array (query lengths):"
echo ""
./build/bin/suffixarray_search --reference data/hg38_partial.fasta.gz --query data/illumina_reads_40.fasta.gz --query_ct 10000 > results/cpp/suffix_querylengths.txt 2>&1
echo ""
./build/bin/suffixarray_search --reference data/hg38_partial.fasta.gz --query data/illumina_reads_60.fasta.gz --query_ct 10000 >> results/cpp/suffix_querylengths.txt 2>&1
echo ""
./build/bin/suffixarray_search --reference data/hg38_partial.fasta.gz --query data/illumina_reads_80.fasta.gz --query_ct 10000 >> results/cpp/suffix_querylengths.txt 2>&1
echo ""
./build/bin/suffixarray_search --reference data/hg38_partial.fasta.gz --query data/illumina_reads_100.fasta.gz --query_ct 10000 >> results/cpp/suffix_querylengths.txt 2>&1
echo "Done. Results: results/cpp/suffix_querylengths.txt"
echo ""

#FM-Index (Query Lengths)
echo "Running FM-Index (query lengths):"
echo "=== Query length 40 ===" > results/cpp/fmindex_querylengths.txt
/usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_partial.index --query data/illumina_reads_40.fasta.gz --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths.txt 2>&1
echo "" >> results/cpp/fmindex_querylengths.txt

echo "=== Query length 60 ===" >> results/cpp/fmindex_querylengths.txt
/usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_partial.index --query data/illumina_reads_60.fasta.gz --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths.txt 2>&1
echo "" >> results/cpp/fmindex_querylengths.txt

echo "=== Query length 80 ===" >> results/cpp/fmindex_querylengths.txt
/usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_partial.index --query data/illumina_reads_80.fasta.gz --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths.txt 2>&1
echo "" >> results/cpp/fmindex_querylengths.txt

echo "=== Query length 100 ===" >> results/cpp/fmindex_querylengths.txt
/usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_partial.index --query data/illumina_reads_100.fasta.gz --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths.txt 2>&1
echo "" >> results/cpp/fmindex_querylengths.txt
echo "Done. Results: results/cpp/fmindex_querylengths.txt"


#FM-Index (Query Lengths)(full genome)
echo "Running FM-Index (query lengths):"
echo "=== Query length 40 ===" > results/cpp/fmindex_querylengths_full_genome.txt
/usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_full_genome.index --query data/illumina_reads_40.fasta.gz --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths_full_genome.txt 2>&1
echo "" >> results/cpp/fmindex_querylengths_full_genome.txt

echo "=== Query length 60 ===" >> results/cpp/fmindex_querylengths_full_genome.txt
/usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_full_genome.index --query data/illumina_reads_60.fasta.gz --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths_full_genome.txt 2>&1
echo "" >> results/cpp/fmindex_querylengths_full_genome.txt

echo "=== Query length 80 ===" >> results/cpp/fmindex_querylengths_full_genome.txt
/usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_full_genome.index --query data/illumina_reads_80.fasta.gz --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths_full_genome.txt 2>&1
echo "" >> results/cpp/fmindex_querylengths_full_genome.txt
echo "=== Query length 100 ===" >> results/cpp/fmindex_querylengths_full_genome.txt
/usr/bin/time -v ./build/bin/fmindex_search --index data/hg38_full_genome.index --query data/illumina_reads_100.fasta.gz --query_ct 10000 --errors 0 >> results/cpp/fmindex_querylengths_full_genome.txt 2>&1
echo "" >> results/cpp/fmindex_querylengths_full_genome.txt
echo "Done. Results: results/cpp/fmindex_querylengths_full_genome.txt"

echo "Benchmarking complete. Results saved in results/cpp/"