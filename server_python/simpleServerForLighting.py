import socket
import sys
import Image

# number of frames
numOfFrames = 6
startFrame = 0

# Create a TCP/IP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Bind the socket to the port
server_address = ('192.168.4.2', 10200)
print >>sys.stderr, 'starting up on %s port %s' % server_address
sock.bind(server_address)

# Listen for incoming connections
sock.listen(5)

while True:
    # Wait for a connection
    print >>sys.stderr, 'waiting for a connection'
    connection, client_address = sock.accept()
    try:
        print >>sys.stderr, 'connection from', client_address
        data = connection.recv(16)
        print >> sys.stderr, 'command is', data
        frameName = "start.png"
        if data == "getstart":
            pass
        if data == "getnext":
            frameName = str(startFrame % numOfFrames) + ".png"
            startFrame = startFrame + 1
            print (frameName)

        im = Image.open(frameName)
        im.thumbnail([8, 8], Image.ANTIALIAS)
        im = im.convert("RGB")
        imstring = im.tostring()

        strList = [imstring[i:i + 24] for i in range(0, len(imstring), 24)]
        reversedStringList = []

        for j, nextString in enumerate(strList):
            correctedPixelList = []
            pixelList = [nextString[i:i + 3] for i in range(0, len(nextString), 3)]
            for k, nextPixel in enumerate(pixelList):
                rPix = nextPixel[1]
                gPix = nextPixel[0]
                bPix = nextPixel[2]
                nextPixel = rPix + gPix + bPix
                correctedPixelList.append(nextPixel)
            if j % 2 == 0:
                correctedPixelList.reverse()
            reversedStringList.append("".join(correctedPixelList))

        reversedStringList.reverse()
        imstring = "".join(reversedStringList)

        connection.sendall(imstring)
        connection.close()

        # Receive the data in small chunks and retransmit it
        # while True:
        #    pass
            
    finally:
        # Clean up the connection
        connection.close()