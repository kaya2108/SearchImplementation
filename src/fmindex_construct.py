import time
import gzip
from pathlib import Path
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

reference_file = "../data/hg38_partial.fasta.gz"
references = load_fasta(reference_file)
reference = references[0]
print(f"Reference length: {len(reference):,} bp")

start = time.time()
fm_index = iv.fmindex(reference=[reference])
construction_time = time.time() - start
print(f"FM-index construction completed in {construction_time:.4f}s")

# Save the index
index_path = "../data/fm_index.bin"
fm_index.save(index_path)
print(f"FM-index saved to {index_path}.")
