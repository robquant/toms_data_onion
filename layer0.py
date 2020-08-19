import sys
import base64

def decode_group(group):
    total = 0
    m = 1
    res = []
    total += (ord(group[4]) - 33) * m
    m *= 85
    total += (ord(group[3]) - 33) * m
    m *= 85
    total += (ord(group[2]) - 33) * m
    m *= 85
    total += (ord(group[1]) - 33) * m
    m *= 85
    total += (ord(group[0]) - 33) * m
    res.append((total >> 24) & 255)    
    res.append((total >> 16) & 255)    
    res.append((total >> 8) & 255)    
    res.append(total & 255)    
    return res

def a85decode(encoded: str):
    res: bytes = []
    i = 0
    while i <= len(encoded):
        if encoded[i] == 'z':
            res += [0,0,0,0]
            i += 1
            continue
        if i + 5 < len(encoded):
            res += decode_group(encoded[i:i+5])
        else:
            padded = list(encoded[i:])
            pad_length = 5 - len(padded)
            padded += ["u"] * pad_length
            res += decode_group(padded)[:-pad_length]
        i += 5
    return bytes(res)


def main(argv=None):
    if argv is None:
        argv = sys.argv[:]

    inp = open(argv[1]).read().replace('\n', '')
    # Strip of <~,~>
    inp = inp[2:-2]

    with open("layer1.txt", "wb") as outf:
        outf.write(a85decode(inp))

if __name__ == "__main__":
    main()
