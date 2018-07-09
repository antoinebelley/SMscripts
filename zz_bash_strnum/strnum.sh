#!/bin/bash
# by: Charlie Payne
# copyright (c): 2016-2018
# files that use these: $IMASMS/sumM2nu.sh, $IMASMS/zscripts/zMEC.sh, $IMAMYR/zcompilerresults.sh

myl=${1}
myp=${2}
precision=12 # DONT FORGET THIS

################################################################################

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

# function prototype: this function will undo a number from being in base e or E notation
# make sure that $precision is set somewhere above this prototype
bcE(){
  local value=${1}
  local check1=${value:0:1}
  local check2=${value:0:2}
  if [ $check1 = 'e' ] || [ $check1 = 'E' ]
  then
    value="1${value}"
  elif [ $check2 = '-e' ] || [ $check2 = '-E' ]
  then
    value=${value#-}
    value="-1${value}"
  fi
  local eval=${value#*[eE]}
  local epm=${eval:0:1}
  if [ $epm = '-' ]
  then
    value=$(echo ${value} | sed -e 's/[eE]-*/\/10\^/')
  elif [ $epm = '+' ]
  then
    value=$(echo ${value} | sed -e 's/[eE]+*/\*10\^/')
  elif [ "$eval" = "$value" ]
  then
    : # the value must not be in base e or E notation, derp...
  else
    echo "ERROR: value = $value has problems..."
  fi
  value=$(bc <<< "scale=${precision}; $value")
  echo $value
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

# function prototype: this function will take an absolute value of a number
absval(){
  local value=${1}
  local prefix=$(echo ${value:0:1})
  if [ $prefix = '-' ]
  then
    value=$(echo ${value#$prefix})
  fi
  echo $value
}

################################################################################

echo "myl = $myl"
myline=$(getline $myl 'test.txt')
echo "myline = $myline"
echo "myp = $myp"
myval=$(getp "$myline" $myp)
echo "myval = $myval"
echo "~~~~~~~~~~~ bc a0 av ~~~~~~~~~~~"
myval1=$(bcE $myval)
echo "bcE: $myval1"
myval1=$(append0 $myval1)
echo "append0: $myval1"
myval1=$(absval $myval1)
echo "absval: $myval1"
echo "~~~~~~~~~~~ bc av a0 ~~~~~~~~~~~"
myval2=$(bcE $myval)
echo "bcE: $myval2"
myval2=$(absval $myval2)
echo "absval: $myval2"
myval2=$(append0 $myval2)
echo "append0: $myval2"
echo "~~~~~~~~~~~ a0 bc av ~~~~~~~~~~~"
myval3=$(append0 $myval)
echo "append0: $myval3"
myval3=$(bcE $myval3)
echo "bcE: $myval3"
myval3=$(absval $myval3)
echo "absval: $myval3"
echo "~~~~~~~~~~~ a0 av bc ~~~~~~~~~~~"
myval4=$(append0 $myval)
echo "append0: $myval4"
myval4=$(bcE $myval4)
echo "bcE: $myval4"
myval4=$(absval $myval4)
echo "absval: $myval4"
echo "~~~~~~~~~~~ av bc a0 ~~~~~~~~~~~"
myval5=$(absval $myval)
echo "absval: $myval5"
myval5=$(bcE $myval5)
echo "bcE: $myval5"
myval5=$(append0 $myval5)
echo "append0: $myval5"
echo "~~~~~~~~~~~ av a0 bc ~~~~~~~~~~~"
myval6=$(absval $myval)
echo "absval: $myval6"
myval6=$(append0 $myval6)
echo "append0: $myval6"
myval6=$(bcE $myval6)
echo "bcE: $myval6"

