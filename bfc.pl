#! /usr/bin/env perl

print(<<EOF
#include <stdio.h>
#include <stdlib.h>
int main() {
      unsigned char * ptr = calloc(30000,1);
EOF
);
while(<>) {
	s/[^\-\+\[\]\<\>\.\,]//g;
	s/\+/++(*ptr);/g;
	s/\-/--(*ptr);/g;
	s/</ptr--;/g;
	s/>/ptr++;/g;
	s/\./putchar(*ptr);/g;
	s/,/(*ptr)=getchar();/g;
	s/\[/while(*ptr){/g;
	s/\]/}/g;
	print;
}
print"}\n";
