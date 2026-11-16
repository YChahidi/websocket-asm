.intel_syntax noprefix
.globl _start

.extern init_socket
.extern accept_loop

.section .text

_start:
    # Initialise socket, bind, listen
    call init_socket

    # Boucle d'accept/listen (bloquante)
    call accept_loop

    # Si on revient, exit
    mov rdi, 0
    mov rax, 60
    syscall
