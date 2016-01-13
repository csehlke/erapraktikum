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
  float* data1 = malloc(MAXLINES * sizeof(float));
  float* data2 = malloc(MAXLINES * sizeof(float));
  float* results1 = malloc(MAXLINES * sizeof(float));
  float* results2 = malloc(3 * sizeof(float));
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

  if (nlines < 21) {
    fprintf(stderr, "Need at least 21 entries, only got %d\n", nlines);
    exit(4);
  }

  if (g_args.verbose >= 1) {
    printf("Read %d entries.\n", nlines);
  }

  // Close the input file if we're not reading from stdin.
  if (g_args.filename) fclose(fin);

  // Call the externed calc() function.
  calc(&nlines, data1, data2, results1, results2);

  // Output the results if we are supposed to.
  if (g_args.show_results) {
    float* r1expected = malloc(nlines * sizeof(float));
    float* r2expected = malloc(3 * sizeof(float));
    if (!r1expected || !r2expected) {
      perror("Can't allocate memory for C-results");
      exit(3);
    }

    // For comparing the results, we use a C-implementation of
    // the same algorithm implemented in ASM.
    calc_c(nlines, data1, data2, r1expected, r2expected);

    int i;
    float l1, l2;
    printf("\n\nResults:\n");
    for(i = 0; i < nlines; i++) {
      printf("results1[%u] = %3.4f (expected %3.4f)\n", i, results1[i], r1expected[i]);
    }
    printf("\n");
    for(i = 0; i < 3; i++) {
      printf("results2[%u] = %3.4f (expected %3.4f)\n", i, results2[i], r2expected[i]);
    }
  }
  return 0;
}

/// ----------------------------------------------------------------------
/// Little sorting algorithm for float arrays.
/// ----------------------------------------------------------------------
static void sort_c(int nlines, float* data)
{
  int i, j;
  for (i = 0; i < nlines; ++i) {
    float x = data[i];
    for (j = i + 1; j < nlines; ++j) {
      float y = data[j];
      if (y < x) {
        data[j] = x;
        data[i] = y;
        x = y;
      }
    }
  }
}


/// ----------------------------------------------------------------------
/// C-Implementation of calc().
/// ----------------------------------------------------------------------
void calc_c(int nlines, float* data1, float* data2, float* results1, float* results2)
{
  int i;
  for (i = 0; i < nlines; ++i) {
    results1[i] = data1[i] / data2[i];
  }
  sort_c(nlines, results1);

  // Compute Average, ignoring the 10 lowest and highest values.
  float avg = 0.0;
  for (i = 10; i < nlines - 10; ++i) {
    avg += results1[i];
  }
  avg /= (nlines - 20);
  results2[0] = avg;

  // Compute dmax and dmin.
  results2[1] = results1[nlines - 10] - avg;
  results2[2] = avg - results1[10];
}
