#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define BUF_SIZE 4096

static int ensure_file(const char *path) {
    FILE *f = fopen(path, "a");
    if (!f) {
        perror(path);
        return 1;
    }
    fclose(f);
    return 0;
}

static int cmd_add(const char *path, const char *service, const char *user, const char *pass) {
    if (ensure_file(path)) return 1;
    FILE *f = fopen(path, "a");
    if (!f) {
        perror(path);
        return 1;
    }
    if (fprintf(f, "%s|%s|%s\n", service, user, pass) < 0) {
        perror("write");
        fclose(f);
        return 1;
    }
    fclose(f);
    return 0;
}

static int cmd_list(const char *path) {
    if (ensure_file(path)) return 1;
    FILE *f = fopen(path, "r");
    if (!f) {
        perror(path);
        return 1;
    }
    char buf[BUF_SIZE];
    while (fgets(buf, sizeof buf, f)) {
        fputs(buf, stdout);
    }
    fclose(f);
    return 0;
}

static int cmd_search(const char *path, const char *term) {
    if (ensure_file(path)) return 1;
    FILE *f = fopen(path, "r");
    if (!f) {
        perror(path);
        return 1;
    }
    char buf[BUF_SIZE];
    int found = 0;
    while (fgets(buf, sizeof buf, f)) {
        if (strstr(buf, term)) {
            fputs(buf, stdout);
            found = 1;
        }
    }
    fclose(f);
    return found ? 0 : 1;
}

static int cmd_delete(const char *path, const char *service) {
    if (ensure_file(path)) return 1;
    FILE *in = fopen(path, "r");
    if (!in) {
        perror(path);
        return 1;
    }
    char tmp[] = "/tmp/passmgrXXXXXX";
    int fd = mkstemp(tmp);
    if (fd == -1) {
        perror("mkstemp");
        fclose(in);
        return 1;
    }
    FILE *out = fdopen(fd, "w");
    if (!out) {
        perror("fdopen");
        close(fd);
        unlink(tmp);
        fclose(in);
        return 1;
    }
    char buf[BUF_SIZE];
    size_t len = strlen(service);
    int removed = 0;
    while (fgets(buf, sizeof buf, in)) {
        if (strncmp(buf, service, len) == 0 && buf[len] == '|') {
            removed = 1;
            continue;
        }
        fputs(buf, out);
    }
    fclose(in);
    if (fclose(out) != 0) {
        perror("fclose");
        unlink(tmp);
        return 1;
    }
    if (rename(tmp, path) != 0) {
        perror("rename");
        unlink(tmp);
        return 1;
    }
    return removed ? 0 : 1;
}

static void usage(void) {
    fprintf(stderr, "\nusage: ./passmgr <add|list|search|delete> [args]\n\n");
    fprintf(stderr, "add: ./passmgr add service username password\n");
    fprintf(stderr, "list: ./passmgr list\n");
    fprintf(stderr, "search: ./passmgr search service\n");
    fprintf(stderr, "delete: ./passmgr delete service\n");
}

int main(int argc, char **argv) {
    if (argc < 3) {
        usage();
        return 1;
    }
    const char *cmd = argv[1];
    const char *path = argv[2];
    if (strcmp(cmd, "add") == 0) {
        if (argc != 6) {
            usage();
            return 1;
        }
        return cmd_add(path, argv[3], argv[4], argv[5]);
    }
    if (strcmp(cmd, "list") == 0) {
        if (argc != 3) {
            usage();
            return 1;
        }
        return cmd_list(path);
    }
    if (strcmp(cmd, "search") == 0) {
        if (argc != 4) {
            usage();
            return 1;
        }
        return cmd_search(path, argv[3]);
    }
    if (strcmp(cmd, "delete") == 0) {
        if (argc != 4) {
            usage();
            return 1;
        }
        return cmd_delete(path, argv[3]);
    }
    usage();
    return 1;
}

