#!/usr/bin/env python3
import socket
import time
import struct
import os

def test_websocket():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5.0)
    sock.connect(('localhost', 8080))
    
    # WebSocket handshake
    handshake = (
        "GET / HTTP/1.1\r\n"
        "Upgrade: websocket\r\n"
        "Connection: Upgrade\r\n"
        "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
        "Sec-WebSocket-Version: 13\r\n"
        "Host: localhost:8080\r\n"
        "\r\n"
    )
    
    print("Sending handshake...")
    sock.send(handshake.encode())
    
    # Read response
    response = sock.recv(4096)
    print("Server response:")
    print(response.decode())
    
    if b"101 Switching Protocols" in response:
        print("✓ WebSocket handshake successful!")
        
        # Wait a bit for server to be ready
        time.sleep(0.5)
        
        # Send PROPER MASKED WebSocket frame (RFC compliant)
        message = "test websocket"
        message_bytes = message.encode()
        length = len(message_bytes)
        
        # Build frame: FIN=1, Text=1, MASK=1, payload length
        frame = bytearray()
        frame.append(0x81)  # FIN=1, Text frame=1
        
        if length < 126:
            frame.append(0x80 | length)  # MASK=1, length
        else:
            frame.append(0x80 | 126)  # MASK=1, extended length
            frame.extend(struct.pack('>H', length))
        
        # Add mask key (4 random bytes)
        mask_key = os.urandom(4)
        frame.extend(mask_key)
        
        # Mask the payload
        masked_payload = bytearray()
        for i, byte in enumerate(message_bytes):
            masked_payload.append(byte ^ mask_key[i % 4])
        
        frame.extend(masked_payload)
        
        print(f"Sending masked message: '{message}'")
        print(f"Frame bytes: {frame.hex()}")
        sock.send(bytes(frame))
        
        # Try to receive echo
        try:
            echo = sock.recv(1024)
            print(f"Received raw echo ({len(echo)} bytes): {echo.hex()}")
            
            # Parse the echo frame (server sends unmasked)
            if len(echo) >= 2:
                opcode = echo[0]
                length_byte = echo[1]
                payload_length = length_byte & 0x7F
                
                if payload_length < 126:
                    payload_start = 2
                    expected_payload_length = payload_length
                else:
                    # Extended length
                    payload_start = 4
                    expected_payload_length = struct.unpack('>H', echo[2:4])[0]
                
                # Extract only the actual payload bytes (ignore any padding)
                actual_payload_length = min(expected_payload_length, len(echo) - payload_start)
                payload = echo[payload_start:payload_start + actual_payload_length]
                
                # Remove any null bytes from the end
                payload = payload.rstrip(b'\x00')
                
                print(f"Parsed echo - opcode: 0x{opcode:02x}, frame_length: {payload_length}, actual_payload: {len(payload)} bytes")
                print(f"Payload bytes: {payload.hex()}")
                print(f"Payload text: '{payload.decode()}'")
                
                if payload == message_bytes:
                    print("✓ Perfect echo!")
                else:
                    print(f"✗ Echo mismatch.")
                    print(f"Expected: '{message}' ({message_bytes.hex()})")
                    print(f"Got: '{payload.decode()}' ({payload.hex()})")
                    
            else:
                print("✗ Invalid echo frame")
                
        except Exception as e:
            print(f"✗ Error receiving: {e}")
            
    else:
        print("✗ WebSocket handshake failed")
        
    sock.close()

if __name__ == "__main__":
    test_websocket()
