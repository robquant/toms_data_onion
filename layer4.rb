require 'ipaddr'


def a85decode(data)
	count = 0
	total = 0
	result = Array.new
	data[2..-3].each_byte do |c|
		if c.chr == 'z' then
			result << 0
		else
			total = total * 85 + (c - 33)
			count += 1
			if count == 5 then
				result << total
				count = 0
				total = 0
			end
		end
	end

	return result.pack("N*")
end

data = File.open("payload_layer4.txt").read.rstrip.tr("\n","")
stream = a85decode(data)

offset = 0
required_src_ip = IPAddr.new "10.1.1.10"
required_dst_ip = IPAddr.new "10.1.1.200"
required_dst_port = 42069
ip_hdr_len = 20
udp_hdr_len = 8

while offset < stream.length
	ip_hdr_raw = stream[offset,ip_hdr_len]
	ip_hdr = ip_hdr_raw.unpack("CCnnnnnNN")
	checksum = ip_hdr_raw.unpack("n10").sum
	while checksum >> 16 != 0
		checksum = (checksum & 0xFFFF) + (checksum >> 16)
	end
	checksum = ~checksum & 0xFFFF
	packet_size = ip_hdr[2]
	udp_hdr_start = offset + ip_hdr_len
	data_length = packet_size - ip_hdr_len - udp_hdr_len
	data_start = offset + ip_hdr_len + udp_hdr_len
	offset += packet_size
	if checksum != 0
		next
	end 
	src_ip = IPAddr.new ip_hdr[7], Socket::AF_INET
	if src_ip != required_src_ip
		next
	end
	dst_ip = IPAddr.new ip_hdr[8], Socket::AF_INET
	if dst_ip != required_dst_ip
		next
	end
	udp_hdr_raw = stream[udp_hdr_start, udp_hdr_len]
	udp_hdr = udp_hdr_raw.unpack("nnnn")
	dst_port = udp_hdr[1]
	udp_len = udp_hdr[2]
	if dst_port != required_dst_port
		next
	end
	pseudo_hdr = [src_ip.to_i, dst_ip.to_i].pack("NN") + [0x11].pack("n") + [udp_len].pack("n")
	udp_packet = stream[udp_hdr_start, udp_len]
	if udp_len % 2 == 1
		udp_packet += "\x0"
	end
	checksum = pseudo_hdr.unpack("n6").sum + udp_packet.unpack("n*").sum
	while checksum >> 16 != 0
		checksum = (checksum & 0xFFFF) + (checksum >> 16)
	end
	checksum = ~checksum & 0xFFFF
	if checksum == 0
		print(stream[data_start, data_length])
	end
end