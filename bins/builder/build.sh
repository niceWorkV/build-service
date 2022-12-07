#! /usr/bin/bash

set -x

source /home/libs/bash_libs/queue.sh

build_dir="${HOME}/rpmbuild"
mock_conf="${conf_dir}/build_env"


myexit () {
  removeLock $rpm_sources
  exit $1
}

while :
do
  isRepoLocked $rpm_sources
  isLocked=$?
  if [[ $isLocked -eq 0 ]]; 
    then
      sleep 2s
    else
      setLock $rpm_sources
      break
  fi
done

rpm=`ls -1 ${rpm_sources} | head -n 1`

if [[ -z $rpm ]];
  then 
    myexit 1
fi

log_dir="${result_dir}/logs/"
log_file="${rpm}.log"

#check whethe we built this RPM before
if [[ -f "${log_dir}/$log_file" ]];
  then
    rm -rf "$rpm_sources/${rpm}"
fi

exec >> "${log_dir}/${log_file}"
exec 2>&1

find "${rpm_sources}/${rpm}" -name '*.spec' -not -path '*/.*' -exec mv {} "${build_dir}/SPECS/" \;
rsync -r --remove-source-files "${rpm_sources}/${rpm}/" "${build_dir}/SOURCES/"
rmdir "${rpm_sources}/${rpm}"

removeLock $rpm_sources

spec_file="${build_dir}/SPECS/${rpm}.spec"

yum-builddep -y $spec_file
rpmbuild -ba $spec_file

if [[ $? -ne 0 ]];
  then
     exit 0
fi

find "${build_dir}/RPMS" -name '*.rpm' -exec mv {} "${result_dir}/" \;

if [[ ! $(ls $rpm_sources) ]]; 
  then
    exit 0
fi

exit 210
