#!/bin/sh

#cat test.json | jq \
bzcat $1 | jq \
	'.primary_snapshot_data.placements_with_allele[] as $pwa
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
       	| select(.f | contains(">"))'\
	| jq -r '[.a, .d, .e, .g] | @tsv' > $1_result.tsv
#	| jq -r '[.a, .d, .e, .g] | @tsv' > result.tsv


