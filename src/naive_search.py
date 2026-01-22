import time
import gzip
from pathlib import Path
import iv2py as iv

def load_fasta(filepath):
    sequences = []
    current_seq = []
    
    open_func = gzip.open if filepath.endswith('.gz') else open
    
    with open_func(filepath, 'rt') as f:
        line_count = 0
        for line in f:
            line = line.strip()
            line_count += 1
            
            if line.startswith('>'):
                if current_seq:
                    sequences.append(''.join(current_seq))
                    current_seq = []
            else:
                current_seq.append(line)
        
        if current_seq:
            sequences.append(''.join(current_seq))
    return sequences


def naive_search(query, reference):
    positions = []
    ref_len = len(reference)
    query_len = len(query)
    
    for i in range(ref_len - query_len + 1):
        if reference[i:i + query_len] == query:
            positions.append(i)
            
    return positions


def benchmark_algorithm(queries, reference):
    print(f"Running Naive Search")
    print(f"Processing {len(queries)} queries")
    
    start = time.time()
    total_hits = 0
    
    progress_interval = max(100, len(queries) // 100)
    
    for idx, query in enumerate(queries):
        hits = naive_search(query, reference)
        total_hits += len(hits)
        
        if (idx + 1) % progress_interval == 0 or idx == 0:
            elapsed_so_far = time.time() - start
            percent = ((idx + 1) / len(queries)) * 100
            queries_per_sec = (idx + 1) / elapsed_so_far if elapsed_so_far > 0 else 0
            print(f"Progress: {idx + 1:>10}/{len(queries)} ({percent:>5.1f}%) - {elapsed_so_far:>8.2f}s - {queries_per_sec:>8.1f} q/s - {total_hits} hits")
    
    elapsed = time.time() - start
    
    print(f"{algorithm_name} complete")
    print(f"Queries processed: {len(queries)}")
    print(f"Total hits found: {total_hits}")
    print(f"Total time: {elapsed:.4f}s")
    print(f"Time per query: {elapsed/len(queries)*1000:.4f}ms")
    print(f"Queries per second: {len(queries)/elapsed:.2f}")
    
    return elapsed, total_hits

# Load reference genome
reference_file = "hg38_partial.fasta.gz"
references = load_fasta(reference_file)

reference = references[0]
print(f"Reference genome: {len(reference):,} base pairs")

# Load queries of length 100 for benchmarking different query counts
queries_100 = load_fasta("illumina_reads_100.fasta.gz")
print(f"Total queries available (length 100): {len(queries_100):,}")

print(f"Testing with 100 queries (length 100)")
test_queries = queries_100[:100]
print("Naive Search")
benchmark_algorithm(test_queries, reference)