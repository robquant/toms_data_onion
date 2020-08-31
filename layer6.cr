
def a85decode(encoded : String) : Array(UInt8)
    result = [] of UInt8
    total : UInt32 = 0
    count = 0
    raw = uninitialized UInt8[4]
    padded = encoded.bytes
    padded << 'u'.ord.to_u8 << 'u'.ord.to_u8 << 'u'.ord.to_u8 << 'u'.ord.to_u8
    padded.each do |c|
        if c == 'z'.ord
            result << 0 << 0 << 0 << 0
            next
        end
        total = total * 85 + (c - 33)
        count += 1
        if count == 5
            IO::ByteFormat::BigEndian.encode(total, raw.to_slice)
            count = 0
            total = 0
            result.concat(raw)
        end
    end
    if count < 4
        result = result[0..-(4 - count)]
    end
    return result
end

class Program
    def new()
    end
end

encoded = File.read_lines("payload_layer6.txt").join("")[2...-2]
decoded = a85decode(encoded)