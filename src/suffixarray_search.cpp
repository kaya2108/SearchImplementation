#include <divsufsort.h>
#include <sstream>
#include <algorithm>
#include <chrono>
#include <iomanip>
#include <vector>

#include <seqan3/alphabet/nucleotide/dna5.hpp>
#include <seqan3/argument_parser/all.hpp>
#include <seqan3/core/debug_stream.hpp>
#include <seqan3/io/sequence_file/all.hpp>
#include <seqan3/search/fm_index/fm_index.hpp>
#include <seqan3/search/search.hpp>

// Compare suffix starting at position 'suffix_pos' with query
int compareSuffix(std::vector<seqan3::dna5> const& reference,
                  saidx_t suffix_pos,
                  std::vector<seqan3::dna5> const& query) {
    size_t cmp_len = std::min(query.size(), reference.size() - suffix_pos);
    
    for (size_t i = 0; i < cmp_len; ++i) {
        if (reference[suffix_pos + i] < query[i]) {
            return -1;
        } else if (reference[suffix_pos + i] > query[i]) {
            return 1;
        }
    }
    
    if (cmp_len == query.size()) {
        return 0;
    }
    
    return -1;
}

// Binary search to find the leftmost occurrence
saidx_t binary_search_left(std::vector<saidx_t> const& sa, 
                            std::vector<seqan3::dna5> const& reference,
                            std::vector<seqan3::dna5> const& query) {
    saidx_t left = 0;
    saidx_t right = sa.size();
    
    while (left < right) {
        saidx_t mid = left + (right - left) / 2;
        int cmp = compareSuffix(reference, sa[mid], query);
        
        if (cmp < 0) {
            left = mid + 1;
        } else {
            right = mid;
        }
    }
    
    return left;
}

// Binary search to find the rightmost occurrence
saidx_t binary_search_right(std::vector<saidx_t> const& sa,
                             std::vector<seqan3::dna5> const& reference,
                             std::vector<seqan3::dna5> const& query) {
    saidx_t left = 0;
    saidx_t right = sa.size();
    
    while (left < right) {
        saidx_t mid = left + (right - left) / 2;
        int cmp = compareSuffix(reference, sa[mid], query);
        
        if (cmp <= 0) {
            left = mid + 1;
        } else {
            right = mid;
        }
    }
    
    return left;
}

struct BenchmarkResult {
    size_t num_queries;
    size_t query_length;
    double construction_time;
    double search_time;
    double total_time;
    size_t hits;
};

int main(int argc, char const* const* argv) {
    seqan3::argument_parser parser{"suffixarray_search", argc, argv, seqan3::update_notifications::off};

    parser.info.author = "SeqAn-Team";
    parser.info.version = "1.0.0";

    auto reference_file = std::filesystem::path{};
    parser.add_option(reference_file, '\0', "reference", "path to the reference file");

    auto query_file = std::filesystem::path{};
    parser.add_option(query_file, '\0', "query", "path to the query file");

    auto number_of_queries = size_t{100};
    parser.add_option(number_of_queries, '\0', "query_ct", "number of query, if not enough queries, these will be duplicated");

    try {
         parser.parse();
    } catch (seqan3::argument_parser_error const& ext) {
        seqan3::debug_stream << "Parsing error. " << ext.what() << "\n";
        return EXIT_FAILURE;
    }

    auto total_start = std::chrono::high_resolution_clock::now();

    // loading our files
    auto reference_stream = seqan3::sequence_file_input{reference_file};
    auto query_stream     = seqan3::sequence_file_input{query_file};

    // read reference into memory
    std::vector<seqan3::dna5> reference;
    for (auto& record : reference_stream) {
        auto r = record.sequence();
        reference.insert(reference.end(), r.begin(), r.end());
    }

    // read query into memory
    std::vector<std::vector<seqan3::dna5>> queries;
    for (auto& record : query_stream) {
        queries.push_back(record.sequence());
    }

    size_t query_length = queries.empty() ? 0 : queries[0].size();

    // Check if we have enough queries
    if (queries.size() < number_of_queries) {
        seqan3::debug_stream << "Error: Not enough queries in file. ";
        seqan3::debug_stream << "Requested: " << number_of_queries << ", Available: " << queries.size() << "\n";
        return EXIT_FAILURE;
    }

    std::cout << "Processing " << number_of_queries << " queries (length " << query_length << " bp)...\n";
    // Array that should hold the future suffix array
    std::vector<saidx_t> suffixarray;
    suffixarray.resize(reference.size());

    // Start timing - SA construction
    auto start_sa = std::chrono::high_resolution_clock::now();

    // Construct suffix array using libdivsufsort
    sauchar_t const* str = reinterpret_cast<sauchar_t const*>(reference.data());
    divsufsort(str, suffixarray.data(), reference.size());

    auto end_sa = std::chrono::high_resolution_clock::now();
    double sa_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_sa - start_sa).count() / 1000.0;

    std::cout << "  Construction time: " << std::fixed << std::setprecision(4) << sa_time << "s\n";

    // Start timing - search
    auto start_search = std::chrono::high_resolution_clock::now();

    size_t total_matches = 0;
    for (auto& q : queries) {
        saidx_t left = binary_search_left(suffixarray, reference, q);
        saidx_t right = binary_search_right(suffixarray, reference, q);
        total_matches += (right - left);
    }

    auto end_search = std::chrono::high_resolution_clock::now();
    double search_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_search - start_search).count() / 1000.0;

    auto total_end = std::chrono::high_resolution_clock::now();
    double total_time = std::chrono::duration_cast<std::chrono::milliseconds>(total_end - total_start).count() / 1000.0;

    std::cout << "  Search time: " << std::fixed << std::setprecision(4) << search_time << "s\n";
    std::cout << "  Total time: " << std::fixed << std::setprecision(4) << total_time << "s\n";
    std::cout << "  Hits found: " << total_matches << "\n\n";

    return 0;
}