import sys
from array import array
import struct
import base64


def a85decode(encoded: str):
    res = array("I")
    pad_length = 0
    count = 0
    total = 0
    for c in encoded:
        if c == 'z':
            res.append(0)
        else:
            total = 85 * total + (ord(c) - 33)
            count += 1
            if count == 5:
                res.append(total)
                total, count = 0, 0
    if count > 0:
        pad_length = 5 - count
        while count < 5:
            count += 1
            total = 85 * total + (ord("u") - 33)
        res.append(total)
    if sys.byteorder == 'little':
        res.byteswap()
    return res.tobytes()[:-pad_length]


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
