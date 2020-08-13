import strutils
import bitops

proc toString(str: seq[byte]): string =
  result = newStringOfCap(len(str))
  for ch in str:
    add(result, chr(ch))

proc ascii85decode(b: string): seq[byte] = 
    var i: int = 0
    result = newSeq[byte]()
    while i <= b.len - 5:
        if b[i] == 'z':
            result.add(@[0'u8,0'u8,0'u8,0'u8])
            i += 1
            continue
        var total: uint32 = 0
        var m: uint32 = 1
        for j in countdown(4, 0):
            total += (uint32(ord(b[i + j])) - 33) * m
            m *= 85
        result.add(uint8(total shr 24))    
        result.add(uint8(total shr 16))    
        result.add(uint8(total shr 8))    
        result.add(uint8(total))    
        i += 5

let f = open("payload_layer1.txt")
let content = replace(f.readAll, "\n", "")
let decoded = ascii85decode(content[2..^2])
var shifted = newSeqUninitialized[byte](decoded.len)
var leftover:byte = 0
for i in 0..decoded.len-1:
    let x = bitxor(decoded[i], 0b01010101)
    shifted[i] = (x shr 1) or (leftover shl 7) 
    leftover = x and 1'u8
echo toString(shifted)