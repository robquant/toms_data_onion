import strutils
import bitops

proc ascii85decode(b: string): string =
    var res: string = ""
    var padded: string = b & "uuuu"
    var count: int = 0
    var total: uint32 = 0
    for c in padded.items:
        if c == 'z':
            res.add("\0\0\0\0")
            continue
        total = 85 * total + (uint32(ord(c) - 33))
        count += 1
        if count == 5:
            res.add(char((total shr 24) and 255))
            res.add(char((total shr 16) and 255))
            res.add(char((total shr 8) and 255))
            res.add(char((total) and 255))
            total = 0
            count = 0
    if count < 4:
        res = res[0..^(5-count)]
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
