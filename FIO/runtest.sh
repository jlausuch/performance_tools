#!/bin/bash

test=""
if [ "$1" == "1" ]; then test="reference";
elif [ "$1" == "2" ]; then test="reallife";
elif [ "$1" == "3" ]; then test="writeintensive";
elif [ "$1" == "4" ]; then test="maxthroughput"; 
else 
   echo "Incorrect argument. Options are:"; 
   echo -e " 1:reference \n 2:reallife \n 3:writeintensive \n 4:maxthroughput"
   exit 1;
fi

echo ">> Running $test test....."

#Read parameteres from config file
while read -r line 
do 
   echo ${line}
   export ${line}
done< "parameters"

if [ ! -z $2 ] && [ "$2" -eq "$2" ] 2>/dev/null; then
  export RUNTIME=$2
fi


tail -n 4 ./$test.fio

command="fio ${test}.fio  > ${test}-results.log;"

echo -e "\n"$command

#RUN COMMAND
date1=$(date +"%s")

fio $test.fio  > $test-results.log;

date2=$(date +"%s")
diff=$(($date2-$date1))


#######################
# Calculate IOPS 
#######################
read_iops_array="$(cat $test-results.log | grep iops | grep read | awk '{print $5;}' | awk '{print substr($0,6)}' | awk 'gsub(",$","")')"
write_iops_array="$(cat $test-results.log | grep iops | grep write | awk '{print $4;}' | awk '{print substr($0,6)}' | awk 'gsub(",$","")')"
#we get an array, each value corresponds to a diferent thread, we have to sum them

read -a arr <<<$read_iops_array
read_iops=0
for var in "${arr[@]}"
do
   #read_iops=$(awk -vx=$read_iops -vy=$var 'BEGIN{ print x+y}')
   read_iops=$(( read_iops + $var ))
done
read -a arr <<<$write_iops_array
write_iops=0
for var in "${arr[@]}"
do
   #write_iops=$(awk -vx=$write_iops -vy=$var 'BEGIN{ print x+y}')
   write_iops=$(( write_iops + $var ))
done

#######################
# Calculate Throughput
#######################
read_th="$(cat $test-results.log  | grep aggrb | grep -i read | awk '{print $3;}' | awk '{print substr($0,7)}' | awk 'gsub(",$","")' | tr "\n" " ")"
write_th="$(cat $test-results.log  | grep aggrb | grep -i write | awk '{print $3;}' | awk '{print substr($0,7)}' | awk 'gsub(",$","")' | tr "\n" " ")"

if [ $read_iops -eq 0 ]; then 
   read_th=0
fi
if [ $write_iops -eq 0 ]; then  
   write_th=0
fi

read_th="$(echo $read_th |awk '{$1/=1024;printf "%.2f MB/s\n",$1}')"
write_th="$(echo $write_th |awk '{$1/=1024;printf "%.2f MB/s\n",$1}')"


#######################
# Calculate Latency
#######################
if [ $read_iops -eq 0 ]; then
   read_lats=0 
   write_lats="$(cat $test-results.log | grep -A 3 write | grep " lat" | awk '{print $5;}' | awk '{print substr($0,5)}' | awk 'gsub(",$","")')"
elif [ $write_iops -eq 0 ]; then
   read_lats="$(cat $test-results.log | grep -A 3 read | grep " lat" | awk '{print $5;}' | awk '{print substr($0,5)}' | awk 'gsub(",$","")')"
   write_lats=0
else
   read_lats="$(cat $test-results.log | grep -A 3 read | grep " lat" | awk '{print $5;}' | awk '{print substr($0,5)}' | awk 'gsub(",$","")')"
   write_lats="$(cat $test-results.log | grep -A 3 write | grep " lat" | awk '{print $5;}' | awk '{print substr($0,5)}' | awk 'gsub(",$","")')"
fi
#We have to calculate the average of the latencies of all the threads (they are not accummulative like throughput)
read -a arr <<<$read_lats
total=0.00
numElements=0
for var in "${arr[@]}"
do
   #echo $var
   total=$(awk -vx=$total -vy=$var 'BEGIN{ print x+y}')
   numElements=$((numElements+1))
done
rd_lat=$(awk -vx=$total -vy=$numElements 'BEGIN{ print x/1000/y}')


read -a arr <<<$write_lats
total=0.00
numElements=0
for var in "${arr[@]}"
do
#   echo $var
   total=$(awk -vx=$total -vy=$var 'BEGIN{ print x+y}')
   numElements=$((numElements+1))
done
wr_lat=$(awk -vx=$total -vy=$numElements 'BEGIN{ print x/1000/y}')


echo -e "\n===============================\nSummary:\n==============================="
echo "IOPS(read):        $read_iops"
echo "IOPS(write):       $write_iops"
echo "THROUGHPUT(read):  $read_th"
echo "THROUGHPUT(write): $write_th"
echo "LATENCY(read):     ${rd_lat} ms"
echo "LATENCY(write):    ${wr_lat} ms"
echo "$(($diff / 60)) minutes and $(($diff % 60)) seconds elapsed."
