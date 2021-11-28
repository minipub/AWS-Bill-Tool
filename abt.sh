#!/bin/bash
## Required: Bash 4.0+
## The results are always sorted by which is the first column except the service name
##    Service | 202109 | 202110 | Percent
## CloudWatch |  10000 |    900 |  +1011%
##        EC2 |     88 |   1000 |    -91%

. ./util.sh

if [ $# -eq 0 ] || [ `expr $# % 2` -ne 0 ]
then
	echo "Params not ok."
	echo "Usage: bash abt.sh [<month> <file> ...]"
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
	month_seq+=($month)
done
# echo ${month_file[@]}

## Display the Percent column when the number of months is exactly 2
show_percent=false
if [ ${#month_seq[@]} -ge 2 ];then
	show_percent=true
fi

srv_title=Service
pct_title=Percent

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

set_month_cnt () {
	declare -n mcnt_res=$1
	local items=$2
	item=(${items//;/ })
	for i in ${item[@]}
	do
		arr=(${i//,/ })
		month=${arr[0]}
		cnt=${arr[1]}
		mcnt_res[$month]=$cnt
	done
}

max_pct_len=0
declare -A srv_pct_res

get_max_pct_len () {
	local month_cnt
	declare -A month_cnt

	for srv in ${qty_desc[@]}
	do
		items=${srv_res[$srv]}
		set_month_cnt month_cnt $items
		# echo $srv
		# declare -p month_cnt

		first=${month_seq[0]}
		second=${month_seq[1]}
		if [ -z ${month_cnt[$first]} ] || [ -z ${month_cnt[$second]} ];then
			unset 'month_cnt[${first}]'
			unset 'month_cnt[${second}]'
			continue
		fi
		# TODO cannot calc numbers like 1.0e-05, 1.0e+05
		pct=$(bc <<< "scale=3; (${month_cnt[$first]}-${month_cnt[$second]})/${month_cnt[$second]}*100" 2>/dev/null)
		# echo $srv
		# echo "1st: " ${month_cnt[$first]} ", 2nd: " ${month_cnt[$second]} ", pct: " $pct
		unset 'month_cnt[${first}]'
		unset 'month_cnt[${second}]'
		if [ -z $pct ];then
			continue
		fi
		txt="${pct}%"
		# echo "txt:" $txt
		if [ $(bc <<< "$pct > 0") -eq 1 ];then
			txt="+${txt}"
		fi

		srv_pct_res[$srv]=$txt
		if [ ${#txt} -gt ${max_pct_len} ];then
			max_pct_len=${#txt}
		fi
	done
}

if $show_percent;then
	get_max_pct_len
fi

# echo "srv_res: ${srv_res[@]}"
# declare -p qty_desc

print_title () {
	if [ ${#srv_title} -gt $max_word_len ];then
		max_word_len=${#srv_title}
	fi

	printf " %${max_word_len}s " ${srv_title}

	for i in ${month_seq[@]}
	do
		local max_cnt_len=${max_cnt_res[$i]}
		printf "| %${max_cnt_len}s " $i
	done

	if $show_percent;then
		if [ ${#pct_title} -gt $max_pct_len ];then
			max_pct_len=${#pct_title}
		fi
		printf "| %${max_pct_len}s " Percent
	fi

	echo ""
}

print_title

print_line () {
	local srv=$1
	local items=$2

	local month_cnt
	declare -A month_cnt
	set_month_cnt month_cnt $items

	printf " %${max_word_len}s " $srv

	for i in ${month_seq[@]}
	do
		local max_cnt_len=${max_cnt_res[$i]}
		printf "| %${max_cnt_len}s " ${month_cnt[$i]}
	done

	if $show_percent;then
		printf "| %${max_pct_len}s " ${srv_pct_res[$srv]}
	fi

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
