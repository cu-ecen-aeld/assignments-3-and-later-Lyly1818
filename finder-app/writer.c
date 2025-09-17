#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <syslog.h>

int main(int argc, char *argv[])
{
    openlog("writer", LOG_PID, LOG_USER);

    if (argc != 3) {
        syslog(LOG_ERR, "Error: 2 arguments are required");
        fprintf(stderr, "Error: 2 arguments are required\n");
        closelog();
        return 1;
    }

    char *writerfile = argv[1];
    char *writerstr = argv[2];

    if (strlen(writerfile) == 0 || strlen(writerstr) == 0) {
        syslog(LOG_ERR, "Error: Arguments cannot be empty");
        fprintf(stderr, "Error: Arguments cannot be empty\n");
        closelog();
        return 1;
    }

    syslog(LOG_DEBUG, "Writing file %s and %s", writerfile, writerstr);
    fprintf(stderr, "Writing file %s and %s\n", writerfile, writerstr);

    int fd = open(writerfile, O_CREAT | O_WRONLY | O_TRUNC, 0644);
    if (fd == -1) {
        syslog(LOG_ERR, "Error: Failed to create or write file: %s", writerfile);
        fprintf(stderr, "Error: Failed to create or write file: %s\n", writerfile);
        closelog();
        return 1;
    }

    size_t str_len = strlen(writerstr);
    ssize_t bytes_written = write(fd, writerstr, str_len);
    if (bytes_written == -1) {
        syslog(LOG_ERR, "Error: Failed to write to file: %s", writerfile);
        fprintf(stderr, "Error: Failed to write to file: %s\n", writerfile);
        closelog();
        return 1;
    }

    if ((size_t)bytes_written != str_len) {
        syslog(LOG_ERR, "Error: Partial write to file: %s -> wrote %zd of %zu bytes",
               writerfile, bytes_written, str_len);
        fprintf(stderr, "Error: Partial write to file: %s -> wrote %zd of %zu bytes\n",
                writerfile, bytes_written, str_len);
        closelog();
        return 1;
    }

    if (close(fd) == -1) {
        syslog(LOG_ERR, "Error: Failed to close file %s", writerfile);
        fprintf(stderr, "Error: Failed to close file %s\n", writerfile);
        closelog();
        return 1;
    }

    closelog();
    return 0;
}
