/* FreePanel setuid wrapper */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#define INTERPRETER		"/usr/bin/perl"
#define SCRIPT			"/change/me/push.pl"

int main (int argc, char * argv[]) {

	char ** args;
	int i;

	args = malloc (sizeof (char *) * (argc + 2));
	if (getuid() != 1004)
        exit (EXIT_FAILURE);


	if (NULL == args) {
		fprintf (stderr, "%s: malloc: %s\n", argv[0], strerror (errno));
		exit (EXIT_FAILURE);
	}

	args[0] = INTERPRETER;
	args[1] = SCRIPT;

	for (i = 1; i < argc; ++i)
		args[i + 1] = argv[i];

	args[i + 1] = NULL;

	if (0 != setreuid (geteuid (), geteuid ())) {
		fprintf (stderr, "%s: setreuid: %s\n", argv[0], strerror (errno));
		exit (EXIT_FAILURE);
	}

	if (0 != execv (INTERPRETER, args)) {
		fprintf (stderr, "%s: execv: %s\n", argv[0], strerror (errno));
		exit (EXIT_FAILURE);
	}

	abort ();
}
