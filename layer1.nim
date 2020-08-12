import strutils
import bitops
import sequtils

proc asci85decode(b: seq[char]): string = 
    for i in 0..(len(b) div 5) - 1:
        echo b[5 * i..5 * (i+1)]
    return ""

let f = open("payload_layer1.txt")
let content = replace(f.readAll, "\n", "")
var s = ""
discard asci85decode(toSeq(content.items)[2..^2])
for c in content:
    let m = bitxor(ord(c), 0b01010101)
    s.add(chr(m))

echo s