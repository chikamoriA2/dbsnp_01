#!/bin/sh

source ./util.sh

refsnp_root=/_ref/ftp.ncbi.nih.gov/snp
refsnp=refsnp-chrY

refsnp_json=${refsnp}.json
refsnp_bz=${refsnp}.json.bz2

dir_fm_pri=fm_pri_${refsnp}
dir_fm_sec=fm_sec_${refsnp}

mkdir ${dir_fm_pri} -p
mkdir ${dir_fm_sec} -p

file_log=log_${refsnp}
touch $file_log

num_json=$(ls ${dir_fm_pri}/*.json-* | wc -l)

if [ ${num_json} = 0  ]; then

	bzcat ${refsnp_root}/${refsnp_bz} | pv | split -l 100000 -d -a 4 - ${dir_fm_pri}/${refsnp_json}-
	echo 'Unzip a bz2 file completed.'

else

	echo 'Already unzipped files existing.'

fi



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

echo 'Begin parallel process....'
ls ${dir_fm_pri} | sed -r "${sed_01}" | parallel
# find ${dir_fm_pri}/* | sed -r "${sed_01}" | parallel
echo 'Finish parallel process....'

cat ${dir_fm_sec}/*_sec.tsv > ${dir_fm_sec}/${refsnp}.sec.01.tsv.unsorted

rm -rf ${dir_fm_sec}/*_sec.tsv

sort -k 1 -t \t ${dir_fm_sec}/${refsnp}.sec.01.tsv.unsorted > ${dir_fm_sec}/${refsnp}.sec.01.${FIX_DATE}.tsv

rm -rf ${dir_fm_sec}/${refsnp}.sec.01.tsv.unsorted

