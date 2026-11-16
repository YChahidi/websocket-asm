.intel_syntax noprefix
.globl init_socket
.globl accept_loop

.extern handle_client
.extern sockaddr_in

.section .data
debug_init_start: .asciz "DEBUG: init_socket started\n"
debug_socket_created: .asciz "DEBUG: Socket created\n"
debug_bind_success: .asciz "DEBUG: Bind successful\n"
debug_listen_success: .asciz "DEBUG: Listen successful\n"
debug_accept_waiting: .asciz "DEBUG: Waiting for connections...\n"
debug_connection_accepted: .asciz "DEBUG: Connection accepted\n"
debug_forking: .asciz "DEBUG: Forking process\n"
debug_child_process: .asciz "DEBUG: Child process started\n"
debug_parent_process: .asciz "DEBUG: Parent process continuing\n"

.section .text

init_socket:
    # DEBUG: init started
    mov rdi, 2
    lea rsi, [rip + debug_init_start]
    mov rdx, 25
    mov rax, 1
    syscall

    # socket(AF_INET, SOCK_STREAM, 0)
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    mov rax, 41
    syscall
    mov r8, rax

    # DEBUG: socket created
    mov rdi, 2
    lea rsi, [rip + debug_socket_created]
    mov rdx, 22
    mov rax, 1
    syscall

    # bind(r8, &sockaddr_in, 16)
    mov rdi, r8
    lea rsi, [rip + sockaddr_in]
    mov rdx, 16
    mov rax, 49
    syscall

    # DEBUG: bind success
    mov rdi, 2
    lea rsi, [rip + debug_bind_success]
    mov rdx, 23
    mov rax, 1
    syscall

    # listen(r8, 0)
    mov rdi, r8
    mov rsi, 0
    mov rax, 50
    syscall

    # DEBUG: listen success
    mov rdi, 2
    lea rsi, [rip + debug_listen_success]
    mov rdx, 24
    mov rax, 1
    syscall

    ret

accept_loop:
    # DEBUG: waiting for connections
    mov rdi, 2
    lea rsi, [rip + debug_accept_waiting]
    mov rdx, 33
    mov rax, 1
    syscall

accept_loop_start:
    # accept(r8, NULL, NULL)
    mov rdi, r8
    mov rsi, 0
    mov rdx, 0
    mov rax, 43
    syscall
    mov r9, rax

    # DEBUG: connection accepted
    push r9
    mov rdi, 2
    lea rsi, [rip + debug_connection_accepted]
    mov rdx, 25
    mov rax, 1
    syscall
    pop r9

    # fork()
    mov rax, 57
    syscall

    # DEBUG: forking
    push rax
    mov rdi, 2
    lea rsi, [rip + debug_forking]
    mov rdx, 18
    mov rax, 1
    syscall
    pop rax

    cmp rax, 0
    je child_process

    # DEBUG: parent process
    mov rdi, 2
    lea rsi, [rip + debug_parent_process]
    mov rdx, 29
    mov rax, 1
    syscall

    # Parent: close client fd and continue
    mov rdi, r9
    mov rax, 3
    syscall
    jmp accept_loop_start

child_process:
    # DEBUG: child process
    mov rdi, 2
    lea rsi, [rip + debug_child_process]
    mov rdx, 26
    mov rax, 1
    syscall

    # Child: close listening socket
    mov rdi, r8
    mov rax, 3
    syscall

    # Handle the client
    call handle_client

    # Exit child process
    mov rdi, 0
    mov rax, 60
    syscall
