import socket
import threading
import time

class InteractiveWebSocketClient:
    def __init__(self):
        self.sock = None
        self.connected = False
        
    def connect(self, host='localhost', port=8080):
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.connect((host, port))
            
            # Send handshake
            handshake = (
                "GET / HTTP/1.1\r\n"
                "Host: localhost:8080\r\n"
                "Upgrade: websocket\r\n"
                "Connection: Upgrade\r\n"
                "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
                "Sec-WebSocket-Version: 13\r\n"
                "\r\n"
            )
            self.sock.send(handshake.encode())
            
            # Read and ignore server response
            response = self.sock.recv(1024)
            self.connected = True
            print("✅ Connected to WebSocket server!")
            print("Type your messages and press Enter. Type 'quit' to exit.\n")
            return True
            
        except Exception as e:
            print(f"❌ Connection failed: {e}")
            return False
    
    def send_message(self, message):
        if not self.connected:
            print("Not connected!")
            return
            
        # Send WebSocket frame (unmasked)
        frame = b'\x81' + bytes([len(message)]) + message.encode('utf-8')
        self.sock.send(frame)
        print(f"You: {message}")
    
    def receive_messages(self):
        while self.connected:
            try:
                # Read frame header
                header = self.sock.recv(2)
                if len(header) < 2:
                    break
                    
                payload_len = header[1] & 0x7F
                if payload_len > 0:
                    payload = self.sock.recv(payload_len)
                    print(f"Server: {payload.decode('utf-8')}")
            except:
                break
    
    def start_interactive(self):
        if not self.connect():
            return
            
        # Start receiver thread
        receiver = threading.Thread(target=self.receive_messages, daemon=True)
        receiver.start()
        
        # Main input loop
        try:
            while self.connected:
                message = input("> ").strip()
                if message.lower() == 'quit':
                    break
                if message:
                    self.send_message(message)
        except KeyboardInterrupt:
            print("\nDisconnecting...")
        finally:
            self.connected = False
            if self.sock:
                self.sock.close()
            print("Disconnected.")

# Run the interactive client
if __name__ == "__main__":
    client = InteractiveWebSocketClient()
    client.start_interactive()
