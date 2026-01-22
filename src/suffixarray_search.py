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

class SuffixArraySearch:    
    def __init__(self, reference):
        self.reference = reference
        self.construction_time = 0
        
        start = time.time()
        self.sa = iv.create_suffixarray(reference)
        self.construction_time = time.time() - start
    
    def search(self, query):
        results = []
        query_len = len(query)
        n = len(self.sa)
        
        # Binary search for start of matching range
        left, right = 0, n - 1
        start_idx = n
        
        while left <= right:
            mid = (left + right) // 2
            pos = self.sa[mid]
            
            if pos + query_len <= len(self.reference):
                cmp_result = self.reference[pos:pos + query_len]
                
                if cmp_result >= query:
                    start_idx = mid
                    right = mid - 1
                else:
                    left = mid + 1
            else:
                right = mid - 1
        
        # Binary search for end of matching range
        left, right = 0, n - 1
        end_idx = -1
        
        while left <= right:
            mid = (left + right) // 2
            pos = self.sa[mid]
            
            if pos + query_len <= len(self.reference):
                cmp_result = self.reference[pos:pos + query_len]
                
                if cmp_result <= query:
                    end_idx = mid
                    left = mid + 1
                else:
                    right = mid - 1
            else:
                right = mid - 1
        
        # Collect all matching positions
        if start_idx <= end_idx:
            for i in range(start_idx, end_idx + 1):
                pos = self.sa[i]
                if pos + query_len <= len(self.reference):
                    if self.reference[pos:pos + query_len] == query:
                        results.append(pos)
        
        return results

def benchmark_query_counts(query_count):
    reference_file = "hg38_partial.fasta.gz"
    references = load_fasta(reference_file)
    reference = references[0]
    print(f"Reference length: {len(reference):,} bp")
    
    queries_100 = load_fasta("illumina_reads_100.fasta.gz")
    
    test_queries = queries_100[:query_count]
    print(f"{len(test_queries):,} queries of length 100 bp\n")    
    # Build suffix array ONCE
    searcher = SuffixArraySearch(reference)
    print(f"Construction time for suffix array: {searcher.construction_time:.4f}s\n")
    
    # Search all queries
    start = time.time()
    total_hits = 0
    for query in test_queries:
        hits = searcher.search(query)
        total_hits += len(hits)
    search_time = time.time() - start
    
    # Results
    print(f"Results for {query_count:,} queries: ")
    print(f"Construction time: {searcher.construction_time:.4f}s")
    print(f"Search time:       {search_time:.4f}s")
    print(f"Total time:        {searcher.construction_time + search_time:.4f}s")
    print(f"Hits found:        {total_hits:,}")

def benchmark_query_lengths():
    reference_file = "hg38_partial.fasta.gz"
    references = load_fasta(reference_file)
    reference = references[0]
    print(f"Reference length: {len(reference):,} bp\n")
    
    searcher = SuffixArraySearch(reference)
    print(f"Construction time of suffix array: {searcher.construction_time:.4f}s\n")
    
    query_files = {
        40: "illumina_reads_40.fasta.gz",
        60: "illumina_reads_60.fasta.gz",
        80: "illumina_reads_80.fasta.gz",
        100: "illumina_reads_100.fasta.gz"
    }
    
    num_queries = 10000
    results = []

    for length in sorted(query_files.keys()):
        filename = query_files[length]
        print(f"\nQuery length: {length} bp")
        
        queries = load_fasta(filename)
        test_queries = queries[:min(num_queries, len(queries))]
        
        start = time.time()
        total_hits = 0
        for query in test_queries:
            hits = searcher.search(query)
            total_hits += len(hits)
        search_time = time.time() - start
        
        results.append({
            'length': length,
            'queries': len(test_queries),
            'search_time': search_time,
            'hits': total_hits
        })
        
        print(f"  Queries:     {len(test_queries):,}")
        print(f"  Search time: {search_time:.4f}s")
        print(f"  Hits found:  {total_hits:,}")
        print(f"  Time/query:  {search_time/len(test_queries)*1000:.4f}ms")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # Qn 4) Query count mode (for time and memory benchmarking with /usr/bin/time -v)
        query_count = int(sys.argv[1])
        benchmark_query_counts(query_count)
    else:
        # Qn 5) Query length mode (time benchmarking only)
        benchmark_query_lengths()