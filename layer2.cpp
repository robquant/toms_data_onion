#include <fstream>
#include <iostream>
#include <vector>
#include <string>
#include <algorithm>
#include <cstdint>

using namespace std;
vector<char> read_file(const string &fname)
{
    ifstream inf(fname);
    string line;
    vector<string> file;
    while (getline(inf, line, '\n'))
    {
        file.push_back(line);
    }
    vector<char> cleaned;
    for (auto line : file)
    {
        copy(line.begin(), line.end(), back_inserter<vector<char>>(cleaned));
    }
    return cleaned;
}

char *decode_group(const char group[5])
{
    static char decoded[4];
    uint32_t total = 0;
    uint32_t m = 1;
    for (int i = 4; i >= 0; i--)
    {
        total += (uint32_t(group[i]) - 33) * m;
        m *= 85;
    }
    char *result = reinterpret_cast<char *>(&total);
    decoded[0] = result[3];
    decoded[1] = result[2];
    decoded[2] = result[1];
    decoded[3] = result[0];
    return decoded;
}

vector<char> a85decode(const vector<char> encoded)
{
    int i = 0;
    vector<char> decoded;
    auto inserter = back_inserter<vector<char>>(decoded);
    while (i < encoded.size())
    {
        if (encoded[i] == 'z')
        {
            for (int j = 0; j < 4; j++)
                decoded.push_back((char)0);
            i++;
            continue;
        }
        if (i + 5 < encoded.size())
        {
            const char *group = decode_group(&encoded[i]);
            copy(group, group + 4, inserter);
        }
        else
        {
            char encoded_group[5];
            int left = encoded.size() - i;
            int padding = 5 - left;
            for (int j = 0; j < left; j++)
            {
                encoded_group[j] = encoded[i + j];
            }
            for (int j = left; j < 5; j++)
            {
                encoded_group[j] = 'u';
            }
            const char *decoded_group = decode_group(encoded_group);
            copy(decoded_group, decoded_group + 4 - padding, inserter);
        }
        i += 5;
    }
    return decoded;
}

int popcount(unsigned x)
{
    int c = 0;
    for (; x != 0; x &= x - 1)
        c++;
    return c;
}

int main()
{
    auto encoded = read_file("payload_layer2.txt");
    vector<char> cleaned;
    copy(encoded.begin() + 2, encoded.end() - 2, back_inserter<vector<char>>(cleaned));
    auto decoded = a85decode(cleaned);
    vector<char> popped;
    for (auto c : decoded)
    {
        if (popcount(c) % 2 == 0)
        {
            popped.push_back(c);
        }
    }
}