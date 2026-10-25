#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/wait.h>

int main(int argc, char **argv)
{
        (void)argc;
        (void)argv;
        printf("probe: musl static OK\n");

        /* mmap 匿名 + 写 + 读 + munmap */
        size_t n = 4096;
        char *p = mmap(NULL, n, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
        if (p == MAP_FAILED) {
                perror("mmap");
                return 1;
        }
        strcpy(p, "hello from mmap");
        printf("probe: mmap=%s\n", p);
        munmap(p, n);

        /* fork + wait4 */
        pid_t pid = fork();
        if (pid == 0) _exit(42);
        int st = 0;
        waitpid(pid, &st, 0);
        printf("probe: fork exit=%d\n", WEXITSTATUS(st));

        return 0;
}
