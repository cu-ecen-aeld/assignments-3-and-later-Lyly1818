#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <errno.h>
#include <fcntl.h>     // For open() and O_* constants
#include <unistd.h>    // For close(), write(), etc.


int main(int argc, char *argv[]){

		//Initializing syslog 
		openlog("writer", LOG_CONS | LOG_PID | LOG_NDELAY, LOG_USER);


		if(argc != 3 ){

			syslog(LOG_ERR, "Invalid number of arguments: %d", argc);

			closelog();

			return 1;



		}


		const char *writerfile = argv[1];
		const char *writerstr = argv[2];

		//opening the file 
		int fd = open(writerfile, O_CREAT | O_WRONLY | O_TRUNC, 0644);
		if(fd == -1)
		{

			syslog(LOG_ERR, "Could  not open the file %s for writing: %s", writerfile, writerstr);

		}



		return 1;
		
		
		}
