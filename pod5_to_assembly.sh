#! /bin/bash

# This script will convert POD5 files from a nanopore sequencer to an assembled genome sequence.
# pod5 dir -> dorado basecaller (pod5s to bam)-> samtools (bam to fasta) -> flye (assemble fasta) -> quast (evaluate assembly) -> output
# Usage: ./pod5_to_assembly.sh --basecaller <basecaller> (hac or sup; default is sup) --pod5_dir <POD5 directory> --output_dir <output directory>

# Check if the correct number of arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 --basecaller <basecaller> --pod5_dir <POD5 directory> --output_dir <output directory>"
    exit 1
fi

# Parse the arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --basecaller)
            basecaller="$2"
            shift 2
            ;;
        --pod5_dir)
            pod5_dir="$2"
            shift 2
            ;;
        --output_dir)
            output_dir="$2"
            shift 2
            ;;
    esac
done

# Check if dependencies are installed
if ! command -v dorado &> /dev/null; then
    echo "dorado could not be found. Please install it from https://github.com/nanoporetech/dorado"
    exit 1
fi

if ! command -v samtools &> /dev/null; then
    echo "samtools could not be found. Please install it from https://github.com/samtools/samtools"
    exit 1
fi

if ! command -v flye &> /dev/null; then
    echo "flye could not be found. Please install it from https://github.com/fenderglass/Flye"
    exit 1
fi

if ! command -v quast.py &> /dev/null; then
    echo "quast could not be found. Please install it from https://github.com/ablab/quast"
    exit 1
fi

# Check if the basecaller is valid
if [ "$basecaller" != "hac" ] && [ "$basecaller" != "sup" ]; then
    echo "Invalid basecaller: $basecaller. Please use 'hac' or 'sup'."
    exit 1
fi

# Check if the pod5 directory exists
if [ ! -d "$pod5_dir" ]; then
    echo "POD5 directory does not exist: $pod5_dir"
    exit 1
fi

# Check if the output directory exists else make it
if [ ! -d "$output_dir" ]; then
    echo "Output directory does not exist: $output_dir. Creating it now..."
    mkdir -p "$output_dir"
fi

# Run dorado basecaller
echo "Running dorado basecaller..."
dorado basecaller --fast5-dir "$pod5_dir" --output-dir "$output_dir/basecalling" --model "$basecaller"

# Run samtools to convert bam to fasta
echo "Running samtools to convert bam to fasta..."
samtools fasta "$output_dir"/basecalling/calls.bam > "$output_dir"/assembly.fasta

# Run flye to assemble fasta
echo "Running flye to assemble fasta..."
flye --nano-raw "$output_dir"/assembly.fasta --out-dir "$output_dir"/assembly --threads 4

# Run quast to evaluate assembly
echo "Running quast to evaluate assembly..."
quast.py -o "$output_dir"/assembly_quast "$output_dir"/assembly.fasta

echo "Assembly complete. Results can be found in $output_dir"