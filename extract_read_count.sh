#! /bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") -S samplenames.txt [OPTION]...
  -h Display help
  -O Output file name           default:"read_count"
  -m Minimum length of reads    default:35
  -x Maximam length of reads    default:151
EOM
  exit 2
}

SN="f"
OUT="read_count"
MIN=35
MAX=151

while getopts "S:O:m:x:h" optKey; do
  case "$optKey" in
    S) SN=${OPTARG};;
    O) OUT=${OPTARG};;
    m) MIN=${OPTARG};;
    x) MAX=${OPTARG};;
    '-h'|'--help'|* ) usage;;
  esac
done

#check
[ ! -e ${SN} ] && usage
[ ! -e "qc_before_trim" ] && usage
[ ! -e "qc_after_trim" ] && usage
[ ${OUT} == "" ] && usage
expr $MIN + 1 >&/dev/null
[ $? -ge 2 ] && usage
expr $MAX + 1 >&/dev/null
[ $? -ge 2 ] && usage

#get absolute path
SN=$(cd $(dirname "$SN") && pwd)/$(basename "$SN")

CURRENT=$(pwd)
cd $(dirname $0)



mkdir ${CURRENT}/qc_data

while read line
do
  unzip ${CURRENT}/qc_before_trim/${line}*_R1_*_fastqc.zip \
        -d ${CURRENT}/qc_data
  mv ${CURRENT}/qc_data/${line}*_R1_*_fastqc/fastqc_data.txt \
     ${CURRENT}/qc_data/${line}_R1_before_trim_fastqc_data.txt
  rm -r ${CURRENT}/qc_data/${line}*_R1_*_fastqc/
  #
  unzip ${CURRENT}/qc_before_trim/${line}*_R2_*_fastqc.zip \
        -d ${CURRENT}/qc_data
  mv ${CURRENT}/qc_data/${line}*_R2_*_fastqc/fastqc_data.txt \
     ${CURRENT}/qc_data/${line}_R2_before_trim_fastqc_data.txt
  rm -r ${CURRENT}/qc_data/${line}*_R2_*_fastqc/
  #
  unzip ${CURRENT}/qc_after_trim/${line}*_R1_*_fastqc.zip \
        -d ${CURRENT}/qc_data
  mv ${CURRENT}/qc_data/${line}*_R1_*_fastqc/fastqc_data.txt \
     ${CURRENT}/qc_data/${line}_R1_after_trim_fastqc_data.txt
  rm -r ${CURRENT}/qc_data/${line}*_R1_*_fastqc/
  #
  unzip ${CURRENT}/qc_after_trim/${line}*_R2_*_fastqc.zip \
        -d ${CURRENT}/qc_data
  mv ${CURRENT}/qc_data/${line}*_R2_*_fastqc/fastqc_data.txt \
     ${CURRENT}/qc_data/${line}_R2_after_trim_fastqc_data.txt
  rm -r ${CURRENT}/qc_data/${line}*_R2_*_fastqc/

done < ${SN}

perl make_read_count_table.pl \
          ${CURRENT}/qc_data ${SN} \
          _R1_before_trim_fastqc_data.txt \
          ${CURRENT}/${OUT}_before_trim_R1.txt \
          ${MIN} ${MAX}
#
perl make_read_count_table.pl \
          ${CURRENT}/qc_data ${SN} \
          _R2_before_trim_fastqc_data.txt \
          ${CURRENT}/${OUT}_before_trim_R2.txt \
          ${MIN} ${MAX}
#
perl make_read_count_table.pl \
          ${CURRENT}/qc_data ${SN} \
          _R1_after_trim_fastqc_data.txt \
          ${CURRENT}/${OUT}_after_trim_R1.txt \
          ${MIN} ${MAX}
#
perl make_read_count_table.pl \
          ${CURRENT}/qc_data ${SN} \
          _R2_after_trim_fastqc_data.txt \
          ${CURRENT}/${OUT}_after_trim_R2.txt \
          ${MIN} ${MAX}
