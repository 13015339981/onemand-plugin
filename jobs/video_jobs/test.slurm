#!/bin/bash
#SBATCH --job-name=hello_world
#SBATCH --partition=small 
#SBATCH --output=%j.out
#SBATCH --error=%j.err
#SBATCH -n 1



echo "Hello World" > output_file

echo "Created output file with 'Hello World'"

