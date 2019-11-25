#include <stdio.h>
#include <unistd.h>

int main(const int argc, const char* argv[]) {
    printf("getuid: %d\n", getuid());
    printf("geteuid: %d\n", geteuid());
    return 0;
}
