// demultiplexing
#include "cellbarcode.h"

using std::string;
using std::unordered_map;
using namespace Rcpp;

// read annotation from files, the file should have two columns
// first column is cell id and second column is barcode.
// protocols with two barcodes are merged as one.
void Barcode::read_anno(string fn)
{
    check_file_exists(fn);
    std::ifstream infile(fn);
    string line;
    std::getline(infile, line); // skip header

    char sep;
    if (line.find(",") != string::npos)
    {
        sep = ',';
    }
    else if (line.find("\t") != string::npos)
    {
        sep = '\t';
    }
    else
    {
        Rcpp::stop("the annotation file should be comma or tab separated");
    }

    while(std::getline(infile, line))
    {
        std::stringstream linestream(line);
        if (line.size() < 3){
            continue;
        }
        string cell_id;
        string barcode;

        std::getline(linestream, cell_id, sep);
        std::getline(linestream, barcode, sep);

        barcode_dict[barcode] = cell_id;

        if (std::find(cellid_list.begin(), cellid_list.end(), cell_id) == cellid_list.end())
        {
            cellid_list.push_back(cell_id);
        }
        
        barcode_list.push_back(barcode);
    }
}

void Barcode::set_threads(int nthreads)
{
    nthreads_ = nthreads;
    t_pool_ = new asio::thread_pool(std::max(nthreads - 1, 1));
}

unordered_map<string, string> Barcode::get_count_file_path(string out_dir)
{
    string csv_fmt = ".csv";
    unordered_map<string, string> out_fn_dict;
    for(const auto& n : cellid_list) 
    {
        out_fn_dict[n] = join_path(out_dir, n+csv_fmt);
    }
    return out_fn_dict;
}

string Barcode::get_closest_match(string const &bc_seq, int max_mismatch)
{
    if (barcode_dict.find(bc_seq) != barcode_dict.end())
    {
        return bc_seq;
    }
    int sml1st = std::numeric_limits<int>::max();
    int sml2ed = std::numeric_limits<int>::max();
    std::vector<int> hamming_dists;
    hamming_dists.reserve(barcode_list.size());
    string closest_match;

    if (barcode_list.size() < 256) {
        for (int i = 0; i < barcode_list.size(); i++)
        {
            hamming_dists[i] = hamming_distance(barcode_list[i], bc_seq);
        }
    }
    else if (barcode_list.size() < 1024)
    {
        asio::post(*t_pool_, [&] () {
            for (int i = 0; i < barcode_list.size() / 2; i++)
            {
                hamming_dists[i] = hamming_distance(barcode_list[i], bc_seq);
            }
        });

        for (int i = barcode_list.size() / 2; i < barcode_list.size(); i++)
        {
            hamming_dists[i] = hamming_distance(barcode_list[i], bc_seq);
        }
    }
    else
    {
        const int CHUNK_SIZE = barcode_list.size() / 4;

        for (int i = 0; i < 3; i++) {
            asio::post(*t_pool_, [&, i] () {
                for (int j = i*CHUNK_SIZE; j < (i+1) * CHUNK_SIZE; j++)
                {
                    hamming_dists[j] = hamming_distance(barcode_list[j], bc_seq);
                }
            });
        }

        for (int j = 3*CHUNK_SIZE; j < barcode_list.size(); j++)
        {
            hamming_dists[j] = hamming_distance(barcode_list[j], bc_seq);
        }
    }

    t_pool_->join();

    for (int i = 0; i < hamming_dists.size(); i++)
    {
        string const &bc = barcode_list[i];
        int dist = hamming_dists[i];
        if (dist <= max_mismatch)
        {
            if (dist < sml1st)
            {
                sml1st = dist;
                closest_match = bc;
            }
            else if (sml1st < dist && dist <= sml2ed)
            {
                sml2ed = dist;
            }
        }
    }

    if (sml1st < sml2ed)
    {
        return closest_match;
    }
    else
    {
        return string();
    }

}

std::ostream& operator<< (std::ostream& out, const Barcode& obj)
{
    for( const auto& n : obj.barcode_dict ) 
    {
        out << "Barcode:[" << n.first << "] Cell Id:[" << n.second << "]\n";
    }
    return out;
}
