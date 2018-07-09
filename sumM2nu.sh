#!/bin/bash
## this script will automatically sum up nutbar results into an M2nu NME
## the nutbar results come from properly executing nuM2nu.sh (so do this first)
## in particular, we calculate the decay: (ZI,A) -> (ZK,A) + e + v [fictituous intermediate state] -> (ZF,A) + 2e + 2v, where ZI=Z, ZK=Z+1, and ZF=Z+2
## with: initial (I) -> intermediate (K) -> final (F)
## NOTE: you must add in the relevant $Eshift and $EXP to "the $Eshift/$EXP if-else ladder" below
## all output files are saved in $nucI/$mydir/$outdir, as set below
## by: Charlie Payne
## copyright (c): 2016-2018
ZI=${1}         # atomic (proton) number of the initial nucleus (I)
A=${2}          # mass number of the decay
mydir=${3}      # the directory holding $nutfileK and $nutfileF, as set below
neigK=${4}      # the desired number of K to sum over, choose 'max' for the maximum
qf=${5}         # the GT quenching factor (some standards are 0.82, 0.77, 0.74), choose 'def' for the default
chift=${6}      # the choice of $Eshift as set below, the options are 'lit' or 'mine', see "the $Eshift/$EXP if-else ladder" below
abinopt=${7}    # 'abin' = run the sum ab-initio style by setting $EXP (below) to 0, if undesired it may be left blank (therefore running with $EXP correction to the s.e.s.)
precision=12      # the bc decimal precision
abinon='abin'
chlit='lit'
chmine='mine'


# parse the input
ZK=$(($ZI+1)) # atomic (proton) number of the intermediate nucleus (K)
ZF=$(($ZI+2)) # " " " " " final " (F)
if [ $ZF -gt 62 ]
then
  echo 'ERROR: this nucleus is too heavy => extend the ELEM array!'
  echo "ZF = $ZF"
  echo 'exiting...'
  exit 1
fi
ELEM=("blank" "h" "he"
      "li" "be" "b"  "c"  "n"  "o"  "f"  "ne"
      "na" "mg" "al" "si" "p"  "s"  "cl" "ar"
      "k"  "ca" "sc" "ti" "v"  "cr" "mn" "fe" "co" "ni" "cu" "zn" "ga" "ge" "as" "se" "br" "kr"
      "rb" "sr" "y"  "zr" "nb" "mo" "tc" "ru" "rh" "pd" "ag" "cd" "in" "sn" "sb" "te" "i"  "xe"
      "cs" "ba" "la" "ce" "pr" "nd" "pm" "sm") # an array of elements from Hydrogen (Z=1) to Samarium (Z=62), includes all current 0vbb candidates
nucI=${ELEM[$ZI]}${A} # the initial nucleus (I) label, eg) ca48
nucK=${ELEM[$ZK]}${A} # the intermediate nucleus (K) label, eg) sc48
nucF=${ELEM[$ZF]}${A} # the final nucleus (F) label, eg) ti48
Eshift=0  # initialize the energy shift in the demoninator of the M2nu NME summation equation [MeV]
EXP=0     # initialize the experimental energy correction (between the lowest lying summed ecxited state and the ground state for the K nucleus) [MeV]
if [ $nucK = 'example' ] # the $Eshift/$EXP if-else ladder
then
  if [ $chift = $chlit ]
  then
    Eshift=10.000000000  # = M_K + (M_I + M_F)/2 [MeV], the literature concention is ambiguous imo...
  elif [ $chift = $chmine ]
  then
    Eshift=9.489001054   # = M_K - m_e + (M_I + M_F)/2 [MeV], where these atomic masses are electrically neutral and in the nuclear ground state
  fi
  EXP=9.9999 # the experimental energy between the lowest lying summed excitation state and the ground state for $nucK
elif [ $nucK = 'sc48' ]
then
  if [ $chift = $chlit ]
  then
    Eshift=1.859700017  # = M_sc48 + (M_ca48 + M_ti48)/2 [MeV]
  elif [ $chift = $chmine ]
  then
    Eshift=1.348701071  # = M_sc48 - m_e + (M_ca48 + M_ti48)/2 [MeV]
  fi
  EXP=2.5173 # the experimental energy between the lowest lying 1+ state and the ground state for sc48
else
  echo 'ERROR: the $Eshift/$EXP for this decay has not been set, please add them to the $Eshift/$EXP if-else ladder!'
  echo "nucK = $nucK"
  echo 'exiting...'
  exit 1
fi
mydir=${mydir%\/} # just in case it has a "/" at the end...
maxK=${mydir#*neig}
maxK=${maxK%%_*}
flow=${mydir#M2nu_}
flow=${flow%%_*${maxK}*}
int=${mydir#M2nu_*_*_*_}
int=${int%_*_*_*_*${maxK}*}
if [ $neigK = 'max' ] || [ $neigK -gt $maxK ]
then
  neigK=$maxK
fi
if [ $qf = 'def' ]
then
  qf=0.77
fi
qfp=$(bc <<< "$qf*100/1") # the '/1' in the bc will put it into interger precision
if [ -z $abinopt ]
then
  abinopt='corrected'
fi
if [ $abinopt = $abinon ]
then
  EXP='off' # this will ensure no corrections to the lowest lying summed excitation state are made to match with experiment
fi


# pre-check
echo '~~~~~~~~~~~~~~~~~~~~~~~~~'
echo "A         =  $A"
echo "nucI      =  $nucI"
echo "nucK      =  $nucK"
echo "nucF      =  $nucF"
echo '~~~~~~~~~~~~~~~~~~~~~~~~~'
echo "Eshift    =  $Eshift"
echo "EXP       =  $EXP"
echo "neigK     =  $neigK"
echo "qf        =  $qf"
echo "chift     =  $chift"
echo "abinopt   =  $abinopt"
echo '~~~~~~~~~~~~~~~~~~~~~~~~~'
echo "maxK      =  $maxK"
echo "flow      =  $flow"
echo "int       =  $int"
echo '~~~~~~~~~~~~~~~~~~~~~~~~~'
echo 'is this input acceptable? (Y/N)'
read incheck
echo
if [ $incheck = 'n' ] || [ $incheck = 'N' ] || [ $incheck = '0' ]
then
  echo 'exiting...'
  exit 1
fi
if [ $chift != $chlit ] && [ $chift != $chmine ]
then
  echo 'ERROR: invalid choice for chift'
  echo "chift = $chift"
  echo 'exiting...'
  exit 1
fi
if [ -z $ZI ] || [ -z $A ] || [ -z $mydir ] || [ -z $neigK ] || [ -z $qf ]
then
  echo 'ERROR: you left something blank!'
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


# "big things have small beginnings"
KIdir=KI_nutbar # make sure this is consistent with the directory naming convention used in $mydir
FKdir=FK_nutbar # " " " " " " " " " " " " "
nutfileK=nutbar_tensor1_${nucK}0.dat
nutfileF=nutbar_tensor1_${nucF}0.dat
cd $nucI/$mydir
if [ ! -s $KIdir/$nutfileK ]
then
  echo "ERROR: cannot find $nucK nutbar file"
  echo "mydir     =  $mydir"
  echo "KIdir     =  $KIdir"
  echo "nutfileK  =  $nutfileK"
  echo 'exiting...'
  exit 1
fi
if [ ! -s $FKdir/$nutfileF ]
then
  echo "ERROR: cannot find $nucF nutbar file"
  echo "mydir     =  $mydir"
  echo "FKdir     =  $FKdir"
  echo "nutfileK  =  $nutfileF"
  echo 'exiting...'
  exit 1
fi
outdir=sumM2nu_output # this is the directory where I'll hold all the output, plotting files, etc...
if [ $chift = $chlit ]
then
  outdir="${outdir}_${chlit}"
elif [ $chift = $chmine ]
then
  outdir="${outdir}_${chmine}"
fi
outdir="${outdir}_${abinopt}"
mkdir -p $outdir
stampL="${int}_qf${qfp}_neig${neigK}"
stampS="${int}_neig${neigK}"
outfile=M2nu_${stampL}.txt # this will hold the results of the calculations done in this script
rm -f $outdir/$outfile # just in case it already exists
echo "mydir         =  $mydir" >> $outdir/$outfile
echo '' >> $outdir/$outfile
echo "A             =  $A" >> $outdir/$outfile
echo "nucI          =  $nucI" >> $outdir/$outfile
echo "nucK          =  $nucK" >> $outdir/$outfile
echo "nucF          =  $nucF" >> $outdir/$outfile
echo "Eshift        =  $Eshift" >> $outdir/$outfile
echo "EXP           =  $EXP" >> $outdir/$outfile
echo "neigK         =  $neigK" >> $outdir/$outfile
echo "qf            =  $qf" >> $outdir/$outfile
echo "abinopt       =  $abinopt" >> $outdir/$outfile

# get the nuclear g.s. energies
Knudir=gs_nushxK_data  # make sure this is consistent with the directory naming convention used in $mydir
Inudir=nushxI_data     # " " " " " " " " " " " " "
Fnudir=nushxF_data     # " " " " " " " " " " " " "
Kgsfile=${nucK}*.lpt
EKgs=$(getline '7' $Knudir/$Kgsfile)
EKgs=$(getp "$EKgs" '2')
Igsfile=${nucI}*.lpt
EIgs=$(getline '7' $Inudir/$Igsfile)
EIgs=$(getp "$EIgs" '2')
Fgsfile=${nucF}*.lpt
EFgs=$(getline '7' $Fnudir/$Fgsfile)
EFgs=$(getp "$EFgs" '2')
echo "EIgs          =  $EIgs" >> $outdir/$outfile
echo "EKgs          =  $EKgs" >> $outdir/$outfile
echo "EFgs          =  $EFgs" >> $outdir/$outfile

# check to see that $nucfileK and $nucfileF have the same number of lines; they should!
maxlK=$(wc -l $KIdir/$nutfileK)
maxlK=${maxlK%$KIdir/$nutfileK}
maxlF=$(wc -l $FKdir/$nutfileF)
maxlF=${maxlF%$FKdir/$nutfileF}
if [ $maxlK != $maxlF ]
then
  echo "$nutfileK and $nutfileF have different line counts!?"
  echo 'exiting...'
  exit 1
fi

# make a plotting scripts with accompanying data, which will be filled during the summation below
mhplot=Fig1MH
myplot=Fig2CP
plotfileuq=uq${mhplot}_${stampL}.dat  # this file will hold what is needed to plot something similar to FIG. 1 of PRC.75.034303(2007)
plotfileq=q${mhplot}_${stampL}.dat    # " " " " " " " " " " " " " " " "
plotsh1=plot${mhplot}_${stampL}.plt   # this file will plot the above, in $outdir use the command: gnuplot $plotsh1
plotfileKI=KIplot_${stampS}.dat       # this file is for plotting the nmeKI vs Ex, as set below
plotfileFK=FKplot_${stampS}.dat       # " " " " " " nmeFI " ", " " "
plotsh2=plot${myplot}_${stampS}.plt   # this file will plot the above, in $outdir use the command: gnuplot $plotsh2
echo "plotfileuq    =  $plotfileuq" >> $outdir/$outfile
echo "plotfileq     =  $plotfileq" >> $outdir/$outfile
echo "plotsh1       =  $plotsh1" >> $outdir/$outfile
echo "plotfileKI    =  $plotfileKI" >> $outdir/$outfile
echo "plotfileFK    =  $plotfileFK" >> $outdir/$outfile
echo "plotsh2       =  $plotsh2" >> $outdir/$outfile
echo '' >> $outdir/$outfile
rm -f $outdir/$plotfileuq # just in case it already exists
rm -f $outdir/$plotfileq # " " " " " "
rm -f $outdir/$plotsh1 # " " " " " "
rm -f $outdir/$plotfileKI # " " " " " "
rm -f $outdir/$plotfileFK # " " " " " "
rm -f $outdir/$plotsh2 # " " " " " "
echo 'set terminal png' >> $outdir/$plotsh1 # creating $plotsh1
echo "set output '${mhplot}_${int}.png'" >> $outdir/$plotsh1
if [ $flow = 'BARE' ]
then
  echo 'set xrange [0:15]' >> $outdir/$plotsh1
  echo 'set yrange [0:0.12]' >> $outdir/$plotsh1
fi
echo "plot '${plotfileq}' w l title 'qf = ${qf}', \\" >> $outdir/$plotsh1
echo "     '${plotfileuq}' w l title 'qf = 1'" >> $outdir/$plotsh1
echo 'set terminal png' >> $outdir/$plotsh2 # creating $plotsh2
echo "set output '${myplot}_${int}.png'" >> $outdir/$plotsh2
if [ $flow = 'BARE' ]
then
  echo 'set xrange [2:15]' >> $outdir/$plotsh2
  echo 'set arrow from 2,0 to 15,0 nohead linetype 9' >> $outdir/$plotsh2
else
  echo 'set arrow from 0,0 to 30,0 nohead linetype 9' >> $outdir/$plotsh2
fi
echo "plot '${plotfileKI}' w l title '< K | \sigma\tau | I >', \\" >> $outdir/$plotsh2
echo "     '${plotfileFK}' w l title '< F | \sigma\tau | K >'" >> $outdir/$plotsh2

# preform the sum that defines M2nu, that is:
# M^{2\nu} = \sum_K [ < F | \sigma\tau | K > < K | \sigma\tau | I > / ( E_K - E_\text{gs} + $Eshift ) ]
echo 'calculating M2nu sum...'
echo -e "nmeFK\t\t*\tnmeKI\t\t->\tnumer\t\t|  EK       EKgs     ; EK-EKgs +  Cexp   +  Eshift       ->  denom\t\t|\tnumer/denom\t+=  M2nu [running sum]" >> $outdir/$outfile
echo '----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'\
  >> $outdir/$outfile
M2nu=0 # initialize the sum over K
Cexp=0 # initialize the correction value = $EXP - min($EK-$EKgs)
maxKsum=$(($neigK+8-1))
for ((i=8; i<=$maxKsum; i++)) # start from i=8 because there's noted out header info in the nutbar_tensor*.dat files
do
  lineK=$(getline $i $KIdir/$nutfileK)
  EK=$(getp "$lineK" '4')
  nmeKI=$(getp "$lineK" '8')
  nmeKI=$(bcE $nmeKI)
  #nmeKI=$(absval $nmeKI) # debugging...
  lineF=$(getline $i $FKdir/$nutfileF)
  nmeFK=$(getp "$lineF" '8')
  nmeFK=$(bcE $nmeFK)
  #nmeFK=$(absval $nmeFK) # debugging...
  numer=$(bc <<< "scale=${precision}; ${nmeFK}*${nmeKI}") # the numerator of the sum
  Ex=$(bc <<< "scale=${precision}; ${EK} - ${EKgs}") # the excitation energy
  if [ $EXP != 'off' ] && [ $i -eq 8 ]
  then
    Cexp=$(bc <<< "scale=${precision}; ${EXP} - ${Ex}") # the experimental energy correction value
  fi
  ExC=$(bc <<< "scale=${precision}; ${Ex} + ${Cexp}") # the (experimentally corrected) excitation energy
  denom=$(bc <<< "scale=${precision}; ${Ex} + ${Cexp} + ${Eshift}") # the denominator of the sum
  tempval=$(bc <<< "scale=${precision}; ${numer}/${denom}") # see line below
  M2nu=$(bc <<< "scale=${precision}; ${tempval} + ${M2nu}") # the M2nu partial sums
  qM2nu=$(bc <<< "scale=${precision}; ${M2nu}*${qf}*${qf}") # the quenched version of M2nu, it has two factors of $qf since there are two GT operators in the numerator
  aM2nu=$(absval $M2nu) # just for plotting the partial sums
  aqM2nu=$(absval $qM2nu) # " " " " " "
  echo -e "$ExC\t$aM2nu" >> $outdir/$plotfileuq
  echo -e "$ExC\t$aqM2nu" >> $outdir/$plotfileq
  echo -e "$ExC\t$nmeKI" >> $outdir/$plotfileKI
  echo -e "$ExC\t$nmeFK" >> $outdir/$plotfileFK
  #echo -e "(  $nmeFK  *  $nmeKI  =  $numer  )/(  $EK  -  $EKgs  +  $Eshift  =  $denom  )\t\t\t=  $tempval,  +=  $M2nu" >> $outdir/$outfile
  echo -e "$nmeFK\t*\t$nmeKI\t->\t$numer\t|  $EK  $EKgs  ;  $Ex  +  $Cexp  +  $Eshift  ->  $denom\t|\t$tempval\t+=  $M2nu" >> $outdir/$outfile
done
M2nu=$(absval $M2nu)
M2nu=$(append0 $M2nu)
qM2nu=$(absval $qM2nu)
qM2nu=$(append0 $qM2nu)

# output to screen
echo '...and the calculation comes to!'
echo
echo "M2nu            =  $M2nu"
echo "M2nu*${qf}*${qf}  =  $qM2nu"
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
q1M2nu=$(bc <<< "scale=${precision}; $M2nu*0.82*0.82")
q1M2nu=$(absval $q1M2nu)
q1M2nu=$(append0 $q1M2nu)
q2M2nu=$(bc <<< "scale=${precision}; $M2nu*0.77*0.77")
q2M2nu=$(absval $q2M2nu)
q2M2nu=$(append0 $q2M2nu)
q3M2nu=$(bc <<< "scale=${precision}; $M2nu*0.74*0.74")
q3M2nu=$(absval $q3M2nu)
q3M2nu=$(append0 $q3M2nu)
echo "M2nu*0.82*0.82  =  $q1M2nu"
echo "M2nu*0.77*0.77  =  $q2M2nu"
echo "M2nu*0.74*0.74  =  $q3M2nu"
echo

# output to file
echo '...and the calculation comes to!' >> $outdir/$outfile
echo '' >> $outdir/$outfile
echo "M2nu            =  $M2nu" >> $outdir/$outfile
echo "qM2nu           =  $qM2nu" >> $outdir/$outfile
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' >> $outdir/$outfile
echo "M2nu*0.82*0.82  =  $q1M2nu" >> $outdir/$outfile
echo "M2nu*0.77*0.77  =  $q2M2nu" >> $outdir/$outfile
echo "M2nu*0.74*0.74  =  $q3M2nu" >> $outdir/$outfile
echo '' >> $outdir/$outfile

# output some reminders to screen
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo
echo "check:  ./$mydir/$outdir/$outfile"
echo "run:    ./$mydir/$outdir/gnuplot $plotsh1"
echo "run:    ./$mydir/$outdir/gnuplot $plotsh2"
echo
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ FIN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo


## FIN
