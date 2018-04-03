#!/bin/bash


FOLDER_NAME=$1
SUM=0
COUNT=0
grep "[A-Za-z ]*MB/s)" $FOLDER_NAME/*.input.out | while read -r line ; do
	#echo "Processing $line"
	IFS=' ' read -r -a array <<< "$line"
	ARRAY_COUNT=${#array[@]}
	CUR_BAND=${array[ARRAY_COUNT-2]:1}
	COUNT=$((COUNT+1))
	SUM=$(echo "$SUM+$CUR_BAND" | bc)
	echo "COUNT=$COUNT, SUM=$SUM"
done
