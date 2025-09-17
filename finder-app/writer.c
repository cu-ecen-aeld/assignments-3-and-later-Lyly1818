#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <syslog.h>

int main(int argc,char *argv[])
{
    //initializing syslog
    openlog("writer", LOG_PID, LOG_USER);

    //check if exactly 2 arguments are passed
    if (argc  != 3)
    {
        syslog(LOG_ERR, "Errors: 2 arguments are required");
        closelog();
        return 1;
    }

    //storing arguments
    char *writerfile = argv[1];
    char *writerstr = argv[2];


    //check if either of the arguments are empty
    if (strlen(writerfile) == 0 || strlen(writerstr) == 0)
    {
        syslog(LOG_ERR, "Arguments connanr be empty");
        closelog();
        return 1;
    }



//Log the writing operations
    syslog(LOG_DEBUG, "Writing file %s and %s", writerfile, writerstr);

    int fd = open(writerfile, O_CREAT | O_WRONLY | O_TRUNC , 0644);
    //handling failure
    if (fd == -1)
    {
        syslog(LOG_ERR, "Errors: System failed to create or write file: %s", writerfile);
        closelog();
        return 1;
    }

    size_t str_len = strlen(writerstr);
    ssize_t bytes_written = write( fd, writerstr, str_len);
    if (bytes_written == -1)
    {
       syslog(LOG_ERR, "Errors: System failed to write to file: %s", writerfile);
        closelog();
        return 1;
    }

    //check if all bytes were written
    if ((size_t)bytes_written != str_len)
    {
//        syslog(LOG_ERR, "Errors Partial wrte to file: %s -> wrote %zd of %zu bytes");
        
        closelog();
        return 1;
    }

    //closing the file descriptor

    // close(fd);
    //handling failure
    
    if (close(fd)== -1)
    {
        syslog(LOG_ERR, "Failed to close");
        closelog();
        return 1;
    }
    closelog();

    return 0;
}
