/*
 * MerlionOS x86_64 C runtime startup.
 * _start entry point — sets up stack and calls __libc_start_main.
 */

__asm__(
".text\n"
".global _start\n"
".type _start, @function\n"
"_start:\n"
"	xor %rbp, %rbp\n"       /* clear frame pointer */
"	mov %rsp, %rdi\n"       /* pass stack pointer as arg1 */
"	andq $-16, %rsp\n"      /* align stack to 16 bytes */
"	call " START "\n"        /* call __libc_start_main */
"	mov $1, %rax\n"          /* SYS_EXIT */
"	xor %rdi, %rdi\n"
"	int $0x80\n"             /* exit(0) if main returns */
"	jmp .\n"                 /* safety halt */
);
