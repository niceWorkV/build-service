#! /usr/bin/bash

set -x  

log_dir="${result_dir}/logs/"

if [[ ! -d $log_dir ]];
  then
    mkdir $log_dir
fi

log_file="${log_dir}/init.log"

if [[ -f $log_file ]];
  then
    rm $log_file
fi

exec >> $log_file
exec 2>&1

source /home/libs/bash_libs/queue.sh

setLock $rpm_sources

my_exit () {
  ec=$1

  exit $ec
}

if [[ -z `ls -1 $host_sources` ]]; then
  my_exit 1
fi

while read dir :
do
  if [[ ! -d $dir ]];
    then
      echo "$dir is not directory"
      my_exit 1
  fi
done <<< $(ls -1 $host_sources)

rsync -aHv "${host_sources}/" "${source_dir}/"

removeLock $rpm_sources
