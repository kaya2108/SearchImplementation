import time
import gzip
import sys
import iv2py as iv

def load_fasta(filepath):
    sequences = []
    current_seq = []
    
    open_func = gzip.open if filepath.endswith('.gz') else open
    
    with open_func(filepath, 'rt') as f:
        for line in f:
            line = line.strip()
            if line.startswith('>'):
                if current_seq:
                    sequences.append(''.join(current_seq))
                    current_seq = []
            else:
                current_seq.append(line)
        
        if current_seq:
            sequences.append(''.join(current_seq))
    
    return sequences

def search_queries(fm_index, queries):
    total_hits = 0
    for query in queries:
        results = fm_index.search(query)
        positions = [pos for seq_idx, pos in results]
        total_hits += len(positions)
    return total_hits

# Get query count from command line argument
if len(sys.argv) != 2:
    print("Please provide the number of queries to search as a command line argument.")
    print("Usage: python fmindex_search_querrycount.py <query_count>")
    sys.exit(1)

query_count = int(sys.argv[1])

# Load FM-index
start_load = time.time()
fm_index = iv.fmindex("../data/fm_index.bin")
load_time = time.time() - start_load
print(f"FM-index loaded in {load_time:.4f}s")

# Load queries
queries_100 = load_fasta("../data/illumina_reads_100.fasta.gz")
test_queries = queries_100[:query_count]
print(f"{len(test_queries):,} queries of length 100 bp: ")

# Search
start_search = time.time()
total_hits = search_queries(fm_index, test_queries)
search_time = time.time() - start_search

print(f"\nResults:")
print(f"  Query count: {len(test_queries):,}")
print(f"  Query length: 100 bp")
print(f"  Load time: {load_time:.4f}s")
print(f"  Search time: {search_time:.4f}s")
print(f"  Total time: {load_time + search_time:.4f}s")
print(f"  Hits found: {total_hits:,}")