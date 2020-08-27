function decode_group(group)
    decoded = {}
    total = 0
    for i=1,5 do
        total = total * 85 + (string.byte(group[i]) - 33)
    end
    decoded[1] = (total >> 24) & 255
    decoded[2] = (total >> 16) & 255
    decoded[3] = (total >> 8) & 255
    decoded[4] = (total >> 0) & 255
    return decoded
end

function split(str)
    local result = {}
    for i = 1,#str do
        result[#result+1] = str:sub(i,i)
    end
    return result
end

function a85decode(s)
    local result = {}
    local i = 1
    while i <= #s do
        if s[i] == "z" then
            for j=1,4 do
                result[#result+1] = 0
            end
        i = i + 1
        goto continue
        end
        if i + 5 <= #s then
            local sub = s:sub(i, i + 4)
            local decoded = decode_group(split(sub))
            for j = 1,#decoded do
                result[#result+1] = decoded[j]
            end
        else
            local sub = s:sub(i,#s)
            local group = split(sub)
            local pad_length = 5 - #group
            for j = 1,pad_length do
                group[#group+1] = "u"
            end
            local decoded = decode_group(group)
            for j = 1, 4 - pad_length do
                result[#result + 1]= decoded[j]
            end
        end
        i = i + 5
        ::continue::
    end
    return result
end



io.input("payload_layer3.txt")
t = io.read("*all")
t = string.gsub(t, "\n", "")
t = t:sub(3,#t-3)
decoded = a85decode(t)

-- We know the start of the plain text which allows us to recover the beginning of the key
known_start = "==[ Layer 4/6: "
key_start = {}
for i = 1,#known_start do
    key_start[#key_start + 1] = decoded[i] ~ string.byte(known_start:sub(i,i))
end

-- Somewhere in the plaintext we have a long sequence of "=". Xor the cipher text with a plaintext
-- of all "=" and look for the known beginning of the key. The next 32 bytes are the full key
single = {}
for i=1,#decoded do
    single[#single + 1] = decoded[i] ~ string.byte("=")
end
-- for i=1,#single do
--     if single[i] == key_start[1] and single[i+1] == key_start[2] and single[i+2] == key_start[3] then
--         print(i, single[i], single[i+1])
--     end
-- end
key = {}
for i=0,31 do
    key[#key+1] = single[3489 + i]
end
print(#key)

-- Decode
for i=0,#decoded-1 do
    io.write(string.char(decoded[i + 1] ~ key[i%32 + 1]))
end