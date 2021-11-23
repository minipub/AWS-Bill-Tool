#!/bin/bash

insert_array () {
	local ele=$1
	local -n arr=$2
	local pos=$3

	if [ $pos -lt 0 ];then
		return
	fi

	before_cnt=${#arr[@]}
	if [ $pos -gt $before_cnt ];then
		pos=$before_cnt
	fi

	arr+=(${ele})
	after_cnt=${#arr[@]}
	if [ $pos -eq $after_cnt ];then
		return
	fi

	for ((i=$after_cnt-1; i>${pos}; i-=1))
	do
		tmp=${arr[$i]}
		arr[$i]=${arr[$i-1]}
		arr[$i-1]=$tmp
	done
}

# brr=()
# insert_array e brr 0
# declare -p brr
