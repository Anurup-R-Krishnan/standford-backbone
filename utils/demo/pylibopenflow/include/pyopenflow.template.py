class ofsocket:
    """OpenFlow scoket"""

    def __init__(self, socket):
        """Initialize with socket"""
        ##Reference to socket
        self.socket = socket

    def send(self, msg):
        """Send message"""
        ofph = ofp_header()  # noqa: F821
        remaining = ofph.unpack(msg)
        if ofph.length != len(msg):
            ofph.length = len(msg)
            msg = ofph.pack() + remaining
        self.socket.send(msg)
