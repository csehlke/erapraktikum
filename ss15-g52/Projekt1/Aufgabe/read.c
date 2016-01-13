/* $Id: read_tgidata.c,v 1.4 2000/07/05 15:38:57 drum Exp $ */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "read.h"

/// ----------------------------------------------------------------------
/// This structure holds the program arguments after they're being parse
/// in parseargs().
/// ----------------------------------------------------------------------
struct
{
	int verbose;
	int show_results;
	const char* filename;
} g_args;

/// ----------------------------------------------------------------------
/// Prints the command-line usage of the program.
/// ----------------------------------------------------------------------
void usage(char* prgname)
{
	printf("usage: %s [-v] [-s] [file] \n", prgname);
}

/// ----------------------------------------------------------------------
/// Parses the command-line arguments into the #g_args structure.
/// ----------------------------------------------------------------------
void parseargs(int argc, char** argv)
{
	memset(&g_args, 0, sizeof(g_args));
	int i, error = 0;
	for (i = 1; i < argc && error == 0; ++i) {
		const char* arg = argv[i];
		if (*arg == '-') {
			while (*++arg && error == 0) {
				switch (*arg) {
					case 'v':
						g_args.verbose++;
						break;
					case 's':
						g_args.show_results = 1;
						break;
					default:
						printf("error: unknown flag %c\n", *arg);
						error = 1;
						break;
				}
			}
		}
		else if (arg[0] == '\0') {
			printf("error: zero-length argument passed\n");
		}
		else if (g_args.filename != NULL) {
			printf("error: filename already specified\n");
			error = 1;
			break;
		}
		else {
			g_args.filename = arg;
		}
	}
	if (error) {
		usage(argv[0]);
		exit(-1);
	}
}

/// ----------------------------------------------------------------------
/// Entry point.
/// ----------------------------------------------------------------------
int main(int argc, char** argv)
{
	parseargs(argc, argv);

	// Open the input file or use stdin if no file was specified.
	FILE* fin = NULL;
	if (g_args.filename) {
		fin = fopen(g_args.filename, "r");
		if (!fin) {
			perror("Can't open file");
			exit(1);
		}
	}
	else {
		fin = stdin;
	}

	// Allocate the data buffers.
	float* data1 = (float*) malloc(MAXLINES * sizeof(float));
	float* data2 = (float*) malloc(MAXLINES * sizeof(float));
	float* results1 = (float*) malloc(MAXLINES * sizeof(float));
	float* results2 = (float*) malloc(MAXLINES * sizeof(float));
	if (!data1 || !data2 || !results1 || !results2) {
		perror("Can't allocate enough memory.");
		exit(2);
	}

	// Read in the lines from the file.
	if (g_args.verbose >= 1) {
		if (g_args.filename)
			printf("Reading from input files %s ...\n", g_args.filename);
		else
			printf("Reading from stdin ...\n");
	}
	int nlines = 0;
	char line[MAXLINELENGTH];
	while (!feof(fin)) {
		int index;
		if (nlines > MAXLINES-1) {
			fprintf(stderr, "Aborting at %d lines.\n", nlines);
			break;
		}
		if (fgets(line, MAXLINELENGTH, fin) == NULL)
			break;
		if (g_args.verbose >= 3) {
			printf("* %s", line);
		}
		if (sscanf(line, "%f  mm  %f  mm", &data1[nlines], &data2[nlines]) != 2) {
			fprintf(stderr, "Error in line: %s\n",line);
			fprintf(stderr, "Aborted.");
			break;
		}
		nlines++;
	}

	if (g_args.verbose >= 1) {
		printf("Read %d entries.\n", nlines);
	}

	// Close the input file if we're not reading from stdin.
	if (g_args.filename) fclose(fin);

	// Call the externed calc() function.
	if (g_args.verbose >= 2) {
		printf("read.c: calc(%d, %X, %X, %X, %X)\n",
		   nlines, (int) data1, (int) data2,
		   (int) results1, (int) results2);
	}
	calc(nlines, data1, data2, results1, results2);

	// Output the results if we are supposed to.
	if (g_args.show_results) {
		int i;
		float l1, l2;
		printf("\n\nResults:\n");
		for(i = 0; i < nlines; i++) {
			l1 = data1[i]; l2 = data2[i];
			printf("results1[%u] = %3.4f (expected %3.4f)\n", i, results1[i], l1/l2);
		}
		printf("\n");
		for(i = 0; i < 3; i++) {
			printf("results2[%u] = %f\n", i, results2[i]);
		}
	}
	return 0;
}

