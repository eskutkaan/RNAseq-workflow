# Define reference genome and annotation file
ref_genome = "path/to/reference/genome"
annotation_file = "path/to/reference/annotation"
ref_index = "path/to/reference/hisat2index"


# Define list of samples to process
samples, = glob_wildcards("data/{sample}_R1.fq.gz")


# Define the workflow
rule all:
    input:
        expand("counts/{sample}/{sample}.gtf", sample=samples)

# Define the rule to align reads to the reference genome using HISAT2
rule hisat2:
    input:
        r1 = "data/{sample}_R1.fq.gz",
        r2 = "data/{sample}_R2.fq.gz"
    output:
        sam = "alignments/{sample}.sam"
    shell:
        """
	hisat2 -x reference/[index_name] -1 {input.r1} -2 {input.r2} -p 128 --dta -S {output.sam} 
	"""

rule sambam:
    input:
        sam = "alignments/{sample}.sam"
    output:
        bam = "alignments/{sample}.bam"
    shell:
        """
    samtools sort -@ 128 {input.sam} -o {output.bam}
    """

# Define the rule to assemble transcripts and generate gene count tables using StringTie
rule stringtie_count:
    input:
        bam = "alignments/{sample}.bam",
        annotation = annotation_file
    output:
        counts = "counts/{sample}/{sample}.gtf"
    shell:
        "stringtie -p 128 {input.bam} -G {input.annotation} -e -o {output.counts}"
