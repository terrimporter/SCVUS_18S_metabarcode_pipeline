# README

This repository outlines how 18S rDNA metabarcodes are processed by Teresita M. Porter. **SCVUS** refers to the programs, algorithms, and reference datasets used in this data flow: **S**EQPREP, **C**UTADAPT, **V**SEARCH, **U**SEARCH-UNOISE, **S**ILVA. 

The pipeline begins with raw Illumina MiSeq fastq.gz files with paired-end reads.  Reads are paired.  Primers are trimmed.  All the samples are pooled for a global analysis.  Reads are dereplicated and denoised producing a reference set of exact sequence variants (ESVs).  These ESVs are taxonomically assigned using the 18S reference set available from https://github.com/terrimporter/18SClassifier and is used with the RDP Classifier (Wang et al., 2007) available from https://sourceforge.net/projects/rdp-classifier/ .  The reference set is based on the SILVA 132 SSURef Nr99 dataset (Preuss et al., 2007) but has been modified to remove taxa with multiple conflicting lineages.

This data flow has been developed using a conda environment and snakemake pipeline for improved reproducibility.  It will be updated on a regular basis so check for the latest version at https://github.com/terrimporter/SCVUS_18S_metabarcode_pipeline/releases

## Outline

[Standard pipeline](#standard-pipeline) 

[Alternate pipeline](#alternate-pipeline)  

[Implementation notes](#implementation-notes)  

[References](#references)  

## Standard pipeline

1. This pipeline includes a conda environment that provides most of the programs needed to run this pipeline (SNAKEMAKE, SEQPREP, CUTADAPT, VSEARCH, etc.).

```linux
# Create the environment from the provided environment.yml file
conda env create -f environment.yml

# Activate the environment
conda activate myenv
```
2. The pipeline requires commercial software for the denoising step.  A free 32-bit version of USEARCH v11.0.667 can be obtained from https://drive5.com/usearch/download.html .  Be sure to put the program in your PATH, ex. ~/bin .  Make it executable and rename it to simply usearch11.

```linux
mv usearch11.0.667_i86linux32 ~/bin/.
cd ~/bin
chmod 755 usearch11.0.667_i86linux32
mv usearch11.0.667_i86linux32 usearch11
```

3. The pipeline also requires the RDP classifier for the taxonomic assignment step.  Although the RDP classifier v2.2 is available through conda, a newer v2.12 is available form SourceForge at https://sourceforge.net/projects/rdp-classifier/ .  Download it and take note of where the classifier.jar file is as this needs to be added to config.yaml .

The RDP classifier comes with the training sets to classify 16S, fungal ITS and fungal LSU rDNA sequences.  To classify 18S sequences, obtain the training set from GitHub 
https://github.com/terrimporter/18SClassifier .  Take note of where the rRNAclassifier.properties file is as this needs to be added to the config.yaml .

```linux
RDP:
    jar: "/path/to/rdp_classifier_2.12/dist/classifier.jar"
    t: "/path/to/18S_Eukaryota/v3.2/mydata/mydata_trained/rRNAClassifier.properties"
```

4. In most cases, your raw paired-end Illumina reads can go into a directory called 'data' which should be placed in the same directory as the other files that come with this pipeline.

```linux
# Create a new directory to hold your raw data
mkdir data
```

5. Please go through the config.yaml file and edit directory names, filename patterns, etc. as necessary to work with your filenames.

6. Be sure to edit the first line of each Perl script (shebang) in the perl_scripts directory to point to where Perl is installed.

```linux
# The usual shebang if you already have Perl installed
#!/usr/bin/perl

# Alternate shebang if you want to run perl using the conda environment (edit this)
#!/path/to/miniconda3/envs/myenv/bin/perl
```

7. Run snakemake by indicating the number of jobs or cores that are available to run the whole pipeline.  

```linux
snakemake --jobs 24 --snakefile snakefile --configfile config.yaml
```

## Alternate pipeline

This section describes modification to the standard pipeline described above when you get a message from 32-bit USEARCH that you have exceeded memory availble.  Instead of processing all the reads in one go, you can denoise each run on its own to keep file sizes small.

1. Instead of putting all raw read files in a directory called 'data'.  Put them in their own directories according to run, ex. run1.  Edit the 'dir' variable in the config.yaml file as follows:

```linux
raw: "run1"
```

2. The output directory also needs to be edited in the config.yaml file:

```linux
dir: "run1_out"
```

3. Please go through the config.yaml file and edit directory names, filename patterns, etc. as necessary to work with your filenames.

4. Run snakemake with the alternate snakefile as follows, be sure to indicate the number of jobs/cores available to run the whole pipeline.

```linux
snakemake --jobs 24 --snakefile snakefile_alt --configfile config.yaml
```

5. Run steps 1-4 for each run directory, ex. run1, run2, run3, etc.

6. Combine and dereplicate the denoised ESVs from each run and put them in a directory named after the amplicon, for example:

```linux
# Combine the denoised ESVs from each run
cat run1/cat.denoised run2/cat.denoised run3/cat.denoised > 18Sv4/cat.denoised.tmp

# Dereplicate the denoised ESVs
vsearch --derep_fulllength 18Sv4/cat.denoised.tmp --output 18Sv4/cat.denoised --sizein --sizeout
```

7. Edit the config.yaml 'dir' variable:

```linux
dir: "18Sv4"
```

8. Continue with the standard snakelake pipeline, be sure to edit the number of jobs/cores available to run the whole pipeline.

```linux
snakemake --jobs 24 --snakefile snakefile --configfile config.yaml
```

## Implementation notes

### Installing conda

Conda is an open source package and envirobnment management system.  Miniconda is a lightweight version of conda that only contains conda, python, and their dependencies.  Using conda can help get all the necessary programs in one place to run the snakemake pipeline.

Install miniconda as follows:

```linux
# Download miniconda3
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh

# Install miniconda3
sh Miniconda3-latest-Linux-x86_64.sh

# Add conda to your PATH, ex. to ~/bin
cd ~/bin
ln -s miniconda3/bin/conda conda
```

### Batch renaming of files

Sometimes it is necessary to rename large numbers of sequence files.  I prefer to use Perl-rename (Gergely, 2018) that is available at https://github.com/subogero/rename as opposed to linux rename.  I prefer the Perl implementation so that you can easily use regular expressions.  I first run the command with the -n flag so you can review the changes without making any actual changes.  If you're happy with the results, re-run without the -n flag.

```linux
rename -n 's/PATTERN/NEW PATTERN/g' *.gz
```

### Symbolic links

Instead of continually traversing nested directories to get to files, I create symbolic links to target directories in a top level directory.  Symbolic links can also be placed in your ~/bin directory that point to scripts that reside elsewhere on your system.  So long as those scripts are executable (e.x. chmod 755 script.plx) then the shortcut will also be executable without having to type out the complete path or copy and pasting the script into the current directory.  This can be especially useful so that you don't have to maintain multiple copies of large raw read files in different places.

```linux
ln -s /path/to/target/directory shortcutName
ln -s /path/to/script/script.sh commandName
```

## References

Edgar, R. C. (2016). UNOISE2: improved error-correction for Illumina 16S and ITS amplicon sequencing. BioRxiv. doi:10.1101/081257 .  Available from: https://www.drive5.com/ 

Gergely, S. (2018, January). Perl-rename. Retrieved from https://github.com/subogero/rename  

Martin, M. (2011). Cutadapt removes adapter sequences from high-throughput sequencing reads. EMBnet. Journal, 17(1), pp–10.  Available from: http://cutadapt.readthedocs.io/en/stable/index.html

Pruesse E, Quast C, Knittel K, Fuchs BM, Ludwig WG, Peplies J, Glöckner FO (2007) SILVA: a comprehensive online resource for quality checked and aligned ribosomal RNA sequence data compatible with ARB. Nucl. Acids Res. 35:7188-7196

Rognes, T., Flouri, T., Nichols, B., Quince, C., & Mahé, F. (2016). VSEARCH: a versatile open source tool for metagenomics. PeerJ, 4, e2584. doi:10.7717/peerj.2584  

St. John, J. (2016, Downloaded). SeqPrep. Retrieved from https://github.com/jstjohn/SeqPrep/releases 

Tange, O. (2011). GNU Parallel - The Command-Line Power Tool. ;;Login: The USENIX Magazine, February, 42–47.  Available from: https://www.gnu.org/software/parallel/

Wang, Q., Garrity, G. M., Tiedje, J. M., & Cole, J. R. (2007). Naive Bayesian Classifier for Rapid Assignment of rRNA Sequences into the New Bacterial Taxonomy. Applied and Environmental Microbiology, 73(16), 5261–5267. doi:10.1128/AEM.00062-07 .  Available from: https://sourceforge.net/projects/rdp-classifier/

## Acknowledgements

I would like to acknowedge funding from the Canadian government through the Genomics Research and Development Initiative (GRDI) EcoBiomics project.

Last updated: August 21, 2019
