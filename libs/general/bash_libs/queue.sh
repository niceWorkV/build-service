#! /usr/bin/bash

lockFileName=".lock"

isRepoLocked () {
  repo=$1
  if [[ -f "${repo}/${lockFileName}" ]]; then
      return 0  
    else
      return 1
  fi
}

setLock () {
  repo=$1
  isRepoLocked $repo
  isLocked=$?
  if [[ -d $repo && $isLocked -eq 1 ]];
    then
      touch  "${repo}/${lockFileName}"
  fi
}

removeLock () {
  repo=$1
  isRepoLocked $repo
  isLocked=$?
  if [[ $isLocked -eq 0 ]];
  then
    rm -f "${repo}/${lockFileName}"
  fi
}
