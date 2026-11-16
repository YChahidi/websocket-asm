.intel_syntax noprefix
.globl is_websocket_handshake
.globl handle_websocket_handshake

.extern http_request

.section .data
handshake_response: 
    .ascii "HTTP/1.1 101 Switching Protocols\r\n"
    .ascii "Upgrade: websocket\r\n"
    .ascii "Connection: Upgrade\r\n"
    .ascii "Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r\n"
    .ascii "\r\n"
handshake_response_end:

.section .text

# Check if request is WebSocket handshake
# rdi = http_request buffer
is_websocket_handshake:
    push r12
    mov r12, rdi  # Save buffer pointer
    
    # Simple detection: look for "Upgrade: websocket" string
    mov rdi, r12
    mov rcx, 1000  # Search first 1000 bytes
    
search_loop:
    # Check for "Upgrade: websocket" (case sensitive)
    cmp byte ptr [rdi], 'U'
    jne next_byte
    cmp byte ptr [rdi + 1], 'p'
    jne next_byte
    cmp byte ptr [rdi + 2], 'g'
    jne next_byte
    cmp byte ptr [rdi + 3], 'r'
    jne next_byte
    cmp byte ptr [rdi + 4], 'a'
    jne next_byte
    cmp byte ptr [rdi + 5], 'd'
    jne next_byte
    cmp byte ptr [rdi + 6], 'e'
    jne next_byte
    cmp byte ptr [rdi + 7], ':'
    jne next_byte
    cmp byte ptr [rdi + 8], ' '
    jne next_byte
    cmp byte ptr [rdi + 9], 'w'
    jne next_byte
    cmp byte ptr [rdi + 10], 'e'
    jne next_byte
    cmp byte ptr [rdi + 11], 'b'
    jne next_byte
    cmp byte ptr [rdi + 12], 's'
    jne next_byte
    cmp byte ptr [rdi + 13], 'o'
    jne next_byte
    cmp byte ptr [rdi + 14], 'c'
    jne next_byte
    cmp byte ptr [rdi + 15], 'k'
    jne next_byte
    cmp byte ptr [rdi + 16], 'e'
    jne next_byte
    cmp byte ptr [rdi + 17], 't'
    jne next_byte
    
    # Found "Upgrade: websocket"
    mov rax, 1
    jmp detection_done

next_byte:
    inc rdi
    dec rcx
    jnz search_loop
    
    # Not found
    mov rax, 0

detection_done:
    pop r12
    ret

# Handle WebSocket handshake
handle_websocket_handshake:
    push r12
    mov r12, rdi  # Save client socket
    
    # Send handshake response
    mov rdi, r12
    lea rsi, [handshake_response]
    mov rdx, handshake_response_end - handshake_response
    mov rax, 1
    syscall
    
    pop r12
    ret
