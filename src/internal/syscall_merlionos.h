/*
 * MerlionOS syscall mapping for musl libc.
 *
 * musl uses Linux syscall numbers internally (via __NR_* constants).
 * This header remaps them to MerlionOS syscall numbers.
 *
 * MerlionOS syscall ABI: int 0x80
 *   rax = syscall number
 *   rdi = arg1, rsi = arg2, rdx = arg3
 *   Return in rax (negative = error)
 */

#ifndef _SYSCALL_MERLIONOS_H
#define _SYSCALL_MERLIONOS_H

/*
 * Linux → MerlionOS syscall number mapping.
 *
 * Linux numbers are what musl uses internally (__NR_read, __NR_write, etc.)
 * We remap them to MerlionOS numbers here.
 */

/* ── Process (Linux 0-14 → MerlionOS 0-14) ─────────────────── */
#define __NR_read              101   /* MerlionOS SYS_READ */
#define __NR_write               0   /* MerlionOS SYS_WRITE */
#define __NR_open              100   /* MerlionOS SYS_OPEN */
#define __NR_close             102   /* MerlionOS SYS_CLOSE */
#define __NR_stat              103   /* MerlionOS SYS_STAT */
#define __NR_fstat             103   /* MerlionOS SYS_STAT (reuse) */
#define __NR_lstat             103   /* MerlionOS SYS_STAT (reuse) */
#define __NR_lseek             104   /* MerlionOS SYS_LSEEK */
#define __NR_mmap              120   /* MerlionOS SYS_MMAP */
#define __NR_mprotect          122   /* MerlionOS SYS_MPROTECT */
#define __NR_munmap            121   /* MerlionOS SYS_MUNMAP */
#define __NR_brk               113   /* MerlionOS SYS_BRK */
#define __NR_ioctl             150   /* MerlionOS SYS_IOCTL */

/* ── File operations ────────────────────────────────────────── */
#define __NR_pread64           101   /* reuse SYS_READ */
#define __NR_pwrite64          195   /* MerlionOS SYS_FWRITE */
#define __NR_readv             101   /* reuse SYS_READ */
#define __NR_writev            195   /* reuse SYS_FWRITE */
#define __NR_access             14   /* MerlionOS SYS_ACCESS */
#define __NR_pipe              151   /* MerlionOS SYS_PIPE */
#define __NR_dup2              152   /* MerlionOS SYS_DUP2 */
#define __NR_dup               152   /* reuse SYS_DUP2 */
#define __NR_mkdir             105   /* MerlionOS SYS_MKDIR */
#define __NR_rmdir             106   /* reuse SYS_UNLINK */
#define __NR_unlink            106   /* MerlionOS SYS_UNLINK */
#define __NR_rename            106   /* stub: reuse SYS_UNLINK */
#define __NR_getcwd            109   /* MerlionOS SYS_GETCWD */
#define __NR_chdir             108   /* MerlionOS SYS_CHDIR */
#define __NR_chmod              12   /* MerlionOS SYS_CHMOD */
#define __NR_chown              13   /* MerlionOS SYS_CHOWN */
#define __NR_getdents64        107   /* MerlionOS SYS_READDIR */
#define __NR_fcntl             243   /* MerlionOS SYS_FCNTL */

/* ── Process management ─────────────────────────────────────── */
#define __NR_exit                1   /* MerlionOS SYS_EXIT */
#define __NR_exit_group          1   /* reuse SYS_EXIT */
#define __NR_fork              110   /* MerlionOS SYS_FORK */
#define __NR_vfork             110   /* reuse SYS_FORK */
#define __NR_execve            111   /* MerlionOS SYS_EXEC */
#define __NR_wait4             112   /* MerlionOS SYS_WAITPID */
#define __NR_waitpid           112   /* MerlionOS SYS_WAITPID */
#define __NR_kill              115   /* MerlionOS SYS_KILL */
#define __NR_getpid              3   /* MerlionOS SYS_GETPID */
#define __NR_getppid           114   /* MerlionOS SYS_GETPPID */
#define __NR_getuid              7   /* MerlionOS SYS_GETUID */
#define __NR_setuid              8   /* MerlionOS SYS_SETUID */
#define __NR_getgid              9   /* MerlionOS SYS_GETGID */
#define __NR_setgid             10   /* MerlionOS SYS_SETGID */
#define __NR_geteuid             7   /* reuse SYS_GETUID */
#define __NR_getegid             9   /* reuse SYS_GETGID */
#define __NR_sched_yield         2   /* MerlionOS SYS_YIELD */

/* ── Signals ────────────────────────────────────────────────── */
#define __NR_rt_sigaction      180   /* MerlionOS SYS_SIGACTION */
#define __NR_rt_sigprocmask    180   /* reuse SYS_SIGACTION */
#define __NR_rt_sigreturn      181   /* MerlionOS SYS_SIGRETURN */
#define __NR_sigaltstack       180   /* reuse */

/* ── Networking ─────────────────────────────────────────────── */
#define __NR_socket            130   /* MerlionOS SYS_SOCKET */
#define __NR_connect           131   /* MerlionOS SYS_CONNECT */
#define __NR_accept            136   /* MerlionOS SYS_ACCEPT */
#define __NR_accept4           136   /* reuse SYS_ACCEPT */
#define __NR_sendto            132   /* MerlionOS SYS_SENDTO */
#define __NR_recvfrom          133   /* MerlionOS SYS_RECVFROM */
#define __NR_sendmsg           132   /* reuse SYS_SENDTO */
#define __NR_recvmsg           133   /* reuse SYS_RECVFROM */
#define __NR_shutdown          268   /* MerlionOS SYS_SHUTDOWN */
#define __NR_bind              134   /* MerlionOS SYS_BIND */
#define __NR_listen            135   /* MerlionOS SYS_LISTEN */
#define __NR_getsockname       134   /* reuse SYS_BIND */
#define __NR_getpeername       134   /* reuse */
#define __NR_setsockopt        244   /* MerlionOS SYS_SETSOCKOPT */
#define __NR_getsockopt        245   /* MerlionOS SYS_GETSOCKOPT */
#define __NR_socketpair        130   /* reuse SYS_SOCKET */

/* ── epoll ──────────────────────────────────────────────────── */
#define __NR_epoll_create      230   /* MerlionOS SYS_EPOLL_CREATE */
#define __NR_epoll_create1     230   /* reuse */
#define __NR_epoll_ctl         231   /* MerlionOS SYS_EPOLL_CTL */
#define __NR_epoll_wait        232   /* MerlionOS SYS_EPOLL_WAIT */
#define __NR_epoll_pwait       232   /* reuse */

/* ── Threads ────────────────────────────────────────────────── */
#define __NR_clone             190   /* MerlionOS SYS_CLONE */
#define __NR_futex             241   /* MerlionOS SYS_FUTEX_WAIT */
#define __NR_set_tid_address     3   /* reuse SYS_GETPID */
#define __NR_set_robust_list     2   /* stub: SYS_YIELD */
#define __NR_get_robust_list     2   /* stub: SYS_YIELD */

/* ── Time ───────────────────────────────────────────────────── */
#define __NR_nanosleep         141   /* MerlionOS SYS_NANOSLEEP */
#define __NR_clock_gettime     255   /* MerlionOS SYS_CLOCK_MONOTONIC */
#define __NR_clock_getres      255   /* reuse */
#define __NR_gettimeofday      254   /* MerlionOS SYS_GETTIMEOFDAY */
#define __NR_time              140   /* MerlionOS SYS_TIME */

/* ── Event fd / Timer fd ────────────────────────────────────── */
#define __NR_eventfd2          260   /* MerlionOS SYS_EVENTFD */
#define __NR_timerfd_create    263   /* MerlionOS SYS_TIMERFD_CREATE */
#define __NR_timerfd_settime   264   /* MerlionOS SYS_TIMERFD_SETTIME */
#define __NR_timerfd_gettime   265   /* MerlionOS SYS_TIMERFD_READ */

/* ── Memory ─────────────────────────────────────────────────── */
#define __NR_madvise           120   /* reuse SYS_MMAP (no-op) */
#define __NR_mremap            120   /* reuse SYS_MMAP */
#define __NR_msync             120   /* reuse SYS_MMAP (no-op) */

/* ── Random ─────────────────────────────────────────────────── */
#define __NR_getrandom         266   /* MerlionOS SYS_GETRANDOM */

/* ── Misc ───────────────────────────────────────────────────── */
#define __NR_poll              267   /* MerlionOS SYS_POLL */
#define __NR_ppoll             267   /* reuse */
#define __NR_pselect6          267   /* reuse */
#define __NR_select            267   /* reuse */
#define __NR_uname             204   /* reuse SYS_CPUINFO */
#define __NR_sysinfo           204   /* reuse */
#define __NR_prctl               2   /* stub: SYS_YIELD */
#define __NR_arch_prctl          2   /* stub: SYS_YIELD */
#define __NR_getrlimit           2   /* stub */
#define __NR_setrlimit           2   /* stub */
#define __NR_prlimit64           2   /* stub */
#define __NR_umask              12   /* reuse SYS_CHMOD */
#define __NR_shmget            191   /* MerlionOS SYS_SHMGET */
#define __NR_shmat             192   /* MerlionOS SYS_SHMAT */
#define __NR_shmdt             193   /* MerlionOS SYS_SHMDT */

#endif /* _SYSCALL_MERLIONOS_H */
