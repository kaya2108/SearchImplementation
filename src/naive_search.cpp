#include <sstream>
#include <chrono>
#include <iomanip>

#include <seqan3/alphabet/nucleotide/dna5.hpp>
#include <seqan3/argument_parser/all.hpp>
#include <seqan3/core/debug_stream.hpp>
#include <seqan3/io/sequence_file/all.hpp>
#include <seqan3/search/fm_index/fm_index.hpp>
#include <seqan3/search/search.hpp>

// prints out all occurences of query inside of ref
size_t findOccurences(std::vector<seqan3::dna5> const& ref, std::vector<seqan3::dna5> const& query) {
    if (query.empty() || ref.empty() || query.size() > ref.size()) {
        return 0;
    }
    
    size_t match_count = 0;
    
    // Naive search: slide the query over the reference
    for (size_t i = 0; i <= ref.size() - query.size(); ++i) {
        bool match = true;
        
        // Check if query matches at position i
        for (size_t j = 0; j < query.size(); ++j) {
            if (ref[i + j] != query[j]) {
                match = false;
                break;
            }
        }
        
        if (match) {
            match_count++;
        }
    }
    
    return match_count;
}

int main(int argc, char const* const* argv) {
    seqan3::argument_parser parser{"naive_search", argc, argv, seqan3::update_notifications::off};

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

    // loading our files
    auto reference_stream = seqan3::sequence_file_input{reference_file};
    auto query_stream     = seqan3::sequence_file_input{query_file};

    // read reference into memory
    std::vector<std::vector<seqan3::dna5>> reference;
    size_t total_ref_size = 0;
    for (auto& record : reference_stream) {
        reference.push_back(record.sequence());
        total_ref_size += record.sequence().size();
    }

    // read query into memory
    std::vector<std::vector<seqan3::dna5>> queries;
    for (auto& record : query_stream) {
        queries.push_back(record.sequence());
    }

    size_t query_length = queries.empty() ? 0 : queries[0].size();
    size_t available_queries = queries.size();

    // Use the requested number of queries (or available if less)
    number_of_queries = std::min(number_of_queries, available_queries);
    
    // Duplicate queries if needed
    while (queries.size() < number_of_queries) {
        auto old_count = queries.size();
        queries.resize(2 * old_count);
        std::copy_n(queries.begin(), old_count, queries.begin() + old_count);
    }
    queries.resize(number_of_queries);

    std::cout << "Reference genome: " << total_ref_size << " base pairs\n";
    std::cout << "Total queries available (length " << query_length << "): " << available_queries << "\n";
    std::cout << "Testing with " << number_of_queries << " queries (length " << query_length << ")\n";
    std::cout << "\n[Naive Search]\n";
    std::cout << "Running Naive Search\n";
    std::cout << "Processing " << number_of_queries << " queries\n";

    // Start timing - search
    auto start_search = std::chrono::high_resolution_clock::now();

    //! search for all occurences of queries inside of reference
    size_t total_matches = 0;
    size_t processed = 0;
    
    for (auto& r : reference) {
        for (auto& q : queries) {
            total_matches += findOccurences(r, q);
            processed++;
            
            // Print progress at first query and last query
            if (processed == 1 || processed == number_of_queries) {
                auto current_time = std::chrono::high_resolution_clock::now();
                auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(current_time - start_search).count() / 1000.0;
                double qps = processed / elapsed;
                
                std::cout << "Progress: " << std::setw(10) << processed << "/" << number_of_queries 
                          << " (" << std::fixed << std::setprecision(1) << (100.0 * processed / number_of_queries) << "%) - "
                          << std::setw(10) << std::fixed << std::setprecision(2) << elapsed << "s - "
                          << std::setw(10) << std::fixed << std::setprecision(1) << qps << " q/s - "
                          << total_matches << " hits\n";
            }
        }
    }

    auto end_search = std::chrono::high_resolution_clock::now();
    auto search_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_search - start_search).count() / 1000.0;

    std::cout << "\nSearch completed in " << std::fixed << std::setprecision(2) << search_time << "s\n";
    std::cout << "Total hits found: " << total_matches << "\n";

    return 0;
}