
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

class Tomtel69CPU
    ptr : UInt32
    pc : UInt32
    def initialize(program : Array(UInt8))
        @memory = program
        @reg8 = {:a => 0, :b => 0, :c => 0, :d => 0, :e => 0, :f => 0} of Symbol => UInt8
        @reg32 = {:la => 0, :lb => 0, :lc => 0, :ld => 0} of Symbol => UInt32
        @ptr = 0
        @pc = 0
    end

    def run()
        while true
            case @memory[@pc]
            when 0xC2
                puts "ADD"
            when 0xE1
                puts "APTR"
                @pc += 1
            when 0x01
                break
            end
            @pc += 1
        end
    end
end

encoded = File.read_lines("payload_layer6.txt").join("")[2...-2]
decoded = a85decode(encoded)
tomtel69 = Tomtel69CPU.new decoded
tomtel69.run