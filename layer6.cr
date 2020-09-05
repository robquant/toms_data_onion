
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
    @ptr : UInt32
    @pc : UInt32
    def initialize(program : Array(UInt8))
        @memory = program
        @reg8 = Array(UInt8).new(6, 0)
        @reg32 = Array(UInt32).new(4, 0)
        @ptr = 0
        @pc = 0
    end

    def read_uint32(pc : UInt32) : UInt32
        mem = Bytes.new(4)
        mem[0] = @memory[pc]
        mem[1] = @memory[pc + 1]
        mem[2] = @memory[pc + 2]
        mem[3] = @memory[pc + 3]
        return IO::ByteFormat::LittleEndian.decode(UInt32, mem)
    end

    def run()
        while true
            ins = @memory[@pc]
            case 
            when ins == 0xC2 #ADD
                a = @reg8[0].to_i16 + @reg8[1].to_i16
                if a >= 256 
                    a -= 256
                end
                @reg8[0] = a.to_u8
            when ins == 0xC3 #SUB
                a = @reg8[0].to_i16 - @reg8[1].to_i16
                if a < 0 
                    a += 256
                end
                @reg8[0] = a.to_u8
            when ins == 0xC4 #XOR
                @reg8[0] ^= @reg8[1]
            when ins == 0xE1 #APTR
                @pc += 1
                @ptr += @memory[@pc]
            when ins == 0xC1 #CMP
                if @reg8[0] == @reg8[1]
                    @reg8[5] = 0
                else
                    @reg8[5] = 1
                end 
            when ins == 0x01
                break
            when ins == 0x02
                STDOUT.print(@reg8[0].chr)
            when ins == 0x21
                if @reg8[5] == 0
                    @pc = read_uint32(@pc + 1) - 1
                else
                    @pc += 4
                end
            when ins == 0x22
                if @reg8[5] != 0
                    @pc = read_uint32(@pc + 1) - 1
                else
                    @pc += 4
                end
            when ins & 0b01000000 == 0b01000000
                dst = (ins & (7 << 3)) >> 3
                if ins & 7 == 0
                    @pc += 1
                    src_data = @memory[@pc]
                else
                    src = ins & 7
                    if src < 7
                        src_data = @reg8[src - 1]
                    else
                        src_data = @memory[@ptr + @reg8[2]]
                    end
                end
                if dst < 7
                    @reg8[dst - 1] = src_data
                else
                    @memory[@ptr + @reg8[2]] = src_data
                end
            when ins & 0b10000000 == 0b10000000
                dst = (ins & (7 << 3)) >> 3
                if ins & 7 == 0
                    src_data = read_uint32(@pc + 1)
                    @pc += 4
                else
                    src = ins & 7
                    if src < 5
                        src_data = @reg32[src - 1]
                    elsif src == 5
                        src_data = @ptr
                    elsif src == 6
                        src_data = @pc + 1
                    else
                        puts "Unknown source"
                        exit
                    end
                end
                if dst < 5
                    @reg32[dst - 1] = src_data
                elsif dst == 5
                    @ptr = src_data
                elsif dst == 6
                    @pc = src_data - 1
                else
                    puts "Unknown destination"
                    exit
                end
            end
            @pc += 1
        end
        STDOUT.print('\n')
    end
end

encoded = File.read_lines("payload_layer6.txt").join("")[2...-2]
decoded = a85decode(encoded)

test=[0x50,0x48,0xC2,0x02,0xA8,0x4D,0x00,0x00,0x00,0x4F,0x02,0x50,0x09,0xC4,0x02,0x02,0xE1,0x01,0x4F,0x02,0xC1,
0x22,0x1D,0x00,0x00,0x00,0x48,0x30,0x02,0x58,0x03,0x4F,0x02,0xB0,0x29,0x00,0x00,0x00,0x48,0x31,0x02,0x50,0x0C,0xC3,
0x02,0xAA,0x57,0x48,0x02,0xC1,0x21,0x3A,0x00,0x00,0x00,0x48,0x32,0x02,0x48,0x77,0x02,0x48,0x6F,0x02,0x48,0x72,
0x02,0x48,0x6C,0x02,0x48, 0x64,0x02,0x48,0x21,0x02,0x01,0x65,0x6F,0x33,0x34,0x2C] of UInt8
tomtel69 = Tomtel69CPU.new decoded
tomtel69.run
