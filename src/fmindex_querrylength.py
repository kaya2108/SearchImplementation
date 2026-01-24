import time
import gzip
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

# Load FM-index
start_load = time.time()
fm_index = iv.fmindex("../data/fm_index.bin")
load_time = time.time() - start_load
print(f"FM-index loaded in {load_time:.4f}s")

# Query files and lengths
query_files = {
    40: "../data/illumina_reads_40.fasta.gz",
    60: "../data/illumina_reads_60.fasta.gz",
    80: "../data/illumina_reads_80.fasta.gz",
    100: "../data/illumina_reads_100.fasta.gz"
}

num_queries = 10000

print("\nSearching with different query lengths (10,000 queries each):")

for query_length, query_file in query_files.items():
    print(f"\nProcessing queries of length {query_length} bp: ")
    
    # Load queries
    queries = load_fasta(query_file)
    test_queries = queries[:min(num_queries, len(queries))]
    
    # Search
    start_search = time.time()
    total_hits = search_queries(fm_index, test_queries)
    search_time = time.time() - start_search
    
    print(f"  Query count: {len(test_queries):,}")
    print(f"  Search time: {search_time:.4f}s")
    print(f"  Hits found: {total_hits:,}")
