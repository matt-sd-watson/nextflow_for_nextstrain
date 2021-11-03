# nextflow_for_nextstrain

Parallelization of Nextstrain builds and parameter testing using Nextflow

## Installation using conda

A conda environment for running nextstrain in Nextflow can be created with the following: 

The package requires conda to be installed in the current environment. 

```
git https://github.com/matt-sd-watson/nextflow_for_nextstrain.git
cd nextflow_for_nextstrain
conda env create -f environments/environment.yml
conda activate nf_nextstrain

```

## Running the pipeline

The nextflow pipeline for nextstrain can be run using the following commands: 


```
nextflow run nextflow_for_nextflow/ --mode # insert mode here (see below) -profile # insert profile here (see below)

```

The following modes are currently supported: 


```
random_subsets: create a number of random subset builds
refine_iterations: Generate a number of random builds and test augur refine clock parameters on each subset
lineages: Given a input list of Pango lineages, create a full build for each lineage

```


## Configuration

All parameters for the different modes can be set using the nextflow.config, or specified as a CLI parameter at runtime.
Note that parameters specified at runtime through the CLI will override the same parameter specified by the nextflow.config

### Configuration variables

The following parameters can be modified in the nextflow.config to support inputs and runtime parameters. Examples of these parameters can be found below: 

```
help = false
subset_number = 100
clockfilteriqd = 10
alignment_ref = '/home/mwatson/COVID-19/reference/reference.gb'
metadata = '/home/mwatson/COVID-19/nextstrain_build/metadata/Nextstrain_metadata_070921_full.csv'
output_dir = '/home/mwatson/COVID-19/one_off/augur_test_2'
colortsv = '/home/mwatson/COVID-19/BCC_dev/BCC_nextstrain/config/colors_2.tsv'
config = '/home/mwatson/COVID-19/BCC_dev/BCC_nextstrain/config/auspice_config.json'
latlong = '/home/mwatson/COVID-19/BCC_dev/BCC_nextstrain/config/lat_ontario_health_unit.tsv'
clades = '/home/mwatson/COVID-19/BCC_dev/BCC_nextstrain/config/clades.tsv'
// threads set to auto uses the total number of cores for each process of align and tree
threads = 1
cleanup = true
start_iteration = 1
stop_iteration = 10
clock = 10
lineages = ['P.1.1', 'A.23.1', 'C.37']
lineage_report = '/NetDrive/Projects/COVID-19/Other/master_fasta/lineage_report_all*plearn.csv'
master_fasta = '/NetDrive/Projects/COVID-19/Other/master_fasta/complete_all*'
nextalign = '/NetDrive/Projects/COVID-19/Other/master_fasta/alignment/complete_all*'
cache = ''
tracedir = "${params.output_dir}/pipeline_info"
refineseed = 10
clean_dir = false
make_alignment = false
```


## Profiles and containers

This pipeline can be run through a Singularity container. To create the container, execute the following: 

```
./environments/create_singularity_container.sh
```

Execution requires root access. 

To enable singularity containeriation at runtime, the user can specify this option through the -profile option, such as the following:


```
nextflow run ~nextflow_for_nextstrain/ --mode refine_iterations -profile singularity
```


The SINGULARITY_BIND variable contains the bound variables for the paths to files on mounted drives. This variable can either be exported explicitly before runtime as shown below:

```
export SINGULARITY_BIND="/NetDrive/Projects/COVID-19/Other/master_fasta"
```

or modified in the nextflow.config under the singularity profile, runOption parameter. 

nextflow_nextstrain also supports running through either a docker or conda profile (not recommended). using docker can assist when the user does not have root access to the environment where nextflow is being executed. This also allows for resource management without requiring sudo access (as is the case with singularity containers).

Running the pipeline just through a conda environment is not recommended.





