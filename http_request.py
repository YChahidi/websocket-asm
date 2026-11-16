# test_http.py
import socket
import time

def test_http():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect(('localhost', 8080))
    
    # Send regular HTTP request (NOT WebSocket)
    http_request = (
        "GET /test.txt HTTP/1.1\r\n"
        "Host: localhost:8080\r\n"
        "User-Agent: test-client\r\n"
        "\r\n"
    )
    
    print("Sending HTTP request (not WebSocket)...")
    sock.send(http_request.encode())
    
    # Try to read response
    response = sock.recv(4096)
    print("Server response:")
    print(response.decode())
    
    sock.close()

if __name__ == "__main__":
    test_http()
