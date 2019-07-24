#include <stdio.h>
#include <unistd.h>

#define MAX_REQUESTS 30

int main(int argc, char **argv) {
    
    int i = 0;
    char *const args[] = {"wsk", "action", "invoke", "test", "-r", "-i", NULL};
    const char *path = "/usr/local/bin/wsk";
    for (i = 0; i < MAX_REQUESTS; i++) {
        pid_t pid = fork();
        if (pid < 0) {
            printf("%s\n", "NO Fork Done");
            continue;
        } else if (pid == 0) {
            execv(path, args);
        }


    }


}
