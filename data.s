.intel_syntax noprefix
.globl sockaddr_in
.globl http_request
.globl http_response
.globl path_file
.globl flag

.section .data
sockaddr_in:
    .word 2
    .word 0x901F      # port 8080 en little-endian = 0x1F90 -> .word 0x901F
    .long 0
    .quad 0

http_response: .ascii "HTTP/1.0 200 OK\r\n\r\n"

.section .bss
http_request: .skip 4096
path_file:    .skip 256
flag:         .skip 256
