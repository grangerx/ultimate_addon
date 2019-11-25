#include <unistd.h>
#include <stdio.h>

int main(const int argc, char* const argv[], char** envp) {
    setuid(0);
    execve(argv[1], argv + 1, envp);
    perror("Could not execve");
    return 1;
}
