#!/bin/bash

FIX_DATE=`date +%Y%m%d_%H%M`

function escape_in_sed (){

        str="$1"
        str="${str//\[/\\[}"
        str="${str//\./\\.}"
        str="${str//\$/\\$}"
        str="${str//\*/\\*}"
#       str="${str//\\/\\\\}"
        str="${str//\^/\\^}"

        echo $str
}

function outputSepExp(){

	echo ''
	echo '-------------------------------------------------'
	echo ''
}

function showTsvInfo(){

	num_all=$(cat $1 | wc -l)

	echo '###################################################'

	echo "TSV name: $1" 
	echo "Total records: ${num_all}" 

	echo `outputSepExp`
	head $1
	echo `outputSepExp`
	echo -e '\n'

}

function generateCutPattern(){

num_row=`cat $1 | awk -F '\t' '{print NF}' | uniq`

#echo $num_row

file_pattern_cut=temp_random_cut.txt

rm -rf ${file_pattern_cut}

touch ${file_pattern_cut}
#echo '' > ${file_pattern_cut}

for i in $(seq 1 ${num_row});do

        echo $i >> ${file_pattern_cut}

        for j in $(seq 1 ${num_row});do

                if [ $i -lt $j ];then

                        echo $i,$j >> ${file_pattern_cut}

                        for k in $(seq 1 ${num_row});do

                                if [ $j -lt $k ];then

                                        echo $i,$j,$k >> ${file_pattern_cut}

                                fi
                        done
                fi
        done
done


cat ${file_pattern_cut} | awk '{print length() ,$0}' | sort -n | awk '{ print  $2 }' > random_cut.txt
rm -rf ${file_pattern_cut}

}

