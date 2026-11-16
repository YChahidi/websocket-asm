.intel_syntax noprefix
.globl read_websocket_frame
.globl send_websocket_frame

.extern flag

.section .data
debug_frame_start: .asciz "DEBUG: read_websocket_frame called\n"
debug_frame_success: .asciz "DEBUG: Frame read success\n"
debug_frame_error: .asciz "DEBUG: Frame read error\n"
debug_sending_frame: .asciz "DEBUG: Sending WebSocket frame\n"
debug_echo_sent: .asciz "DEBUG: Echo sent\n"
newline: .asciz "\n"

.section .bss
.lcomm frame_buffer, 1024
.lcomm mask_key, 4

.section .text

# Simple WebSocket frame reader
read_websocket_frame:
    push r12
    push r13
    push r14
    push r15
    
    mov r12, rdi
    
    # DEBUG: Starting
    mov rdi, 2
    lea rsi, [debug_frame_start]
    mov rdx, 33
    mov rax, 1
    syscall

    # Read first 2 bytes (header)
    mov rdi, r12
    lea rsi, [frame_buffer]
    mov rdx, 2
    mov rax, 0
    syscall
    
    # Check if we got 2 bytes
    cmp rax, 2
    jne read_frame_error
    
    # Parse frame header
    mov al, byte ptr [frame_buffer]    # First byte
    mov bl, byte ptr [frame_buffer + 1] # Second byte
    
    # Check opcode (text frame)
    mov cl, al
    and cl, 0x0F
    cmp cl, 0x01  # Text frame
    jne read_frame_error
    
    # Get payload length and check mask bit
    movzx r13, bl
    and r13, 0x7F  # Remove mask bit to get length
    mov r14b, bl    # Save original second byte
    and r14b, 0x80  # Check mask bit
    
    # If masked, we need to read 4 more bytes for mask key
    test r14b, r14b
    jz read_payload_unmasked
    
    # Read mask key (4 bytes)
    mov rdi, r12
    lea rsi, [mask_key]
    mov rdx, 4
    mov rax, 0
    syscall
    
    cmp rax, 4
    jne read_frame_error
    
read_payload_unmasked:
    # If no payload, return success
    test r13, r13
    je read_frame_success_empty
    
    # Read payload
    mov rdi, r12
    lea rsi, [flag]
    mov rdx, r13  # expected payload length
    mov rax, 0
    syscall
    
    # Use the expected payload length from frame header
    mov r15, r13
    
    # If masked, unmask the payload
    test r14b, r14b
    jz read_frame_success
    
    # Unmask the payload using the mask key
    mov rcx, 0  # counter
    lea rsi, [flag]
    lea r8, [mask_key]  # Load address of mask_key
unmask_loop:
    cmp rcx, r15
    jge read_frame_success
    mov al, byte ptr [rsi + rcx]      # Load payload byte
    mov dl, cl                        # Calculate mask index: rcx % 4
    and dl, 3                         # dl = counter % 4
    mov bl, byte ptr [r8 + rdx]       # Load correct mask byte
    xor al, bl                        # Unmask
    mov byte ptr [rsi + rcx], al      # Store back
    inc rcx
    jmp unmask_loop

read_frame_success_empty:
    mov r15, 0  # No payload
    lea rsi, [flag]
    jmp read_frame_success

read_frame_success:
    # DEBUG: Success
    mov rdi, 2
    lea rsi, [debug_frame_success]
    mov rdx, 23
    mov rax, 1
    syscall
    
    # Return the correct length
    mov rax, r15
    lea rsi, [flag]
    jmp read_frame_done

read_frame_error:
    # DEBUG: Error
    mov rdi, 2
    lea rsi, [debug_frame_error]
    mov rdx, 21
    mov rax, 1
    syscall
    
    xor rax, rax

read_frame_done:
    pop r15
    pop r14
    pop r13
    pop r12
    ret

# Send WebSocket frame
# rdi = client socket
# rsi = data buffer  
# rdx = payload length
send_websocket_frame:
    push r12
    push r13
    push r14
    
    mov r12, rdi  # socket
    mov r13, rsi  # data buffer
    mov r14, rdx  # payload length
    
    # DEBUG: Sending frame
    mov rdi, 2
    lea rsi, [debug_sending_frame]
    mov rdx, 28
    mov rax, 1
    syscall
    
    # Build frame header in stack
    sub rsp, 16
    mov byte ptr [rsp], 0x81          # FIN=1, Text frame
    
    # Set correct payload length
    cmp r14, 126
    jae send_frame_error_to_stack
    
    mov byte ptr [rsp + 1], r14b      # Use actual payload length
    
    # Send header (2 bytes)
    mov rdi, r12
    mov rsi, rsp
    mov rdx, 2
    mov rax, 1
    syscall
    
    # Send payload data
    test r14, r14
    jz send_done_to_stack
    
    mov rdi, r12
    mov rsi, r13      # data buffer
    mov rdx, r14      # actual payload length
    mov rax, 1
    syscall
    
    # DEBUG: Echo sent
    mov rdi, 2
    lea rsi, [debug_echo_sent]
    mov rdx, 14
    mov rax, 1
    syscall

send_frame_error_to_stack:
    # Error handling placeholder
    nop

send_done_to_stack:
    add rsp, 16
    pop r14
    pop r13
    pop r12
    ret
