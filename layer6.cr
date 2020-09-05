
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
        @reg8 = Array(UInt8).new(6, 0)
        @reg32 = Array(UInt32).new(4, 0)
        @ptr = 0
        @pc = 0
    end

    def run()
        while true
            val = @memory[@pc]
            case 
            when val == 0xC2
                @reg8[0] += @reg8[1]
            when val== 0xC3
                a : Int16 = @reg8[0].to_i16 - @reg8[1].to_i16
                if a < 0 
                    a *= 256
                end
                b : UInt8 = a.to_u8
            when val == 0xC4
                @reg8[0] = @reg8[0] ^ @reg8[1]
            when val == 0xE1
                @pc += 1
                @ptr += @memory[@pc]
            when val == 0xC1
                if @reg8[0] == @reg8[1]
                    @reg8[5] = 0
                else
                    @reg8[5] = 1
                end 
            when val == 0x01
                break
            when val == 0x02
                puts @reg8[0].chr
            when val == 0x21
                @pc += 1
                if @reg8[5] == 0
                    mem = Bytes.new(4)
                    mem[0] = @memory[@pc]
                    mem[1] = @memory[@pc + 1]
                    mem[2] = @memory[@pc + 2]
                    mem[3] = @memory[@pc + 3]
                    pc = IO::ByteFormat::LittleEndian.decode(UInt32, mem)
                else
                    @pc += 4
                end
            when val == 0x22
                @pc += 1
                if @reg8[5] != 0
                    mem = Bytes.new(4)
                    mem[0] = @memory[@pc]
                    mem[1] = @memory[@pc + 1]
                    mem[2] = @memory[@pc + 2]
                    mem[3] = @memory[@pc + 3]
                    pc = IO::ByteFormat::LittleEndian.decode(UInt32, mem)
                else
                    @pc += 4
                end
            when val & 0b01000000 == 0b01000000
                puts "MV"
            when val & 0b10000000 == 0b10000000
                puts "MV32"
            end
            @pc += 1
        end
    end
end

encoded = File.read_lines("payload_layer6.txt").join("")[2...-2]
decoded = a85decode(encoded)
tomtel69 = Tomtel69CPU.new decoded
tomtel69.run