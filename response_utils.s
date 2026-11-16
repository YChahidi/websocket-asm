.intel_syntax noprefix
.globl send_http_header
.globl send_http_data

.extern http_response

.section .text

# rdi = client_fd
send_http_header:
    lea rsi, [rip + http_response]
    mov rdx, 19
    mov rax, 1          # sys_write
    syscall
    ret

# rdi = client_fd
# rsi = buffer
# rdx = size
send_http_data:
    mov rax, 1          # sys_write
    syscall
    ret
