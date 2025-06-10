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


