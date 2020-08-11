import sys


def extract_payload(fname):
    payload_found = False
    with open("payload_" + fname, "w") as outf:
        for line in open(fname):
            if not payload_found:
                payload_found = line.startswith("==[ Payload ]")
                continue
            if len(line) <= 1:
                continue
            outf.write(line)


if __name__ == "__main__":
    extract_payload(sys.argv[1])
