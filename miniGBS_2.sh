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

while read line
do

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
