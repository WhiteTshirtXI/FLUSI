#!/bin/bash

#-------------------------------------------------------------------------------
# FLUSI (FSI) unit test
# This file contains one specific unit test, and it is called by unittest.sh
#-------------------------------------------------------------------------------
# SPHERE unit test
# Tests the flow past a sphere at Reynolds number 100
#-------------------------------------------------------------------------------

params="./swimmer2_staggered/swimmer.ini"

happy=0
sad=0

# list of prefixes the test generates
prefixes=(ux uy uz p usx usy usz mask)
# list of possible times (no need to actually have them)
times=(000000 000250 000500 000750)
# run actual test
${mpi_command} ./flusi ${params}
echo "============================"
echo "run done, analyzing data now"
echo "============================"

# loop over all HDF5 files an generate keyvalues using flusi
for p in ${prefixes[@]}
do  
  for t in ${times[@]}
  do
    # *.h5 file coming out of the code
    file=${p}"_"${t}".h5"
    # will be transformed into this *.key file
    keyfile=${p}"_"${t}".key"
    # which we will compare to this *.ref file
    reffile=./swimmer2_staggered/${p}"_"${t}".ref" 
    
    if [ -f $file ]; then    
        # get four characteristic values describing the field
        ${mpi_serial} ./flusi --postprocess --keyvalues ${file}        
        # and compare them to the ones stored
        if [ -f $reffile ]; then        
            ${mpi_serial} ./flusi --postprocess --compare-keys $keyfile $reffile 
            result=$?
            if [ $result == "0" ]; then
              echo -e ":) Happy, this looks okay! " $keyfile $reffile 
              happy=$((happy+1))
            else
              echo -e ":[ Sad, this is failed! " $keyfile $reffile 
              sad=$((sad+1))
            fi
        else
            sad=$((sad+1))
            echo -e ":[ Sad: Reference file not found"
        fi
    else
        sad=$((sad+1))
        echo -e ":[ Sad: output file not found"
    fi
    echo " "
    echo " "
    
  done
done


#-------------------------------------------------------------------------------
#                               time series
#-------------------------------------------------------------------------------

files=(beam_data1.t forces.t)
for file in ${files[@]}
do
  echo comparing $file time series...
  
  ${mpi_serial} ./flusi --postprocess --compare-timeseries $file swimmer2_staggered/$file
  
  result=$?
  if [ $result == "0" ]; then
    echo -e ":) Happy, time series: this looks okay! " $file
    happy=$((happy+1))
  else
    echo -e ":[ Sad, time series: this is failed! " $file
    sad=$((sad+1))
  fi
done




echo -e "\thappy tests: \t" $happy 
echo -e "\tsad tests: \t" $sad




#-------------------------------------------------------------------------------
#                               RETURN
#-------------------------------------------------------------------------------
if [ $sad == 0 ] 
then
  exit 0
else
  exit 999
fi
