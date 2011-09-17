#!/usr/bin/python
import socket
import array

kLedsPerStrip = 157;
kBytesPerLed = 3;
kBytesPerStrip = kLedsPerStrip * kBytesPerLed;
kNumStripsPerPacket = 16
kNumStripsPerSystem = 128;
# strip data (471 * 16) + 8 byte UDP header
kBufSize = kBytesPerStrip * kNumStripsPerPacket + 4 + 4

ip="192.168.1.177"
port=6000
message = "000050" * 157 * 16

sock = socket.socket(socket.AF_INET, #Internet
    socket.SOCK_DGRAM) #UDP
sock.sendto(message, (ip, port))
