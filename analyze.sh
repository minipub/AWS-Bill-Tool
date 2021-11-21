#!/bin/bash
## Need Bash 4.0+
##    SERVICE | 202109 | 202110  
## CloudWatch |  10000 |   1000  
##        EC2 |     88 |   1000 

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
	echo "month: ${month}"
	file=${params[$((i+1))]}
	echo "file: ${file}"
	month_file[$month]=$file
	month_seq[$i]=$month
done
# echo ${month_file[@]}

srv_title=SERVICE
# last_month=202109
# now_month=202110

max_word_len=0

read_file () {
	local month=$1
	local file=$2
	declare -n sres=$3
	declare -n mcres=$4
	while read line
	do
		# echo $line  
		noblank_line=${line// /}
		arr=(${noblank_line//,/ })
		srv=${arr[0]}
		# echo $srv
		if [ ${#srv} -gt $max_word_len ]
		then
			max_word_len=${#srv}
		fi
		cnt=${arr[1]}
		if [ ${#cnt} -gt ${mcres[$month]} ]
		then
			mcres[$month]=${#cnt}
		fi
		# sres[$srv,$month]=$cnt
		sres[$srv]+="${month},${cnt};"
	done < <(cat $file | tail +2 | awk -F"," '{a[$3]+=$NF}END{for(i in a){printf "%s,%.10g\n", i, a[i]}}' | sort -t"," -k2,2nr)
}

declare -A srv_res
declare -A max_cnt_res
for i in ${!month_file[@]}
do
	month=$i
	file=${month_file[$i]}
	max_cnt_res[$month]=${#month}
	read_file $month $file srv_res max_cnt_res
done

# echo "srv_res: ${srv_res[@]}"

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
	for srv in ${!srv_res[@]}
	do
		items=${srv_res[$srv]}
		print_line $srv $items 
	done
}

print_lines

########
# for i in ${!r1[@]}
# do	
# 	printf "$format" $i ${r1[$i]} ${r2[$i]}
# 	unset 'r2[${i}]'
# done

# for j in ${!r2[@]}
# do
# 	printf "$format" $j "" ${r2[$j]}
# done
########
