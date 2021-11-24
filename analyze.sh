#!/bin/bash
## Required: Bash 4.0+
## The results are always sorted by which is the first column except the service name
##    SERVICE | 202109 | 202110  
## CloudWatch |  10000 |    900  
##        EC2 |     88 |   1000 

. ./util.sh

if [ $# -eq 0 ] || [ `expr $# % 2` -ne 0 ]
then
	echo "Params not ok."
	echo "Usage: bash analyze.sh [<month> <file> ...]"
	exit 1
fi

declare -A month_file
params=("$@")
for ((i=0; i<=$#-1; i+=2))
do
	month=${params[$i]}
	file=${params[$((i+1))]}
	# echo "month: ${month} file: ${file}"
	month_file[$month]=$file
	month_seq[$i]=$month
done
# echo ${month_file[@]}

srv_title=SERVICE

max_word_len=0

declare -a qty_desc

read_file () {
	local month=$1
	local file=$2
	declare -n sres=$3
	declare -n mcres=$4
	local j=0
	while read line
	do
		# echo $line  
		noblank_line=${line// /}
		arr=(${noblank_line//,/ })
		srv=${arr[0]}
		# echo $srv
		if [ ${#srv} -gt $max_word_len ];then
			max_word_len=${#srv}
		fi
		cnt=${arr[1]}
		if [ ${#cnt} -gt ${mcres[$month]} ];then
			mcres[$month]=${#cnt}
		fi
		# sres[$srv,$month]=$cnt
		if [ -z ${sres[$srv]} ];then
			# echo "------ $srv $j"
			# declare -p qty_desc
			insert_array $srv qty_desc $j
		fi
		j=$(($j+1))
		sres[$srv]+="${month},${cnt};"
	done < <(cat $file | tail +2 | awk -F"," '{a[$3]+=$NF}END{for(i in a){printf "%s,%.10g\n", i, a[i]}}' | sort -t"," -k2,2nr)
}

declare -A srv_res
declare -A max_cnt_res
for month in ${month_seq[@]}
do
	file=${month_file[$month]}
	max_cnt_res[$month]=${#month}
	read_file $month $file srv_res max_cnt_res
done

# echo "srv_res: ${srv_res[@]}"
# declare -p qty_desc

print_title () {
	if [ ${#srv_title} -gt $max_word_len ]
	then
		max_word_len=${#srv_title}
	fi

	printf " %${max_word_len}s " ${srv_title}

	for i in ${month_seq[@]}
	do
		local max_cnt_len=${max_cnt_res[$i]}
		printf "| %${max_cnt_len}s " $i
	done

	echo ""
}

print_title

print_line () {
	local srv=$1
	local items=$2

	declare -A month_cnt
	item=(${items//;/ })
	for i in ${item[@]}
	do
		arr=(${i//,/ })
		month=${arr[0]}
		cnt=${arr[1]}
		month_cnt[$month]=$cnt
	done

	printf " %${max_word_len}s " $srv

	for i in ${month_seq[@]}
	do
		local max_cnt_len=${max_cnt_res[$i]}
		printf "| %${max_cnt_len}s " ${month_cnt[$i]}
	done

	echo ""
}

print_lines () {
	for srv in ${qty_desc[@]}
	do
		items=${srv_res[$srv]}
		print_line $srv $items 
	done
}

print_lines
