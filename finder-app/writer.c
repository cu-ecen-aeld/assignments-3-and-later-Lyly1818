#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <stdio.h>
#include <syslog.h>
#include <errno.h>
#include <string.h>

#include <stdlib.h>
int main(int argc, char *argv[]){


	openlog("writer", LOG_PID | LOG_CONS, LOG_USER);

		const char *writefile;
		char *writestr;
		int fd ;


		if(argc ==  3){

			writefile = argv[1];
			writestr = argv[2];

			fd = open(writefile, O_RDWR );
			//On failure log the error
			if(fd == -1){
				syslog(LOG_ERR, "System failed to opem file %s", strerror(errno));
				closelog();
				return 1;
			}


			syslog(LOG_INFO, "Successfully open %s", writefile);

			//writing the file
			if(write(fd, writestr, strlen(writestr))== -1){

				syslog(LOG_ERR, "Failed to write to file %s: %s", writefile, strerror(errno));
   				fprintf(stderr, "Error: could not write to %s (%s)\n", writefile, strerror(errno));
    				close(fd);
    				exit(EXIT_FAILURE);


					}




		}
		else {

			
			exit(EXIT_FAILURE);

		}

		 printf("Terminating the program\n");






	return 0;
}
