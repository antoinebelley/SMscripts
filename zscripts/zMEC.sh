#!/bin/bash
## this script will combine GamowTeller TBMEs (from IMSRG) with GTMEC TBMEs (from IMSRG)
## ie) <ab| GTFULL | cd > = <ab| GamowTeller |cd> + fact*<ab| GTMEC |cd>
## by: Charlie Payne
## last updated: Spring 2018
GTfile=${1}     # the operator file for the pure GT, calling the 1b or the 2b is fine
MECfile=${2}    # " " " " " GTMEC, " " " " " " " "
extra=${3}      # just an extra string to tac on to the name of the output files, may be left blank
fact=-3.419935006159658  # some kind of conversion factor to multiply by the GTMEC TBMEs
precision=9              # the bc decimal precision


# parse the input
GTfile=${GTfile%_1b.op}
GTfile=${GTfile%_2b.op}
MECfile=${MECfile%_1b.op}
MECfile=${MECfile%_2b.op}
basename=${MECfile%_GTMEC}


# pre-check
GTtail=$(echo -n $GTfile | tail -c 11)
if [ $GTtail != 'GamowTeller' ]
then
  echo 'ERROR: are you sure you have the GamowTeller operator as your first argument?'
  echo "GTfile = $GTfile"
  echo "GTtail = $GTtail"
  echo 'exiting...'
  exit 1
fi
MECtail=$(echo -n $MECfile | tail -c 5)
if [ $MECtail != 'GTMEC' ]
then
  echo 'ERROR: are you sure you have the GTMEC operator as your second argument?'
  echo "MECfile = $MECfile"
  echo "MECtail = $MECtail"
  echo 'exiting...'
  exit 1
fi


# function prototype: this function will get the lnum-th line of a file
getline(){
  local lnum=${1}
  local myfile=${2}
  local line=$(sed -n "${lnum}p" $myfile)
  echo $line
}

# function prototype: this function will get the place-th of a space separated string (aka: vector)
# make sure to put double qoutes around "vector", place counting starts from 0 (not 1)
getp(){
  local vector=${1}
  local place=${2}
  for ((p=0; p<$place; p++))
  do
    vector=$(echo $vector | sed 's/[^ ]* //') # remove everything before the current first space
  done
  vector=$(echo $vector | sed 's/\s.*$//') # remove everything after the current first space
  echo $vector
}

# function prototype: this function will take a number like .012348 and write it as 0.012348, because I ain't no tool!
append0(){
  local value=${1}
  if [ ${value:0:1} = '.' ]
  then
    value=$(echo $value | sed -e 's/./0./')
  elif [ ${value:0:2} = '-.' ]
  then
    value=$(echo $value | sed -e 's/-./-0./')
  fi
  echo $value
}


# do out the starting stuff
GT1bfile=${GTfile}_1b.op
GT2bfile=${GTfile}_2b.op
MEC1bfile=${MECfile}_1b.op
MEC2bfile=${MECfile}_2b.op
FULL1bfile=${basename}_GTFULL # this will contain the result (1b)
FULL2bfile=${basename}_GTFULL # " " " " " (2b)
if [ ! -z $extra ]
then
  FULL1bfile=${FULL1bfile}_${extra}
  FULL2bfile=${FULL2bfile}_${extra}
fi
FULL1bfile=${FULL1bfile}_1b.op
FULL2bfile=${FULL2bfile}_2b.op
rm -f $FULL1bfile $FULL2bfile # just in case they already exist...

findline="!  a"
GT1blnum=$(awk "/$findline/{ print NR; exit }" $GT1bfile)   # find the line number where $findline appears
GT2blnum=$(awk "/$findline/{ print NR; exit }" $GT2bfile)   # " " " " " "
MEC1blnum=$(awk "/$findline/{ print NR; exit }" $MEC1bfile) # " " " " " "
MEC2blnum=$(awk "/$findline/{ print NR; exit }" $MEC2bfile) # " " " " " "
GT1bmax=$(wc -l $GT1bfile)
GT1bmax=${GT1bmax%$GT1bfile} # get the last line number
GT2bmax=$(wc -l $GT2bfile)
GT2bmax=${GT2bmax%$GT2bfile} # " " " " "
MEC1bmax=$(wc -l $MEC1bfile)
MEC1bmax=${MEC1bmax%$MEC1bfile} # " " " " "
MEC2bmax=$(wc -l $MEC2bfile)
MEC2bmax=${MEC2bmax%$MEC2bfile} # " " " " "
if [ $GT1blnum -ne $MEC1blnum ] || [ $GT1blnum -ne $MEC1blnum ] || [ $GT1bmax -ne $MEC1bmax ] || [ $GT2bmax -ne $MEC2bmax ]
then
  echo 'ERROR: the line numbers are NOT matching!?'
  echo "GT1blnum  = $GT1blnum"
  echo "MEC1blnum = $MEC1blnum"
  echo "GT2blnum  = $GT2blnum"
  echo "MEC2blnum = $MEC2blnum"
  echo "GT1bmax   = $GT1bmax"
  echo "MEC1bmax  = $MEC1bmax"
  echo "GT2bmax   = $GT2bmax"
  echo "MEC2bmax  = $MEC2bmax"
  echo 'exiting...'
  exit 1
fi
head -$MEC1blnum $MEC1bfile >> $FULL1bfile # copy the form of the 1b file for the first $MEC1blnum lines
sed -i "1s/MEC/FULL/" $FULL1bfile # change the name in the first line of the file
head -$MEC2blnum $MEC2bfile >> $FULL2bfile # copy the form of the 2b file for the first $MEC2blnum lines
sed -i "1s/MEC/FULL/" $FULL2bfile # change the name in the first line of the file

lnum1b=$((MEC1blnum+1))
lnum2b=$((MEC2blnum+1))
max1b=$MEC1bmax
max2b=$MEC2bmax

# in this loop, we combine the TBMEs from GT and MEC to make FULL
# NOTE: setting and unsetting the "IFS" is just to tell bash how to handle spaces appropriately
for ((i=$lnum1b; i<=$max1b; i++))
do
  IFS='%'
  GT1bline=$(getline $i $GT1bfile)
  MEC1bline=$(getline $i $MEC1bfile)
  unset IFS
  GT1bA=$(getp "$GT1bline" '0')
  GT1bB=$(getp "$GT1bline" '1')
  GT1bval=$(getp "$GT1bline" '2')
  MEC1bA=$(getp "$MEC1bline" '0')
  MEC1bB=$(getp "$MEC1bline" '1')
  MEC1bval=$(getp "$MEC1bline" '2')
  if [ $GT1bA != $MEC1bA ] || [ $GT1bB != $MEC1bB ]
  then
    echo 'ERROR: the particle labels for the 1b operators are not matching!'
    echo "line = $i"
    echo "GT1bA = $GT1bA"
    echo "GT1bB = $GT1bB"
    echo "MEC1bA = $MEC1bA"
    echo "MEC1bB = $MEC1bB"
    echo "you should compare $GT1bfile and $MEC1bfile, and delete $FULL1bfile"
    echo 'exiting...'
    exit 1
  fi
  IFS='%'
  FULL1bval=$(bc <<< "scale=${precision}; ${GT1bval} + ${fact}*${MEC1bval}")
  FULL1bval=$(bc <<< "scale=${precision}; ${FULL1bval}/1")
  FULL1bval=$(append0 $FULL1bval)
  FULL1bline=${MEC1bline%$MEC1bval}
  echo "${FULL1bline}${FULL1bval}" >> $FULL1bfile
  unset IFS
done

# same as the above loop, for for the 2b file
for ((i=$lnum2b; i<=$max2b; i++))
do
  IFS='%'
  GT2bline=$(getline $i $GT2bfile)
  MEC2bline=$(getline $i $MEC2bfile)
  unset IFS
  GT2bA=$(getp "$GT2bline" '0')
  GT2bB=$(getp "$GT2bline" '1')
  GT2bC=$(getp "$GT2bline" '2')
  GT2bD=$(getp "$GT2bline" '3')
  GT2bJAB=$(getp "$GT2bline" '4')
  GT2bJCD=$(getp "$GT2bline" '5')
  GT2bval=$(getp "$GT2bline" '6')
  MEC2bA=$(getp "$MEC2bline" '0')
  MEC2bB=$(getp "$MEC2bline" '1')
  MEC2bC=$(getp "$MEC2bline" '2')
  MEC2bD=$(getp "$MEC2bline" '3')
  MEC2bJAB=$(getp "$MEC2bline" '4')
  MEC2bJCD=$(getp "$MEC2bline" '5')
  MEC2bval=$(getp "$MEC2bline" '6')
  if [ $GT2bA != $MEC2bA ] || [ $GT2bB != $MEC2bB ] || [ $GT2bC != $MEC2bC ] || [ $GT2bD != $MEC2bD ] \
      || [ $GT2bJAB != $MEC2bJAB ] || [ $GT2bJCD != $MEC2bJCD ]
  then
    echo 'ERROR: the particle labels and/or angular momentum for the 2b operators are not matching!'
    echo "line = $i"
    echo "GT2bA = $GT2bA"
    echo "GT2bB = $GT2bB"
    echo "GT2bC = $GT2bC"
    echo "GT2bD = $GT2bD"
    echo "GT2bJAB = $GT2bJAB"
    echo "GT2bJCD = $GT2bJCD"
    echo "MEC2bA = $MEC2bA"
    echo "MEC2bB = $MEC2bB"
    echo "MEC2bC = $MEC2bC"
    echo "MEC2bD = $MEC2bD"
    echo "MEC2bJAB = $MECJAB"
    echo "MEC2bJCD = $MECJCD"
    echo "you should compare $GT2bfile and $MEC2bfile, and delete $FULL2bfile"
    echo 'exiting...'
    exit 1
  fi
  IFS='%'
  FULL2bval=$(bc <<< "scale=${precision}; ${GT2bval} + ${fact}*${MEC2bval}")
  FULL2bval=$(bc <<< "scale=${precision}; ${FULL2bval}/1")
  FULL2bval=$(append0 $FULL2bval)
  FULL2bline=${MEC2bline%$MEC2bval}
  echo "${FULL2bline}${FULL2bval}" >> $FULL2bfile
  unset IFS
done


## FIN
