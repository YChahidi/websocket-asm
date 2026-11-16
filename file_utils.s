.intel_syntax noprefix
.globl open_file
.globl read_file
.globl write_file
.globl close_file

.section .text

# rdi = path
# rsi = flags
# rdx = mode
# -> retour: rax = fd
open_file:
    mov rax, 2          # sys_open
    syscall
    ret

# rdi = fd
# rsi = buffer
# rdx = count
# -> retour: rax = nb_lu
read_file:
    mov rax, 0          # sys_read
    syscall
    ret

# rdi = fd
# rsi = buffer
# rdx = count
# -> retour: rax = nb_ecrit
write_file:
    mov rax, 1          # sys_write
    syscall
    ret

# rdi = fd
close_file:
    mov rax, 3          # sys_close
    syscall
    ret
