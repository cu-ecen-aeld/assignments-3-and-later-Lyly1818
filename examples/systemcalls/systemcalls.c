#include "systemcalls.h"
#include <stdlib.h>      // for exit(), EXIT_FAILURE
#include <unistd.h>      // for fork(), execv(), close(), dup2()
#include <sys/types.h>   // for pid_t type
#include <sys/wait.h>    // for waitpid(), WIFEXITED(), WEXITSTATUS()
#include <fcntl.h>       // for open(), O_WRONLY, O_CREAT, O_TRUNC
#include <stdio.h>       // for perror()
#include <stdarg.h>      // for va_list, va_start(), va_arg(), va_end()
/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system(const char *cmd)
{

/*
 * TODO  add your code here
 *  Call the system() function with the command set in the cmd
 *   and return a boolean true if the system() call completed with success
 *   or false() if it returned a failure
*
*/

	int result = system(cmd);
	if(result == -1)
	{
		printf("System call failed.\n");
		return false;
	}

	//checking child exit status
	if(WIFEXITED(result) && WEXITSTATUS(result) == 0){

		return true;// command ran successfully
	}
	else
	{
		return false; // command failer or exited with non zero status
	}

    return true;
}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/

bool do_exec(int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    command[count] = command[count];

/*
 * TODO:
 *   Execute a system command by calling fork, execv(),
 *   and wait instead of system (see LSP page 161).
 *   Use the command[0] as the full path to the command to execute
 *   (first argument to execv), and use the remaining arguments
 *   as second argument to the execv() command.
 *
*/


    va_end(args);

    //for a new process
    pid_t pid = fork();
    if(pid == -1){
	    perror("Fork failed");
	    return false;
    }


    

   // va_end(args);

    //return true;
    //

    if (pid == 0) {
        // *** CHILD PROCESS ***
        // We're now in the child process. Replace it with the command.

        /*
         * execv() replaces the current process image with a new program
         * command[0] = full path to executable (e.g., "/bin/echo")
         * command = array of arguments including command[0]
         *
         * If execv() succeeds, this code never returns!
         * If it returns, something went wrong.
         */
        execv(command[0], command);

        // If we get here, execv() failed
        perror("execv");
        exit(EXIT_FAILURE);  // Exit child process with failure
    }

    // *** PARENT PROCESS ***
    // Wait for the child process to complete
    int status;

    /*
     * waitpid() suspends parent until child terminates
     * pid = the child process ID we're waiting for
     * &status = where to store exit status
     * 0 = options (none in this case)
     */
    if (waitpid(pid, &status, 0) == -1) {
        // Wait failed
        perror("waitpid");
        return false;
    }

    /*
     * Check if child exited normally and with success
     * WIFEXITED(status) = true if child terminated normally
     * WEXITSTATUS(status) = exit code of child (0 = success)
     */
    if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
        return true;
    }

    return false;
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;

    va_end(args);
    
    pid_t pid = fork();
    if (pid == -1) {
        perror("fork");
        return false;
    }
    if (pid == 0) {
        int fd = open(outputfile, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd == -1) {
            perror("open");
            exit(EXIT_FAILURE);
        }
        
        if (dup2(fd, STDOUT_FILENO) == -1) {
            perror("dup2");
            close(fd);
            exit(EXIT_FAILURE);
        }
        
        close(fd);
        
        execv(command[0], command);
        
        perror("execv");
        exit(EXIT_FAILURE);
    }
    
    int status;
    if (waitpid(pid, &status, 0) == -1) {
        perror("waitpid");
        return false;
    }
    if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
        return true;
    }
    return false;
   // return true;
}
