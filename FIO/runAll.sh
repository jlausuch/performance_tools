#!/bin/bash


date1=$(date +"%s")
for i in {1,2,3,4}; do
   echo "-------------------------------------------------------------"
   ./runtest.sh $i $1
done

date2=$(date +"%s")
diff=$(($date2-$date1))
echo -e "-------------------------------------------------------------\n$(($diff / 60)) minutes and $(($diff % 60)) seconds elapsed in TOTAL."
