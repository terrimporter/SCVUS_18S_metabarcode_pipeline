#!/usr/bin/perl

# Teresita M. Porter, Aug. 7, 2019

# Script to separate primer trimmed reads by run prior to dereplication and denoising
# Do this to stay within memory limit for 32-bit USEARCH
# Also because different runs can have different error profiles (see dada2 documention)
# run.list is a list of files that each contain the files from each run ex. run1.txt, run2.txt, run3.txt, etc.
# each runX.txt file contains a list of the forward and reverse raw read filenames

# USAGE perl sepByRun.plx cat.fasta.gz run.list

use strict;
use warnings;

# declare var
my $line;
my $i=0;
my $j;
my $k=0;
my $runfile;
my $run;
my $sample;
my $seq;

# declare array
my @run;
my @fasta;
my @runfiles;
my @files;
my @line;

# declare hash
my %samples; # key = sample name, value = 1

# open compressed fasta file
open (IN, "gunzip -c $ARGV[0] |") or die "Error cannot read in fasta file: $!\n";
@fasta = <IN>;
close IN;

# open list of files in run
open (IN2, "<", $ARGV[1]) || die "Error cannot open text file: $!e\n";
@runfiles = <IN2>;
close IN2;

# test
#my $length = scalar(@runfiles);
#print "$length runfiles read in\n";

while ($runfiles[$k]) {
	$runfile = $runfiles[$k];
	chomp $runfile;

	open (RUN, "<", $runfile) || die "Error cannot open runfile: $!\n";
	@files = <RUN>;
	close RUN;

	@run = split(/\./, $runfile);
	$run = $run[0];

	# remove filename suffix ".fasta.gz"
	foreach $line (@files) {
		chomp $line;

		$line =~ s/_R(1|2)_001\.fastq\.gz//;
		$line =~ s/-/_/g;
		$samples{$line} = 1;

	}

	# create a new fasta file for the filtered reads
	open (OUT, ">>", $run.".cat.fasta") || die "Error cannot open outfile: $!\n";

	# loop through each run file
	parse_cat_file();
	
	@files=();
	%samples=();
	$k++;

}	
$k=0;

################################################

sub parse_cat_file {

# filter the original fasta file
while ($fasta[$i]) {
	$line = $fasta[$i];
	chomp $line;
#	print $line."\n"; #test

	if ($line =~ /^>/) {
		@line = split(/;/, $line);
		$sample = $line[0];
		$sample =~ s/^>//;
#		print $sample."\n"; #test

		if (exists $samples{$sample}) {
			print OUT $line."\n";
			$j = $i+1;
			$seq = $fasta[$j];
			chomp $seq;
			print OUT $seq."\n";
			$i+=2;
		}
		else {
			$i+=2;
			next;
		}
	}
	else {
		$i++;
		next;
	}

}
$i=0;

}

close OUT;
