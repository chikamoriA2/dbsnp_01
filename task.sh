#!/bin/sh

source ./util.sh

refsnp_root=/_ref/ftp.ncbi.nih.gov/snp
refsnp=refsnp-chrY

refsnp_json=${refsnp}.json
refsnp_bz=${refsnp}.json.bz2

dir_fm_pri=fm_pri_${refsnp}
dir_fm_sec=fm_sec_${refsnp}

dir_log=log

mkdir ${dir_fm_pri} -p
mkdir ${dir_fm_sec} -p
mkdir ${dir_log} -p

mkdir ${dir_fm_sec}/${FIX_DATE} 

file_parallel=parallel.bash

file_sh_log=${dir_log}/01_sh_${refsnp}_${FIX_DATE}.log
file_report_log=${dir_log}/02_report_${refsnp}_${FIX_DATE}.log

touch $file_parallel
touch $file_sh_log
touch $file_report_log

num_json=$(ls ${dir_fm_pri}/*.json-* | wc -l)

if [ ${num_json} = 0  ]; then

	bzcat ${refsnp_root}/${refsnp_bz} | pv | split -l 100000 -d -a 4 - ${dir_fm_pri}/${refsnp_json}-
	echo 'Unzip a bz2 file completed.'

else

	echo 'Already unzipped files existing.'

fi

echo '###################################################' >> ${file_report_log}
echo 'The number of Primary records is ['$(cat ${dir_fm_pri}/* | wc -l)'].' >> ${file_report_log}

jq_01='.primary_snapshot_data.placements_with_allele[] as $pwa
       	| $pwa.alleles[] as $lls
       	| {
		a:.refsnp_id,
		b: $pwa.is_ptlp,
		d: $lls.allele.spdi.deleted_sequence,
		e: $lls.allele.spdi.inserted_sequence,
		f: $lls.hgvs,
		g: $lls.hgvs[-3:]
	}
	| select(.b == true)
       	| select(.f | contains(">"))'

jq_02='[.a, .d, .e, .g] | @tsv'

jq_01=$(escape_in_sed "$jq_01")
jq_02=$(escape_in_sed "$jq_02")

sed_01="s!(.*)!cat ${dir_fm_pri}\/\1 | jq '${jq_01}' | jq -r '${jq_02}' > ${dir_fm_sec}\/\1_sec.tsv!g"

echo 'Begin parallel jq....'

ls ${dir_fm_pri} | sed -r "${sed_01}" > ${file_parallel}
#ls ${dir_fm_pri} | sed -r "${sed_01}" | parallel
parallel < ${file_parallel}

cat ${file_parallel} >> ${file_sh_log}
# find ${dir_fm_pri}/* | sed -r "${sed_01}" | parallel
echo 'Finish parallel jq....'

cat ${dir_fm_sec}/*_sec.tsv > ${dir_fm_sec}/${refsnp}.sec.01.tsv.unsorted

rm -rf ${dir_fm_sec}/*_sec.tsv

file_all_tsv=${dir_fm_sec}/${FIX_DATE}/${refsnp}.sec.01.${FIX_DATE}.tsv

sort -k 1 -t \t ${dir_fm_sec}/${refsnp}.sec.01.tsv.unsorted | uniq > ${file_all_tsv}

#num_all=$(cat ${file_all_tsv} | wc -l)

#echo "TSV name: ${file_all_tsv}" >> ${file_report_log}
#echo "Total records: ${num_all}" >> ${file_report_log}
#echo ''

#showTsvInfo ${file_all_tsv} >> ${file_report_log}
#head ${file_all_tsv} >> ${file_report_log}

generateCutPattern ${file_all_tsv}

sed_02="s!(.*)!cut -f\1 ${file_all_tsv} | sort | uniq > ${file_all_tsv}.\1!g"

#cat temp_random_cut.txt | sed -r "${sed_02}" > ${file_parallel}
cat random_cut.txt | sed -r "${sed_02}" | awk -F "|" '{OFS="|"; gsub(/,/, "-", $3); print $0}' > ${file_parallel}
# cat ${file_parallel} | awk -F "|" '{OFS="|"; gsub(/,/, "-", $3); print $0}' > ${file_parallel}
#'s!(.*)!cut -f\1 fm_sec_refsnp-chrY\/refsnp-chrY.sec.01.20250610_1408.tsv | sort | uniq > fm_sec_refsnp-chrY\/refsnp-chrY.sec.01.20250610_1408.tsv.\1!g'

echo 'Begin parallel sorting....'
parallel < ${file_parallel}
#sh < ${file_parallel}
echo 'Finish parallel sorting....'

cat ${file_parallel} >> ${file_sh_log}

# -------------------------------------------------------

echo '###################################################' >> ${file_report_log}

wc -l ${dir_fm_sec}/${FIX_DATE}/* >> ${file_report_log}

find ${dir_fm_sec}/${FIX_DATE}/* | sed -r "s!(.*)!source ./util.sh; showTsvInfo \1 >> ${file_report_log}!g" > ${file_parallel}

echo 'Begin parallel recording tsv info....'
sh < ${file_parallel}
echo 'Finish parallel recording tsv info....'
cat ${file_parallel} >> ${file_sh_log}


rm -rf ${dir_fm_sec}/${refsnp}.sec.01.tsv.unsorted
rm -rf ${file_parallel}


