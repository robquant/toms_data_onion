import sys

def main(argv=None):
    if argv is None:
        argv = sys.argv[:]

    inp = open(argv[1]).read().replace('\n', '')
    # Strip of <~,~>
    inp = inp[2:-2]

    outf = open("layer1.txt", "w")
    for i in range(len(inp)//5):
        arr = inp[i * 5:(i+1)*5]
        total = 0
        m = 1
        for c in arr[::-1]:
            total += (ord(c) - 33) * m
            m *= 85
        s = chr(total & 255)
        total >>= 8
        s = chr(total & 255) + s
        total >>= 8
        s = chr(total & 255) + s
        total >>= 8
        s = chr(total & 255) + s
        outf.write(s)

if __name__ == "__main__":
    main()
