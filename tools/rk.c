/*
 * Small static helper for poking at the stock Android system:
 *   rk peek ADDR [COUNT]       read 32-bit words of physical memory
 *   rk poke ADDR VALUE         write one 32-bit word
 *   rk i2cscan BUS             list answering addresses (quick read)
 *   rk i2cget BUS ADDR REG [w] read one register byte (or 16-bit word)
 *   rk i2cset BUS ADDR REG VAL write one register byte
 *   rk serve PORT              shell server on 127.0.0.1:PORT (for adb forward)
 */
#include <arpa/inet.h>
#include <fcntl.h>
#include <linux/i2c-dev.h>
#include <linux/i2c.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <unistd.h>

static unsigned long num(const char *s) { return strtoul(s, NULL, 0); }

static int mem(unsigned long addr, unsigned long n, int write, unsigned int val)
{
	int fd = open("/dev/mem", (write ? O_RDWR : O_RDONLY) | O_SYNC);
	if (fd < 0) { perror("/dev/mem"); return 1; }
	unsigned long page = addr & ~0xfffUL, off = addr - page;
	size_t len = (write ? 4 : n * 4) + off;
	volatile unsigned int *p = mmap(NULL, len, PROT_READ | (write ? PROT_WRITE : 0), MAP_SHARED, fd, page);
	if (p == MAP_FAILED) { perror("mmap"); return 1; }
	p = (volatile unsigned int *)((char *)p + off);
	if (write) { *p = val; n = 1; }
	for (unsigned long i = 0; i < n; i++)
		printf("0x%08lx 0x%08x\n", addr + i * 4, p[i]);
	return 0;
}

static int i2c_open(const char *bus, int addr)
{
	char path[32];
	snprintf(path, sizeof(path), "/dev/i2c-%s", bus);
	int fd = open(path, O_RDWR);
	if (fd < 0) { perror(path); exit(1); }
	if (addr >= 0 && ioctl(fd, I2C_SLAVE_FORCE, addr) < 0) { perror("I2C_SLAVE_FORCE"); exit(1); }
	return fd;
}

static int i2c_rw(int fd, int addr, unsigned char *w, int wn, unsigned char *r, int rn)
{
	struct i2c_msg m[2];
	int n = 0;
	if (wn) m[n++] = (struct i2c_msg){ .addr = addr, .flags = 0, .len = wn, .buf = w };
	if (rn) m[n++] = (struct i2c_msg){ .addr = addr, .flags = I2C_M_RD, .len = rn, .buf = r };
	struct i2c_rdwr_ioctl_data d = { .msgs = m, .nmsgs = n };
	return ioctl(fd, I2C_RDWR, &d) < 0 ? -1 : 0;
}

static int serve(int port)
{
	signal(SIGCHLD, SIG_IGN);
	int s = socket(AF_INET, SOCK_STREAM, 0), one = 1;
	setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));
	struct sockaddr_in a = { .sin_family = AF_INET, .sin_port = htons(port) };
	a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
	if (bind(s, (void *)&a, sizeof(a)) || listen(s, 4)) { perror("bind"); return 1; }
	for (;;) {
		int c = accept(s, NULL, NULL);
		if (c < 0) continue;
		if (fork() == 0) {
			dup2(c, 0); dup2(c, 1); dup2(c, 2); close(s);
			execl("/system/bin/sh", "sh", NULL);
			_exit(127);
		}
		close(c);
	}
}

int main(int argc, char **argv)
{
	if (argc < 2) goto usage;
	const char *cmd = argv[1];
	if (!strcmp(cmd, "peek") && argc >= 3)
		return mem(num(argv[2]), argc > 3 ? num(argv[3]) : 1, 0, 0);
	if (!strcmp(cmd, "poke") && argc == 4)
		return mem(num(argv[2]), 1, 1, num(argv[3]));
	if (!strcmp(cmd, "i2cscan") && argc == 3) {
		int fd = i2c_open(argv[2], -1);
		for (int a = 0x03; a < 0x78; a++) {
			unsigned char b;
			if (i2c_rw(fd, a, NULL, 0, &b, 1) == 0) printf("0x%02x\n", a);
		}
		return 0;
	}
	if (!strcmp(cmd, "i2cget") && (argc == 5 || argc == 6)) {
		int fd = i2c_open(argv[2], -1), a = num(argv[3]);
		unsigned char reg = num(argv[4]), v[2];
		int n = argc > 5 ? 2 : 1;
		if (i2c_rw(fd, a, &reg, 1, v, n)) {
			/* Some vendor I2C drivers reject combined transfers */
			if (ioctl(fd, I2C_SLAVE_FORCE, a) < 0 || write(fd, &reg, 1) != 1 ||
			    read(fd, v, n) != n) { perror("i2c"); return 1; }
		}
		if (n == 2) printf("0x%02x%02x\n", v[0], v[1]);
		else printf("0x%02x\n", v[0]);
		return 0;
	}
	if (!strcmp(cmd, "i2cset") && argc == 6) {
		int fd = i2c_open(argv[2], -1), a = num(argv[3]);
		unsigned char w[2] = { num(argv[4]), num(argv[5]) };
		if (i2c_rw(fd, a, w, 2, NULL, 0)) { perror("i2c"); return 1; }
		return 0;
	}
	if (!strcmp(cmd, "serve") && argc == 3)
		return serve(num(argv[2]));
usage:
	fprintf(stderr, "rk peek|poke|i2cscan|i2cget|i2cset|serve ...\n");
	return 1;
}
