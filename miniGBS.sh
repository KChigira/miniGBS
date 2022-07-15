#! /bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") -R referance_genome.fasta -I input.vcf \
                        -S samplenames.txt [OPTION]...
  -h Display help
  -R [Referance Genome].fasta
  -I [Input VCF File].vcf
  -S [Sample name of each fastq].txt
  -n project name               default:"genotyping"
  -d minimum sequence depth     default:6
  -m margin of target sequence   default:150
EOM
  exit 2
}
REF="f"
VCF="f"
SN="f"
NAME="genotyping"
MIN_DEP=10
MARGIN=150

while getopts ":R:I:S:n:d:m:h" optKey; do
  case "$optKey" in
    R) REF=${OPTARG};;
    I) VCF=${OPTARG};;
    S) SN=${OPTARG};;
    n) NAME=${OPTARG};;
    d) MIN_DEP=${OPTARG};;
    m) MARGIN=${OPTARG};;
    '-h'|'--help'|* ) usage;;
  esac
done

#check
[ ! -e ${REF} ] && usage
[ ! -e ${VCF} ] && usage
[ ! -e ${SN} ] && usage
[ ! -e "fastq" ] && usage
[ ${NAME} == "" ] && usage
expr $MIN_DEP + 1 >&/dev/null
[ $? -ge 2 ] && usage
expr $MARGIN + 1 >&/dev/null
[ $? -ge 2 ] && usage

#get absolute path
REF=$(cd $(dirname "$REF") && pwd)/$(basename "$REF")
VCF=$(cd $(dirname "$VCF") && pwd)/$(basename "$VCF")
SN=$(cd $(dirname "$SN") && pwd)/$(basename "$SN")

CURRENT=$(pwd)
cd $(dirname $0)


#Make reference genome file of the target resions.
perl make_samtools_data.pl ${VCF} \
                           ${CURRENT}/${NAME}_list_samtools.txt \
                           ${MARGIN}
if test $? -ne 0 ; then
  echo "Making data for extracting sequence was failed."
  exit 1
fi

mkdir ${CURRENT}/fasta
while read line
do
  samtools faidx ${REF} ${line} \
            >> ${CURRENT}/fasta/${NAME}_reference.fasta
  if test $? -ne 0 ; then
    echo "Extracting sequence from refernce was failed."
    exit 1
  fi
done < ${CURRENT}/${NAME}_list_samtools.txt
bwa index ${CURRENT}/fasta/${NAME}_reference.fasta
echo 'Extracting sequence from refernce has done.'

#Prepare for haplotype calling
mkdir ${CURRENT}/vcf
perl make_template_vcf.pl ${VCF} \
                          ${CURRENT}/vcf/${NAME}_template.vcf \
                          150
samtools faidx ${CURRENT}/fasta/${NAME}_reference.fasta
picard CreateSequenceDictionary \
       R=${CURRENT}/fasta/${NAME}_reference.fasta \
       O=${CURRENT}/fasta/${NAME}_reference.dict
gatk IndexFeatureFile \
     -I ${CURRENT}/vcf/${NAME}_template.vcf

#Trim fastq and quality check
mkdir ${CURRENT}/fastq_trimmed
mkdir ${CURRENT}/qc
mkdir ${CURRENT}/bam
while read line
do
  trimmomatic PE -threads 4 -phred33 \
    ${CURRENT}/fastq/${line}*_R1_*.fastq.gz \
    ${CURRENT}/fastq/${line}*_R2_*.fastq.gz \
    ${CURRENT}/fastq_trimmed/${line}_R1_trimmed.fastq.gz \
    ${CURRENT}/fastq_trimmed/${line}_R1_unpaired.fastq.gz \
    ${CURRENT}/fastq_trimmed/${line}_R2_trimmed.fastq.gz \
    ${CURRENT}/fastq_trimmed/${line}_R2_unpaired.fastq.gz \
    LEADING:20 \
    TRAILING:20 \
    SLIDINGWINDOW:30:20 \
    CROP:150 \
    MINLEN:60

  fastqc -o ${CURRENT}/qc \
         --nogroup \
         ${CURRENT}/fastq_trimmed/${line}_R1_trimmed.fastq.gz \
         ${CURRENT}/fastq_trimmed/${line}_R2_trimmed.fastq.gz

  bwa mem \
      -t 4 \
      -R "@RG\tID:${line}\tLB:${line}\tPL:ILLUMINA\tSM:${line}" \
      ${CURRENT}/fasta/${NAME}_reference.fasta \
      ${CURRENT}/fastq_trimmed/${line}_R1_trimmed.fastq.gz \
      ${CURRENT}/fastq_trimmed/${line}_R2_trimmed.fastq.gz \
      > ${CURRENT}/bam/${line}_aligned_reads.sam

  samtools sort -@ 4 -O bam \
                -o ${CURRENT}/bam/${line}_aligned_reads.bam \
                ${CURRENT}/bam/${line}_aligned_reads.sam
  samtools index ${CURRENT}/bam/${line}_aligned_reads.bam
  rm ${CURRENT}/bam/${line}_aligned_reads.sam

  samtools view -@ 4 -bh -F 256 ${CURRENT}/bam/${line}_aligned_reads.bam \
           > ${CURRENT}/bam/${line}_aligned_reads_primary.bam
  samtools index ${CURRENT}/bam/${line}_aligned_reads_primary.bam

  gatk HaplotypeCaller \
         -R ${CURRENT}/fasta/${NAME}_reference.fasta \
         -I ${CURRENT}/bam/${line}_aligned_reads_primary.bam \
         -O ${CURRENT}/vcf/${line}_raw_variants.vcf \
         --alleles ${CURRENT}/vcf/${NAME}_template.vcf

  perl select_only_target.pl ${CURRENT}/vcf/${line}_raw_variants.vcf \
                             ${CURRENT}/vcf/${NAME}_template.vcf \
                             ${CURRENT}/vcf/${line}_select_variants.vcf

  gatk IndexFeatureFile \
       -I ${CURRENT}/vcf/${line}_select_variants.vcf

done < ${SN}

perl merge_genotypes.pl ${CURRENT}/vcf \
                        ${SN} \
                        ${CURRENT}/vcf/${NAME}_template.vcf \
                        ${CURRENT}/${line}_genotypes.vcf
                        
