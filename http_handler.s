.intel_syntax noprefix
.globl handle_client

.extern http_request
.extern http_response
.extern path_file
.extern flag

.extern open_file
.extern read_file
.extern write_file
.extern close_file
.extern send_http_header
.extern send_http_data
.extern is_websocket_handshake
.extern handle_websocket_handshake
.extern read_websocket_frame
.extern send_websocket_frame

.section .data
debug_handle_called: .asciz "DEBUG: handle_client CALLED\n"
debug_request_received: .asciz "DEBUG: Received request\n"
debug_bytes_read: .asciz "DEBUG: Bytes read: "
debug_websocket_detected: .asciz "DEBUG: WebSocket detected!\n"
debug_not_websocket: .asciz "DEBUG: Not WebSocket - normal HTTP\n"
debug_handshake_sent: .asciz "DEBUG: Handshake sent\n"
debug_echo_started: .asciz "DEBUG: WebSocket echo started\n"
debug_frame_received: .asciz "DEBUG: Frame received\n"
debug_echo_sent: .asciz "DEBUG: Echo sent\n"
debug_websocket_done: .asciz "DEBUG: WebSocket done\n"
debug_normal_http: .asciz "DEBUG: Normal HTTP\n"
debug_get_request: .asciz "DEBUG: GET request\n"
debug_post_request: .asciz "DEBUG: POST request\n"
debug_file_opened: .asciz "DEBUG: File opened\n"
debug_file_written: .asciz "DEBUG: File written\n"
debug_file_read: .asciz "DEBUG: File read\n"
debug_end_handle: .asciz "DEBUG: End handle\n"
debug_request_content: .asciz "DEBUG: Request content:\n"
debug_separator: .asciz "------------------------\n"
newline: .asciz "\n"
space: .asciz " "

.section .bss
.lcomm debug_number_buffer, 32

.section .text

# Print number in RAX (to stderr)
print_number:
    push r12
    push r13
    push r14
    
    mov r12, rax
    lea r13, [debug_number_buffer + 31]
    mov byte ptr [r13], 0
    
    mov r14, 10
    
print_loop:
    dec r13
    xor rdx, rdx
    mov rax, r12
    div r14
    add dl, '0'
    mov byte ptr [r13], dl
    mov r12, rax
    test rax, rax
    jnz print_loop
    
    mov rdi, 2
    mov rsi, r13
    lea rdx, [debug_number_buffer + 32]
    sub rdx, rsi
    mov rax, 1
    syscall
    
    pop r14
    pop r13
    pop r12
    ret

handle_client:
    # DEBUG: Handle client called (to stderr)
    mov rdi, 2
    lea rsi, [debug_handle_called]
    mov rdx, 26
    mov rax, 1
    syscall

    # Lire la requête HTTP
    mov rdi, r9
    lea rsi, [http_request]
    mov rdx, 4096
    mov rax, 0
    syscall
    mov r14, rax

    # DEBUG: Request received (to stderr)
    mov rdi, 2
    lea rsi, [debug_request_received]
    mov rdx, 22
    mov rax, 1
    syscall

    # DEBUG: Bytes read (to stderr)
    mov rdi, 2
    lea rsi, [debug_bytes_read]
    mov rdx, 17
    mov rax, 1
    syscall
    
    push r14
    call print_number
    mov rdi, 2
    lea rsi, [newline]
    mov rdx, 1
    mov rax, 1
    syscall
    pop r14

    # DEBUG: Print the actual request content
    mov rdi, 2
    lea rsi, [debug_request_content]
    mov rdx, 22
    mov rax, 1
    syscall
    
    mov rdi, 2
    lea rsi, [http_request]
    mov rdx, r14  # Print exactly what we received
    mov rax, 1
    syscall
    
    mov rdi, 2
    lea rsi, [debug_separator]
    mov rdx, 24
    mov rax, 1
    syscall

    # ========== PROTOCOL DETECTION ==========
    # Check if this is a WebSocket handshake
    lea rdi, [http_request]
    call is_websocket_handshake
    test rax, rax
    jnz websocket_detected
    
    # If not WebSocket, handle as normal HTTP
    mov rdi, 2
    lea rsi, [debug_not_websocket]
    mov rdx, 32
    mov rax, 1
    syscall
    jmp normal_http_request

websocket_detected:
    # Clear the flag buffer before WebSocket communication
    lea rdi, [flag]
    mov rcx, 256
    xor al, al
    rep stosb

    # DEBUG: WebSocket detected (to stderr)
    mov rdi, 2
    lea rsi, [debug_websocket_detected]
    mov rdx, 25
    mov rax, 1
    syscall
    
    # Handle WebSocket handshake (to client socket)
    mov rdi, r9
    call handle_websocket_handshake
    
    # DEBUG: Handshake sent (to stderr)
    mov rdi, 2
    lea rsi, [debug_handshake_sent]
    mov rdx, 21
    mov rax, 1
    syscall
    
    # DEBUG: Echo started (to stderr)
    mov rdi, 2
    lea rsi, [debug_echo_started]
    mov rdx, 28
    mov rax, 1
    syscall
    
    # WebSocket echo loop
websocket_loop:
    # Read WebSocket frame (from client socket)
    mov rdi, r9
    call read_websocket_frame
    test rax, rax
    jz websocket_done
    
    # DEBUG: Frame received (to stderr)
    mov rdi, 2
    lea rsi, [debug_frame_received]
    mov rdx, 20
    mov rax, 1
    syscall
    
    # Save payload length (rax contains length)
    push rax
    
    # DEBUG: Print actual payload for verification
    mov rdi, 2
    lea rsi, [flag]
    mov rdx, rax      # FIXED: Use rax directly, don't pop/push
    mov rax, 1
    syscall
    
    mov rdi, 2
    lea rsi, [newline]
    mov rdx, 1
    mov rax, 1
    syscall
    
    # Send WebSocket frame back (to client socket)
    mov rdi, r9
    lea rsi, [flag]  # Use the flag buffer where payload is stored
    pop rdx          # FIXED: Only one pop - restore length
    call send_websocket_frame
    
    # DEBUG: Echo sent (to stderr)
    mov rdi, 2
    lea rsi, [debug_echo_sent]
    mov rdx, 14
    mov rax, 1
    syscall
    
    jmp websocket_loop

websocket_done:
    # DEBUG: WebSocket done (to stderr)
    mov rdi, 2
    lea rsi, [debug_websocket_done]
    mov rdx, 20
    mov rax, 1
    syscall
    
    # Close socket and exit
    mov rdi, r9
    mov rax, 3
    syscall
    mov rdi, 0
    mov rax, 60
    syscall

normal_http_request:
    # DEBUG: Normal HTTP (to stderr)
    mov rdi, 2
    lea rsi, [debug_normal_http]
    mov rdx, 17
    mov rax, 1
    syscall

    # Extraire le nom du fichier
    lea rbx, [http_request]  # Load base address once
    xor rcx, rcx
find_space_loop:
    cmp byte ptr [rbx + rcx], ' '
    je start_copy
    inc rcx
    jmp find_space_loop

start_copy:
    inc rcx
    inc rcx
    xor r10, r10
    lea r11, [path_file]
copy_loop:
    mov al, byte ptr [rbx + rcx]
    cmp al, ' '
    je finish_copy
    mov byte ptr [r11 + r10], al
    inc r10
    inc rcx
    jmp copy_loop

finish_copy:
    mov byte ptr [r11 + r10], 0

    # Vérifier si requête = GET ou POST
    mov al, 'G'
    cmp byte ptr [rbx], al
    je GET_request

    # DEBUG: POST request (to stderr)
    mov rdi, 2
    lea rsi, [debug_post_request]
    mov rdx, 19
    mov rax, 1
    syscall

    # POST: trouver body
    xor rcx, rcx
find_headers_end:
    cmp dword ptr [rbx + rcx], 0x0A0D0A0D
    je found_headers_end
    inc rcx
    jmp find_headers_end

found_headers_end:
    add rcx, 4
    mov r13, r14
    sub r13, rcx
    mov r15, r13  # Save body size

    xor r10, r10
    lea r11, [flag]
copy_body:
    mov al, byte ptr [rbx + rcx]
    mov byte ptr [r11 + r10], al
    inc r10
    dec r13
    inc rcx
    cmp r13, 0
    jne copy_body

    # open_file(path_file, O_WRONLY|O_CREAT, 0777)
    lea rdi, [path_file]
    mov rsi, 65
    mov rdx, 0777
    call open_file
    mov r8, rax

    # DEBUG: File opened (to stderr)
    mov rdi, 2
    lea rsi, [debug_file_opened]
    mov rdx, 17
    mov rax, 1
    syscall

    # write_file(fd, flag, body_size)
    mov rdi, r8
    lea rsi, [flag]
    mov rdx, r15  # Use saved body size
    call write_file

    # DEBUG: File written (to stderr)
    mov rdi, 2
    lea rsi, [debug_file_written]
    mov rdx, 18
    mov rax, 1
    syscall

    # close_file(fd)
    mov rdi, r8
    call close_file

    # send_http_header(client) - to client socket
    mov rdi, r9
    call send_http_header
    jmp end_handle


GET_request:
    # DEBUG: GET request (to stderr)
    mov rdi, 2
    lea rsi, [debug_get_request]
    mov rdx, 17
    mov rax, 1
    syscall

    # open_file(path_file, O_RDONLY, 0)
    lea rdi, [path_file]
    mov rsi, 0
    mov rdx, 0
    call open_file
    mov r10, rax

    # DEBUG: File opened (to stderr)
    mov rdi, 2
    lea rsi, [debug_file_opened]
    mov rdx, 17
    mov rax, 1
    syscall

    # read_file(fd, flag, 256)
    mov rdi, r10
    lea rsi, [flag]
    mov rdx, 256
    call read_file
    mov r12, rax

    # DEBUG: File read (to stderr)
    mov rdi, 2
    lea rsi, [debug_file_read]
    mov rdx, 15
    mov rax, 1
    syscall

    # close_file(fd)
    mov rdi, r10
    call close_file

    # send_http_header(client) - to client socket
    mov rdi, r9
    call send_http_header

    # send_http_data(client, flag, size) - to client socket
    mov rdi, r9
    lea rsi, [flag]
    mov rdx, r12
    call send_http_data

end_handle:
    # DEBUG: End handle (to stderr)
    mov rdi, 2
    lea rsi, [debug_end_handle]
    mov rdx, 17
    mov rax, 1
    syscall

    # Fermer socket client
    mov rdi, r9
    mov rax, 3
    syscall
    ret
