import strutils
import bitops
import unicode

proc toString(str: seq[byte]): string =
  result = newStringOfCap(len(str))
  for ch in str:
    add(result, chr(ch))

proc ascii85decode(b: string): seq[byte] = 
    var i: int = 0
    result = newSeq[byte]()
    while i < b.len:
        while b[i] == ' '  or b[i] == '\n' or b[i] == '\t':
            i += 1
        if b[i] == 'z':
            result.add(@[0'u8,0'u8,0'u8,0'u8])
            i += 1
            continue
        var total: uint32 = 0
        var m: uint32 = 1
        let leftover = b.len - i
        var padding: int = 0
        if leftover < 5:
            padding = 5 - leftover
            for j in 1..padding:
                total += uint32(ord('u') - 33) * m
                m *= 85 
        for j in countdown(min(5, leftover) - 1, 0):
            while b[i+j] == ' '  or b[i+j] == '\n' or b[i+j] == '\t':
                i+=1
            total += (uint32(ord(b[i + j])) - 33) * m
            m *= 85
        result.add(uint8(total shr 24))    
        if leftover > 2:
            result.add(uint8(total shr 16))    
        if leftover > 3:
            result.add(uint8(total shr 8))    
        if leftover > 4:
            result.add(uint8(total))    
        i += 5

let f = open("payload_layer1.txt")
let content = replace(f.readAll, "\n", "")
let decoded = ascii85decode(content[2..^3])
var shifted = newSeqUninitialized[byte](decoded.len)
var leftover:byte = 0
for i in 0..decoded.len-1:
    let x = bitxor(decoded[i], 0b01010101)
    shifted[i] = (x shr 1) or (leftover shl 7) 
    leftover = x and 1'u8
echo toString(shifted)