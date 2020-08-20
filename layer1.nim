import strutils
import bitops

proc decodeGroup(group: string): string =
    var res : string = ""
    var total: uint32 = 0
    for i in 0..4:
        total = 85 * total + (uint32(ord(group[i])) - 33)
    res.add(char((total shr 24) and 255))
    res.add(char((total shr 16) and 255))
    res.add(char((total shr 8) and 255))
    res.add(char((total) and 255))
    return res

proc ascii85decode(b: string): string =
    var i: int = 0
    var res: string = ""
    var decoded: string
    while i < len(b):
        if b[i] == 'z':
            result.add("\0\0\0\0")
            i += 1
            continue
        if i + 5 < len(b):
            decoded = decodeGroup(b[i..i+4])
        else:
            var padded: string = b[i..len(b)-1]
            var padding: int = 5 - len(padded)
            padded.add("u".repeat(padding))
            decoded = decodeGroup(padded)[0..3-padding]
        res.add(decoded)
        i += 5
    return res

proc main() =
    let f = open("payload_layer1.txt")
    let content = replace(f.readAll, "\n", "")
    let decoded = ascii85decode(content[2..^3])
    var shifted : string = ""
    var leftover:byte = 0
    for i in 0..decoded.len-1:
        let x = bitxor(uint8(decoded[i]), 0b01010101)
        shifted.add(char((x shr 1) or (leftover shl 7)))
        leftover = x and 1'u8
    echo shifted

main()