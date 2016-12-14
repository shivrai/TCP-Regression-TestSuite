#!/bin/sh
#
##################################################
# Automation script for running tests            #
# A default tolerance value of 1 second is used. #
##################################################

# This variable has to be updated to point to the location of packetdrill binary.
packetdrill=/usr/home/zeebsd/packetdrill/gtests/net/packetdrill/packetdrill
directory="$1"
extension=".pkt"

file=tests_list      # contains the list of ".pkt" files in case the argument is empty or a directory
pkt_file_flag=0   # tracks whether the argument is a ".pkt" file

# Check if path to packetdrill binary is set
if [ -z "$packetdrill" ]
then
  printf "Please set the value of \$packetdrill variable to the path of packetdrill binary on your machine.\n"
  exit
fi

if [ ! -e $file ]
then
  `find . -type f -iname '*.pkt' | cut -f 2 -d '.' > tests_list`
fi

# Check if the argument is a ".pkt" file
if test "${directory#*$extension}" != "$directory"
then
  pkt_file_flag=1
fi

# Check if the argument is a directory
if [ ! -z "$directory" ] && [ $pkt_file_flag == 0 ]
then
  `find ./$directory -type f -iname '*.pkt' | cut -f 2 -d '.' > temp_list`
  file=temp_list
fi

delay=0.2
run=0
skipped=0
passed=0
failed=0

# Modify values depending on return status
check_status() {
  run=`expr $run + 1`
  if [ $result = 1 ]
  then
    `printf "Test Name: ${test}\.pkt\n" >> error.log`
    `printf "\---------------------------------------------------------\n" >> error.log`
    `cat temp.log >> error.log`
    `printf "\n" >> error.log`
    echo -e "\e[0;31mFAILED\e[0m"
    printf "\--------------------------------------------------------------\n"
    failed=`expr $failed + 1`
    # set -- "$@" $test
  else
    echo -e "\e[1;32mPASSED\e[0m"
    printf "\---------------------------------------------------------------\n"
    passed=`expr $passed + 1`
  fi
}

`rm -f error.log`
printf "\nScript Name                                             Result\n"
printf "===============================================================\n"

# Check if a single test script or a directory is given as argument
if [ $pkt_file_flag == 1 ]
then
  printf "%-55.55s " $directory
  if [ -e $directory ]
  then
    `rm -f temp.log`
    `$packetdrill -v --tolerance_usecs=1000000 $directory >> temp.log 2>&1`
    result="`echo $?`"
    check_status
  else
    echo -e "\e[1;33mSKIPPED\e[0m"
    skipped=`expr $skipped + 1`
  fi

else
  while IFS= read test
  do
    printf "%-55.55s " .$test
    `sleep $delay`
    if [ -e .${test}.pkt ]
    then
      `rm -f temp.log`
      `$packetdrill -v --tolerance_usecs=1000000 .${test}.pkt >> temp.log 2>&1`
      result="`echo $?`"
      check_status
    else
      printf "%-55.55s " .$test
      echo -e "\e[1;33mSKIPPED\e[0m"
      skipped=`expr $skipped + 1`
    fi
  done< "$file"
  `rm -f temp.log`
  `rm -f temp_list`
fi

printf "\nSummary\n"
printf "===========================\n"

printf "Number of tests run: %6d\n" $run
printf "Number of tests passed: %3d\n" $passed
printf "Number of tests failed: %3d\n" $failed
printf "Number of tests skipped: %2d\n" $skipped
if [ $failed -ne 0 ]
then
  printf "\nView the log file (error.log) for details\n"
fi

# printf "\nList of failed tests\n"
# printf "===========================\n"
# printf '%s\n' "$@"
