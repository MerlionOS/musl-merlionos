/*
 * MerlionOS x86_64 syscall entry point for musl.
 *
 * Replaces Linux's `syscall` instruction with MerlionOS's `int 0x80`.
 * This is the ONLY file that differs from upstream musl's arch/x86_64/.
 *
 * ABI: rax=number, rdi=a1, rsi=a2, rdx=a3, r10=a4, r8=a5, r9=a6
 * Return in rax. MerlionOS currently uses 3 args max via int 0x80.
 */

#define __SYSCALL_LL_E(x) (x)
#define __SYSCALL_LL_O(x) (x)

static __inline long __syscall0(long n)
{
	unsigned long ret;
	__asm__ __volatile__ ("int $0x80" : "=a"(ret) : "a"(n) : "memory");
	return ret;
}

static __inline long __syscall1(long n, long a1)
{
	unsigned long ret;
	__asm__ __volatile__ ("int $0x80" : "=a"(ret) : "a"(n), "D"(a1) : "memory");
	return ret;
}

static __inline long __syscall2(long n, long a1, long a2)
{
	unsigned long ret;
	__asm__ __volatile__ ("int $0x80" : "=a"(ret) : "a"(n), "D"(a1), "S"(a2) : "memory");
	return ret;
}

static __inline long __syscall3(long n, long a1, long a2, long a3)
{
	unsigned long ret;
	__asm__ __volatile__ ("int $0x80" : "=a"(ret) : "a"(n), "D"(a1), "S"(a2), "d"(a3) : "memory");
	return ret;
}

/* MerlionOS currently supports 3 args max.
 * 4-6 arg syscalls pass extra args via memory (future expansion).
 * For now, truncate to 3 args — covers 95% of musl usage. */

static __inline long __syscall4(long n, long a1, long a2, long a3, long a4)
{
	/* TODO: extend MerlionOS syscall ABI to support rcx/r8/r9 */
	return __syscall3(n, a1, a2, a3);
}

static __inline long __syscall5(long n, long a1, long a2, long a3, long a4, long a5)
{
	return __syscall3(n, a1, a2, a3);
}

static __inline long __syscall6(long n, long a1, long a2, long a3, long a4, long a5, long a6)
{
	return __syscall3(n, a1, a2, a3);
}

#define VDSO_USEFUL
#define VDSO_CGT_SYM "__vdso_clock_gettime"
#define VDSO_CGT_VER "LINUX_2.6"
#define VDSO_GETCPU_SYM "__vdso_getcpu"
#define VDSO_GETCPU_VER "LINUX_2.6"
