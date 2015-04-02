#!/bin/bash

function print_help() {
   echo "Usage: runIostat.sh [device] [results_path (default ./results/)]"
   echo "  example: ./runIostat /dev/sda"
   echo "  example: ./runIostat /dev/sdb myResults"
   echo "  example: ./runIostat /dev/mapper/3487563847 ~/myResultsDir"
   echo "  example: ./runIostat /dev/sdb /root/somefolder/myResultsDir"
}


if [ -z $1 ]; then
   print_help
   exit 1
fi


ls -l $1 &>/dev/null; 
if [ $? -ne 0 ]; then 
   print_help
   exit 1
fi


device=$(echo $1 | cut -c6-)
#echo $device

d_results="results"
if [ ! -z $2 ]; then 
   d_results=$2
fi
f_output=$d_results"/f_output"
f_parsed=$d_results"/f_parsed"
f_read_iops=$d_results"/read_iops.txt"
f_write_iops=$d_results"/write_iops.txt"
f_read_bw=$d_results"/read_bw.txt"
f_write_bw=$d_results"/write_bw.txt"
f_read_lat=$d_results"/read_lat.txt"
f_write_lat=$d_results"/write_lat.txt"

function parse_output() {
   echo ""

   grep $device $f_output > $f_parsed
   #Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util
   #col 4  : read  iops
   #col 5  : write iops
   #col 6  : read  bw
   #col 7  : write bw
   #col 11 : read  latency
   #col 12 : write latency
   cat $f_parsed | awk '{print $4}'  | sed "s/,/./g" > $f_read_iops
   cat $f_parsed | awk '{print $5}'  | sed "s/,/./g" > $f_write_iops
   cat $f_parsed | awk '{print $6}'  | sed "s/,/./g" > $f_read_bw 
   cat $f_parsed | awk '{print $7}'  | sed "s/,/./g" > $f_write_bw
   cat $f_parsed | awk '{print $11}' | sed "s/,/./g" > $f_read_lat
   cat $f_parsed | awk '{print $12}' | sed "s/,/./g" > $f_write_lat
   echo "Statistics collected and stored in $d_results/"
   echo ""
}

trap parse_output SIGINT SIGTERM

mkdir -p $d_results
echo "Collecting statistics for $1..." 
#echo "commad: iostat -x 1 -c $device"
iostat -x 1 -c $device >&$f_output
