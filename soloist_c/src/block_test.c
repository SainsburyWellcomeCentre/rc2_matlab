#include <stdio.h>
#include <unistd.h>

int
main(int argc, char **argv) {
    printf("sleeping for 5 seconds...\n");
    sleep(5);
    printf("done\n");
}