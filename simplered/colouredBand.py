# This requires Python 3.x

import socket
import time
import math

kNumStrips = 8
kBaseIP = 177
kDestIPs = ["192.168.1." + str(x) for x in range(kBaseIP, kBaseIP + kNumStrips)]
kPort = 6000
kLedsPerStrip = 157
kBytesPerLed = 3
kBytesPerStrip = kLedsPerStrip * kBytesPerLed
kNumStripsPerPacket = 16
kNumStripsPerSystem = 128
kHeaderSize = 4 + 4
kBufSize = kBytesPerStrip * kNumStripsPerPacket + kHeaderSize
kBlueOffset = 0
kGreenOffset = 1
kRedOffset = 2

defaultMsg = bytearray(bufSize)
seq = 0
# The band is the colored band that shoots down the tunnel
bandWidth = ledsPerStrip // 5 
start = time.time()
maxBrightness = 0x20 # Out of 0xFF. These LEDs are bright; don't need max

while True:
  # increase sequence, insert into message
  msg = defaultmsg[:]
  seq += 1
  if seq > 0xffffffff:
    seq = 1
  msg[7] = seq & 0xFF
  msg[6] = (seq & 0xFF00) >> 8
  msg[5] = (seq & 0xFF0000) >> 16
  msg[4] = (seq & 0xFF000000) >> 24

  rate = 350
  now = time.time()
  for i in range(kHeaderSize, kBufSize, kBytesPerLed):
    num = (rate * now + i - kHeaderSize) // bytesPerLed
    denom = kLedsPerStrip
    if num % denom < width:
      msg[i + kBlueOffset] = abs(int((math.sin(now)+1 / 2 * maxBrightness))
      msg[i + kGreenOffset] = abs(int((math.sin(now * 1.1 + 1)+1) / 2 * maxBrightness))
      msg[i + kRedOffset] = abs(int((math.sin(now * 1.2 + 2)+1) / 2 * maxBrightness))

  for ip in destIPs:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.sendto(msg, (ip, port))

  time.sleep(0.03333333333) # 1/30


