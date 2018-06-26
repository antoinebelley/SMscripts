#!/bin/bash
##  goM0nu.sh
##  by: Charlie Payne
##  last updated: June 26 2018
## DESCRIPTION
##  this script will automatically run nushellx and/or nutbar for an M0nu NME calculation
##  it will pull the relevant 0vbb operator information from an IMSRG evolution that has already been run
##  in particular, we calculate the decay: (ZI,A) -> (ZF,A) + 2e, where ZI=Z and ZF=Z+2
##  it will do all three of: GT, F, and/or T, depending on the barcode inputs
##  using 'BARE' for the flow is a special case whereby the sp/int is set phenomenologically via nushellx
##  alternatively, to manually set sp/int use the -o option, as described below (see "# override option 1" and "# override option 2" below)
##  please add executions of nushellx and nutbar to your PATH and such via .bashrc
##  this script will use nuqsub.sh from $imasms, as set below
## OPTIONS
##  -u for "usage": see script usage
##  -h for "help": less the relevant documentation and see script usage
##  -o <on|1|2> for "override": override the automatic search for *.int and *.sp, giving the user the chance to manually choose them
##  -x <string> for "extra": an additional tag for the directory naming
## PARAMETERS
##  1) ZI=${1}        # atomic (proton) number of the initial nucleus (I)
##  2) A=${2}         # mass number of the decay
##  3) flow=${3}      # 'BARE', 'MAGNUS', 'HYBRID', etc
##  4) sp=${4}        # the desired space to use in nushellx, see: nushellx/sps/label.dat
##  5) int=${5}       # " " interaction " " " "
##  6) int3N=${6}     # a label for which 3N interaction file was used
##  7) emax=${7}      # keep consistent with M0nu operator files
##  8) hw=${8}        # " " " " " "
##  9) nushon=${9}    # 's1', 's2', 's12', or 'off', where "s" stands for "stage"
## 10) GTbar=${10}    # the five letter barcode for the GT operator found in $imaout, to not run it in nutbar use 'zzzzz'
## 11) Fbar=${11}     # " " " " " " F " " " ", " " " " " " " "
## 12) Tbar=${12}     # " " " " " " T " " " ", " " " " " " " "
## STAGES
##  stage 0 = making directories, setting up files and symlinks
##  stage 1 = the first nushellx calculation, for the initial nucleus (I)
##  stage 2 = the second nushellx calculation, for the final nucleus (F), and submit the symlinks
##  stage 3 = the nutbar calculation(s) for the overall M0nu NME(s), and make the results copying script (the latter of which requires running GT, F, and/or T)
myUsage(){ echo "Usage ${1}: ${0} [-u for usage] [-h for help] [-o <on|1|2>] [-x <string>] <ZI> <A> <FLOW> <sp> <int> <int3N> <emax> <hw> <s1|s2|s12|off> <GTbar> <Fbar> <Tbar>" 1>&2; exit 1; }
neigI=5       # number of eigenstates for nushellx to calculate for the initial nucelus (I)
maxJI=6       # maximum total angular momentum of the initial nucleus' state (I)
delJI=1       # step size for the total angular momentum calculations (I)
neigF=5       # ...similar to above... (F)
maxJF=6       # ...similar to above... (F)
delJF=1       # ...similar to above... (F)
que=batchmpi    # to see which queues have been set, execute: qmgr -c "p s"
wall=144        # in [1,192],  walltime limit for qsub [hr]
ppn=12          # in [1,12],   the number of CPUs to use for the qsub
vmem=60         # in [1,60],   memory limit for qsub [GB]
nth=12          # in [1,12],   number of threads to use
snoozer=1       # set the sleep time between stages [s]
tagit='IMSRG'     # a tag for the symlinks below
imaout=$IMAOOO    # this must point to where the IMSRG output files live
imasms=$IMASMS    # " " " " " " nuqsub.sh script lives
imamyr=$IMAMYR    # " " " " " " nutbar results may be copied to
oron='on'
or1='1'
or2='2'
s1on='s1'
s2on='s2'
s12on='s12'
soff='off'
Zbar='zzzzz'
Ztime='zzzzzzzzzz'
Zid=000000



# pre-parse the script parameters
ormanual='0' # this gets turned on by the override argument
while getopts ":uho:x:" myopt # filter the script options
do
  case "${myopt}" in
    u) # -u for "usage": see script usage
      myUsage 1;;
    h) # -h for "help": less the relevant documentation and see script usage
      sed -n '4,27p; 28q' $imasms/README_CP.txt | less
      sed -n '2,36p; 37q' $imasms/goM0nu.sh | less
      myUsage 2
      ;;
    o) # -o <on|1|2> for "override": override the automatic search for *.int and *.sp, giving the user the chance to manually choose them
      override=${OPTARG}
      if [ $override = $or1 ] || [ $override = $or2 ]
      then
        ormanual=$override
        override=$oron # reset override to 'on' for ease of if-else statements
      fi
      if [ $override != $oron ]
      then
        myUsage 3
      fi
      ;;
    x) # -x <string> for "extra": an additional tag for the directory naming
      extra=${OPTARG};;
    \?)
      myUsage 4;;
  esac
done
shift $((OPTIND - 1)) # this shifts the script parameter number to compensate for those taken into getopts (OPTIND) above
if [ ${#} -ne 12 ] # check that the right number of script paramters have been filled
then
  myUsage 5
fi
ZI=${1}        # atomic (proton) number of the initial nucleus (I)
A=${2}         # mass number of the decay
flow=${3}      # 'BARE', 'MAGNUS', 'HYBRID', etc
sp=${4}        # the desired space to use in nushellx, see: nushellx/sps/label.dat
int=${5}       # " " interaction " " " "
int3N=${6}     # a label for which 3N interaction file was used
emax=${7}      # keep consistent with M0nu operator files
hw=${8}        # " " " " " "
nushon=${9}    # 's1', 's2', 's12', or 'off', where "s" stands for "stage"
GTbar=${10}    # the five letter barcode for the GT operator found in $imaout, to not run it in nutbar use 'zzzzz'
Fbar=${11}     # " " " " " " F " " " ", " " " " " " " "
Tbar=${12}     # " " " " " " T " " " ", " " " " " " " "


# parse the input
if [ $override = $oron ]
then
  echo
  echo "switching flow from '$flow' to 'HYBRID' (just accept it)..."
  echo
  flow='HYBRID' # if you remove this, you'll get what you deserve...
fi
if [ -z $override ]
then
  override='off'
elif [ $override = $oron ] && [ $extra ]
then
  extra="override_${extra}"
elif [ $override = $oron ] && [ -z $extra ]
then
  extra='override'
fi
ZF=$(($ZI+2)) # atomic (proton) number of the final nucleus (F)
if [ $ZF -gt 62 ]
then
  echo 'ERROR 8898: this nucleus is too heavy => extend the ELEM array!'
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
nucF=${ELEM[$ZF]}${A} # the final nucleus (F) label, eg) ti48
if [ $delJI -eq 0 ]
then
  delJI=1 # seems to be a default that nushellx sets, even if maxJI=0
fi
if [ $delJF -eq 0 ]
then
  delJF=1 # " " " " " " " " " " "
fi
quni="hw${hw}_e${emax}" # this is just to make the qsub's name more unique


# pre-check
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo "NME       =  M0nu"
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo "override  =  $override"
echo "extra     =  $extra"
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo "A         =  $A"
echo "nucI      =  $nucI"
echo "ZI        =  $ZI"
echo "neigI     =  $neigI"
echo "maxJI     =  $maxJI"
echo "delJI     =  $delJI"
echo "nucF      =  $nucF"
echo "ZF        =  $ZF"
echo "neigF     =  $neigF"
echo "maxJF     =  $maxJF"
echo "delJF     =  $delJF"
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo "flow      =  $flow"
echo "sp        =  $sp"
echo "int       =  $int"
echo "int3N     =  $int3N"
echo "emax      =  $emax"
echo "hw        =  $hw"
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo "nushon    =  $nushon"
echo "GTbar     =  $GTbar"
echo "Fbar      =  $Fbar"
echo "Tbar      =  $Tbar"
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo "que       =  $que"
echo "wall      =  $wall"
echo "ppn       =  $ppn"
echo "vmem      =  $vmem"
echo "nth       =  $nth"
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo 'is this input acceptable? (Y/N)'
read incheck
echo
if [ $incheck = 'n' ] || [ $incheck = 'N' ]
then
  echo 'exiting...'
  exit 1
fi
if [ $nushon != $s1on ] && [ $nushon != $s2on ] && [ $nushon != $s12on ] && [ $nushon != $soff ]
then
  echo 'ERROR 1862: invalid choice for nushon'
  echo "nushon = $nushon"
  echo 'exiting...'
  exit 1
fi


# function prototype: given an M0nu barcode, this function will get the corresponding time stamp
timeit(){
  local barcode=${1}
  local timestamp=$(ls ${imaout}/M0nu_header_${barcode}*.txt)
  timestamp=$(echo ${timestamp#${imaout}/M0nu_header_${barcode}})
  timestamp=$(echo ${timestamp%.txt})
  echo $timestamp
}



#----------------------------------- STAGE 0 -----------------------------------

# get the relevant time stamps
echo 'grabbing the relevant time stamps...'
echo
GTtime=$Ztime
Ftime=$Ztime
Ttime=$Ztime
if [ $GTbar != $Zbar ]
then
  GTtime=$(timeit $GTbar)
  GTbar=${GTbar}${GTtime}
fi
if [ $Fbar != $Zbar ]
then
  Ftime=$(timeit $Fbar)
  Fbar=${Fbar}${Ftime}
fi
if [ $Tbar != $Zbar ]
then
  Ttime=$(timeit $Tbar)
  Tbar=${Tbar}${Ttime}
fi
if [ -z $GTtime ] || [ -z $Ftime ] || [ -z $Ttime ]
then
  echo 'ERROR 2135: cannot find a barcode!'
  echo "GTbar  = $GTbar"
  echo "GTtime = $GTtime"
  echo "Fbar   = $Fbar"
  echo "Ftime  = $Ftime"
  echo "Tbar   = $Tbar"
  echo "Ttime  = $Ttime"
  echo 'exiting...'
  exit 1
fi
sleep $snoozer

# make the relevant directories
echo 'making the relevant directories...'
echo
mkdir -p $nucI
cd $nucI
basedir=$PWD
mydir=M0nu_${flow}_${sp}_${int}_${int3N}_e${emax}_hw${hw}
if [ $extra ]
then
  mydir=${mydir}_${extra}
fi
mkdir -p $mydir
cd $mydir
nudirI=nushxI_data        # this directory will hold the nushellx data for $nucI
nudirF=nushxF_data        # " " " " " " " " $nucF
linkdir='nushx_symlinks'  # this directory just holds the symlinks script and output from its clutser run
GTdir=GT_${GTbar}         # this directory will hold the GT nutbar results
Fdir=F_${Fbar}            # " " " " " F " "
Tdir=T_${Tbar}            # " " " " " T " "
mkdir -p $nudirI
mkdir -p $nudirF
mkdir -p $linkdir
if [ $GTbar != $Zbar ]
then
  mkdir -p $GTdir
fi
if [ $Fbar != $Zbar ]
then
  mkdir -p $Fdir
fi
if [ $Tbar != $Zbar ]
then
  mkdir -p $Tdir
fi
sleep $snoozer

# copy over the relevant files from the IMSRG output directory for nushellx (*.int and *.sp) and nutbar (*.op)
echo 'copying over the relevant files...'
echo
GTheader=M0nu_header_${GTbar}.txt
Fheader=M0nu_header_${Fbar}.txt
Theader=M0nu_header_${Tbar}.txt
intfile="*${GTbar}.int" # NOTE: the *.int and *.sp should be equivalent for all GT/F/T operators
spfile="*${GTbar}.sp"  # ": " " " " " " " " " " "
if [ $GTbar = $Zbar ] && [ $Fbar != $Zbar ]
then
  intfile="*${Fbar}.int"
  spfile="*${Fbar}.sp"
elif [ $GTbar = $Zbar ] && [ $Tbar != $Zbar ]
then
  intfile="*${Tbar}.int"
  spfile="*${Tbar}.sp"
fi
if [ $override = $oron ]
then
  echo 'manual OVERRIDE in effect...'
  if [ $ormanual = '0' ]
  then
    echo
    echo 'would you like to choose space/interaction files from <1|2>:'
    echo "1) nushellx with sp = $sp and int = $int [hint: does nushellx/sps/label.dat have these sp/int?]"
    echo 'or'
    echo "2) $imaout"
    read ormanual
  fi
  echo
  if [ $ormanual = $or1 ] # override option 1 (via nushellx)
  then
    echo 'running with...'
    echo "sp    = $sp"
    echo "int   = $int"
    echo "GTbar = $GTbar" # this could be (un)evolved, depending on the barcodes
    echo "Fbar  = $Fbar"  # " " " ", " " " "
    echo "Tbar  = $Tbar"  # " " " ", " " " "
    echo
  elif [ $ormanual = $or2 ] # override option 2 (fully manual)
  then
    echo "from:  $imaout"
    echo 'enter the name of the desired *.sp file:'
    read spfile
    echo 'enter the name of the desired *.int file:'
    read intfile
    echo
    if [ ! -s $imaout/$intfile ]
    then
      echo 'ERROR 6847: cannot find the given *.int file'
      echo "intfile = $intfile"
      echo 'exiting...'
      exit 1
    fi
    if [ ! -s $imaout/$spfile ]
    then
      echo 'ERROR 0152: cannot find the given *.sp file'
      echo "spfile = $spfile"
      echo 'exiting...'
      exit 1
    fi
  else
    echo 'ERROR 5818: invalid choice for ormanual'
    echo "ormanual = $ormanual"
    echo 'exiting...'
    exit 1
  fi
fi
if [ $nushon != $soff ] && [ -s $imaout/$intfile ] && [ -s $imaout/$spfile ]
then
  cp $imaout/$intfile $imaout/$spfile $nudirI
  cp $imaout/$intfile $imaout/$spfile $nudirF
elif [ $nushon != $soff ] && [ $flow != 'BARE' ] && [ $ormanual != $or1 ]
then
  echo 'ERROR 5294: cannot find the needed files for nushellx!'
  echo "spfile  = $spfile"
  echo "intfile = $intfile"
  echo 'exiting...'
  exit 1
fi
if [ $GTbar != $Zbar ]
then
  cd $GTdir
  if [ -s $imaout/*${GTbar}_1b.op ] && [ -s $imaout/*${GTbar}_2b.op ] && [ -s $imaout/$GTheader ]
  then
    cp $imaout/*${GTbar}_1b.op $imaout/*${GTbar}_2b.op .
    cp $imaout/$GTheader ..
  else
    echo 'ERROR 3983: cannot find the needed files!'
    echo "$GTdir is likely empty"
    echo 'exiting...'
    exit 1
  fi
  cd ..
fi
if [ $Fbar != $Zbar ]
then
  cd $Fdir
  if [ -s $imaout/*${Fbar}_1b.op ] && [ -s $imaout/*${Fbar}_2b.op ] && [ -s $imaout/$Fheader ]
  then
    cp $imaout/*${Fbar}_1b.op $imaout/*${Fbar}_2b.op .
    cp $imaout/$Fheader ..
  else
    echo 'ERROR 9101: cannot find the needed files!'
    echo "$Fdir is likely empty"
    echo 'exiting...'
    exit 1
  fi
  cd ..
fi
if [ $Tbar != $Zbar ]
then
  cd $Tdir
  if [ -s $imaout/*${Tbar}_1b.op ] && [ -s $imaout/*${Tbar}_2b.op ] && [ -s $imaout/$Theader ]
  then
    cp $imaout/*${Tbar}_1b.op $imaout/*${Tbar}_2b.op .
    cp $imaout/$Theader ..
  else
    echo 'ERROR 2409: cannot find the needed files!'
    echo "$Tdir is likely empty"
    echo 'exiting...'
    exit 1
  fi
  cd ..
fi
sleep $snoozer

# prepping all the relevant symlinks
echo 'prepping the relevant symlinks...'
echo
onebop=${flow}_M0nu_1b.op # the symlink name for the 1b op
twobop=${flow}_M0nu_2b.op # " " " " " 2b "
linksh=${linkdir}.sh # a script which will make additional symlinks, to be run after nushellx is done
cd $linkdir
rm -f $linksh # just in case it already exists
echo "cd $basedir/$mydir/$nudirI" >> $linksh
echo "for tempf in *.xvc *.nba *.prj *.sps *.sp *.lpt" >> $linksh
echo "do" >> $linksh
if [ $GTbar != $Zbar ]
then
  echo "  ln -sf ../$nudirI/\$tempf ../$GTdir/\$tempf" >> $linksh # this will make the appropriate symlinks of the nushellx stuff from the $nudirI to the $GTdir
fi
if [ $Fbar != $Zbar ]
then
  echo "  ln -sf ../$nudirI/\$tempf ../$Fdir/\$tempf" >> $linksh # " " " " " " " " " " " " " " " $Fdir
fi
if [ $Tbar != $Zbar ]
then
  echo "  ln -sf ../$nudirI/\$tempf ../$Tdir/\$tempf" >> $linksh # " " " " " " " " " " " " " " " $Tdir
fi
echo "done" >> $linksh
echo "cd $basedir/$mydir/$nudirF" >> $linksh
echo "for tempf in *.xvc *.nba *.prj *.sps *.sp *.lpt" >> $linksh
echo "do" >> $linksh
if [ $GTbar != $Zbar ]
then
  echo "  ln -sf ../$nudirF/\$tempf ../$GTdir/\$tempf" >> $linksh # this will make the appropriate symlinks of the nushellx stuff from the $nudirF to the $GTdir
fi
if [ $Fbar != $Zbar ]
then
  echo "  ln -sf ../$nudirF/\$tempf ../$Fdir/\$tempf" >> $linksh # " " " " " " " " " " " " " " " $Fdir
fi
if [ $Tbar != $Zbar ]
then
  echo "  ln -sf ../$nudirF/\$tempf ../$Tdir/\$tempf" >> $linksh # " " " " " " " " " " " " " " " $Tdir
fi
echo "done" >> $linksh
chmod 755 $linksh # make it executable from shell
cd ..
if [ $nushon != $soff ] && [ $flow != 'BARE' ] && [ $ormanual != $or1 ]
then
  cd $nudirI
  ln -sf $intfile ${tagit}.int
  ln -sf $spfile  ${tagit}.sp
  cd ../$nudirF
  ln -sf $intfile ${tagit}.int
  ln -sf $spfile  ${tagit}.sp
  cd ..
fi
if [ $GTbar != $Zbar ]
then
  cd $GTdir
  ln -sf *${GTbar}_1b.op $onebop
  ln -sf *${GTbar}_2b.op $twobop
  cd ..
fi
if [ $Fbar != $Zbar ]
then
  cd $Fdir
  ln -sf *${Fbar}_1b.op $onebop
  ln -sf *${Fbar}_2b.op $twobop
  cd ..
fi
if [ $Tbar != $Zbar ]
then
  cd $Tdir
  ln -sf *${Tbar}_1b.op $onebop
  ln -sf *${Tbar}_2b.op $twobop
  cd ..
fi
sleep $snoozer


#----------------------------------- STAGE 1 -----------------------------------

# run nushellx for the initial nucleus, $nucI
s1id=$Zid # stage 1 que id, as a backup...
nucIans=${nucI}.ans
nucIao=${nucIans}.o
if [ $nushon = $s1on ] || [ $nushon = $s12on ]
then
  cd $nudirI
  rm -f $nucIans # just in case it already exists
  rm -f $nucIao # " " " " " "
  echo '--------------------------------------------------' >> $nucIans
  echo "lpe,   ${neigI}             ! option (lpe or lan), neig (zero=10)" >> $nucIans
  if [ $flow != 'BARE' ] && [ $ormanual != $or1 ]
  then
    echo "${tagit}                ! model space (*.sp) name (a8)" >> $nucIans
  else
    echo "${sp}                ! model space (*.sp) name (a8)" >> $nucIans
  fi
  echo 'n                    ! any restrictions (y/n)' >> $nucIans
  if [ $flow != 'BARE' ] && [ $ormanual != $or1 ]
  then
    echo "${tagit}                ! interaction (*.int) name (a8)" >> $nucIans
  else
    echo "${int}                ! interaction (*.int) name (a8)" >> $nucIans
  fi
  echo " ${ZI}                  ! number of protons" >> $nucIans
  echo " ${A}                  ! number of nucleons" >> $nucIans
  echo " 0.0, ${maxJI}.0, ${delJI}.0,      ! min J, max J, del J" >> $nucIans
  echo '  0                  ! parity (0 for +) (1 for -) (2 for both)' >> $nucIans
  echo '--------------------------------------------------' >> $nucIans
  echo 'st                   ! option' >> $nucIans
  echo "setting up $nucIans for nushellx..."
  shell $nucIans >> $nucIao # set up files for nushellx, and divert stdout to file
  sleep $snoozer
  echo
  echo "running $nucI in $nudirI via qsub..."
  s1id=$($imasms/nuqsub.sh "bash -c \". $nucI.bat\"" $nucI "M0nu_nushx_${quni}" $que $wall $ppn $vmem $nth) # qsub nushellx
  sleep $snoozer
  echo "s1id(nus) = $s1id"
  echo
  cd ..
fi


#----------------------------------- STAGE 2 -----------------------------------

# run nushellx for the final nucleus, $nucF
s2id=$Zid # stage 2 que id, as a backup...
nucFans=${nucF}.ans
nucFao=${nucFans}.o
if [ $nushon = $s2on ] || [ $nushon = $s12on ]
then
  cd $nudirF
  rm -f $nucFans # just in case it already exists
  rm -f $nucFao # " " " " " "
  if [ -s ../$nudirI/$nucIans ]
  then
    cp ../$nudirI/$nucIans $nucFans
  else
    echo "ERROR 6659: cannot find nucIans = $nucIans for nucFans editing"
    echo 'exiting...'
    exit 1
  fi
  sed -i "2s/${neigI}/${neigF}/" $nucFans # replace $neigI with $neigF in line 2 of the file
  sed -i "6s/${ZI}/${ZF}/" $nucFans # replace $ZI with $ZF in line 6 of the file
  sed -i "8s/0.0, ${maxJI}.0, ${delJI}.0/0.0, ${maxJF}.0, ${delJF}.0/" $nucFans # replace J choices in line 8
  echo "setting up $nucFans for nushellx..."
  shell $nucFans >> $nucFao # set up files for nushellx, and divert stdout to file
  sleep $snoozer
  echo
  if [ $s1id != $Zid ]
  then
    echo "running $nucF in $nudirF via qsub with -W on $s1id..."
    s2id=$($imasms/nuqsub.sh "bash -c \". $nucF.bat\"" $nucF "M0nu_nushx_${quni}" $que $wall $ppn $vmem $nth $s1id) # qsub nushellx, and tell it to wait for $s1id to finish
  else
    echo "running $nucF in $nudirF via qsub..."
    s2id=$($imasms/nuqsub.sh "bash -c \". $nucF.bat\"" $nucF "M0nu_nushx_${quni}" $que $wall $ppn $vmem $nth) # qsub nushellx
  fi
  sleep $snoozer
  echo "s2id(nus) = $s2id"
  echo
  cd ..
fi

# run $linksh, dependant on how I've run nushellx
cd $linkdir
if [ $s2id != $Zid ]
then
  echo "running $linksh in $linkdir via qsub with -W on $s2id..."
  s2id=$($imasms/nuqsub.sh "./$linksh" $linkdir "M0nu_${quni}" $que '1' '1' '1' '1' $s2id) # qsub $linksh, and tell it to wait for $s2id to finish
elif [ $s1id != $Zid ]
then
  echo "running $linksh in $linkdir via qsub with -W on $s1id..."
  s2id=$($imasms/nuqsub.sh "./$linksh" $linkdir "M0nu_${quni}" $que '1' '1' '1' '1' $s1id) # qsub $linksh, " " " " " " $s1id " "
else
  echo "running $linksh in $linkdir via qsub..."
  s2id=$($imasms/nuqsub.sh "./$linksh" $linkdir "M0nu_${quni}" $que '1' '1' '1' '1') # qsub $linksh
fi
sleep $snoozer
echo "s2id(mls) = $s2id"
echo
cd ..


#----------------------------------- STAGE 3 -----------------------------------

# run nutbar to get final NME results
s3id=$Zid # stage 3 que id, as a backup...
outfile=nutbar_tensor0_${nucF}0.dat # this should contain the results! :)
nutrun=nutbar_${nucF}0
nutrunin=${nutrun}.input
rm -f $nutrunin # just in case it already exists, although it shouldn't...
if [ $flow != 'BARE' ] && [ $ormanual != $or1 ]
then
  echo "$tagit" >> $nutrunin
else
  echo "$sp" >> $nutrunin
fi
echo "${nucI}0" >> $nutrunin
echo "${nucF}0" >> $nutrunin
echo "${onebop} ${twobop}" >> $nutrunin
echo '0.0' >> $nutrunin
echo '1' >> $nutrunin
echo '0.0' >> $nutrunin
echo '1' >> $nutrunin
echo '' >> $nutrunin
if [ $GTbar != $Zbar ]
then
  cd $GTdir
  rm -f $outfile # just in case it already exists
  cp ../$nutrunin $nutrunin
  if [ $s2id != $Zid ]
  then
    echo "running nutbar in $GTdir via qsub with -W on $s2id..."
    s3id=$($imasms/nuqsub.sh "nutbar $nutrun.input" $nutrun "M0nu_${quni}_${GTbar}_GT" $que $wall $ppn $vmem $nth $s2id) # qsub nutbar for GT, and tell it to wait for $s2id to finish
  else
    echo "running nutbar in $GTdir via qsub..."
    s3id=$($imasms/nuqsub.sh "nutbar $nutrun.input" $nutrun "M0nu_${quni}_${GTbar}_GT" $que $wall $ppn $vmem $nth) # qsub nutbar for GT
  fi
  sleep $snoozer
  echo "s3id(GT) = $s3id"
  echo
  cd ..
fi
if [ $Fbar != $Zbar ]
then
  cd $Fdir
  rm -f $outfile # just in case it already exists
  cp ../$nutrunin $nutrunin
  if [ $s3id != $Zid ]
  then
    echo "running nutbar in $Fdir via qsub with -W on $s3id..."
    s3id=$($imasms/nuqsub.sh "nutbar $nutrun.input" $nutrun "M0nu_${quni}_${Fbar}_F" $que $wall $ppn $vmem $nth $s3id) # qsub nutbar for F, and tell it to wait for $s3id to finish
  elif [ $s2id != $Zid ]
  then
    echo "running nutbar in $Fdir via qsub with -W on $s2id..."
    s3id=$($imasms/nuqsub.sh "nutbar $nutrun.input" $nutrun "M0nu_${quni}_${Fbar}_F" $que $wall $ppn $vmem $nth $s2id) # qsub nutbar for F, and tell it to wait for $s2id to finish
  else
    echo "running nutbar in $Fdir via qsub..."
    s3id=$($imasms/nuqsub.sh "nutbar $nutrun.input" $nutrun "M0nu_${quni}_${Fbar}_F" $que $wall $ppn $vmem $nth) # qsub nutbar for F
  fi
  sleep $snoozer
  echo "s3id(F) = $s3id"
  echo
  cd ..
fi
if [ $Tbar != $Zbar ]
then
  cd $Tdir
  rm -f $outfile # just in case it already exists
  cp ../$nutrunin $nutrunin
  if [ $s3id != $Zid ]
  then
    echo "running nutbar in $Tdir via qsub with -W on $s3id..."
    s3id=$($imasms/nuqsub.sh "nutbar $nutrun.input" $nutrun "M0nu_${quni}_${Tbar}_T" $que $wall $ppn $vmem $nth $s3id) # qsub nutbar for T, and tell it to wait for $s3id to finish
  elif [ $s2id != $Zid ]
  then
    echo "running nutbar in $Tdir via qsub with -W on $s2id..."
    s3id=$($imasms/nuqsub.sh "nutbar $nutrun.input" $nutrun "M0nu_${quni}_${Tbar}_T" $que $wall $ppn $vmem $nth $s2id) # qsub nutbar for T, and tell it to wait for $s2id to finish
  else
    echo "running nutbar in $Tdir via qsub..."
    s3id=$($imasms/nuqsub.sh "nutbar $nutrun.input" $nutrun "M0nu_${quni}_${Tbar}_T" $que $wall $ppn $vmem $nth) # qsub nutbar for T
  fi
  sleep $snoozer
  echo "s3id(T) = $s3id"
  echo
  cd ..
fi
rm -rf $nutrunin # remove this from $mydir, since it was copied into $GTdir/$Fdir/$Tdir respectively

# make $mycpsh for further automation
mycpsh='mycopies.sh' # a script to copy the results to $imamyr
outfileGT=nutbar_tensor0_${nucF}0_${GTbar}.dat
outfileF=nutbar_tensor0_${nucF}0_${Fbar}.dat
outfileT=nutbar_tensor0_${nucF}0_${Tbar}.dat
if [ $GTbar != $Zbar ] || [ $Fbar != $Zbar ] || [ $Tbar != $Zbar ]
then
  rm -f $mycpsh # just in case it already exists
  if [ $GTbar != $Zbar ]
  then
    echo "mv $basedir/$mydir/$GTdir/$outfile $basedir/$mydir/$GTdir/$outfileGT 2>/dev/null" >> $mycpsh
  fi
  if [ $Fbar != $Zbar ]
  then
    echo "mv $basedir/$mydir/$Fdir/$outfile $basedir/$mydir/$Fdir/$outfileF 2>/dev/null" >> $mycpsh
  fi
  if [ $Tbar != $Zbar ]
  then
    echo "mv $basedir/$mydir/$Tdir/$outfile $basedir/$mydir/$Tdir/$outfileT 2>/dev/null" >> $mycpsh
  fi
  echo "cd $imamyr" >> $mycpsh
  echo "mkdir -p M0nu" >> $mycpsh
  echo 'cd M0nu' >> $mycpsh
  echo "mkdir -p $nucI" >> $mycpsh
  echo "cd $nucI" >> $mycpsh
  echo "mkdir -p $mydir" >> $mycpsh
  echo "cd $mydir" >> $mycpsh
  if [ $GTbar != $Zbar ]
  then
    echo "mkdir -p $GTdir" >> $mycpsh
    echo "cp $basedir/$mydir/$GTdir/${nucI}*.lpt $GTdir 2>/dev/null" >> $mycpsh
    echo "cp $basedir/$mydir/$GTdir/${nucF}*.lpt $GTdir 2>/dev/null" >> $mycpsh
    echo "cp $basedir/$mydir/$GTdir/$outfileGT $GTdir 2>/dev/null" >> $mycpsh
    echo "cp $basedir/$mydir/$GTheader . 2>/dev/null" >> $mycpsh
  fi
  if [ $Fbar != $Zbar ]
  then
    echo "mkdir -p $Fdir" >> $mycpsh
    echo "cp $basedir/$mydir/$Fdir/${nucI}*.lpt $Fdir 2>/dev/null" >> $mycpsh
    echo "cp $basedir/$mydir/$Fdir/${nucF}*.lpt $Fdir 2>/dev/null" >> $mycpsh
    echo "cp $basedir/$mydir/$Fdir/$outfileF $Fdir 2>/dev/null" >> $mycpsh
    echo "cp $basedir/$mydir/$Fheader . 2>/dev/null" >> $mycpsh
  fi
  if [ $Tbar != $Zbar ]
  then
    echo "mkdir -p $Tdir" >> $mycpsh
    echo "cp $basedir/$mydir/$Tdir/${nucI}*.lpt $Tdir 2>/dev/null" >> $mycpsh
    echo "cp $basedir/$mydir/$Tdir/${nucF}*.lpt $Tdir 2>/dev/null" >> $mycpsh
    echo "cp $basedir/$mydir/$Tdir/$outfileT $Tdir 2>/dev/null" >> $mycpsh
    echo "cp $basedir/$mydir/$Theader . 2>/dev/null" >> $mycpsh
  fi
  chmod 755 $mycpsh # make it executable from shell
fi


# output some reminders to screen
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo
echo "check:  ./$nucI/$mydir/$nudirI/${nucI}*.lpt"
echo "check:  ./$nucI/$mydir/$nudirF/${nucF}*.lpt"
if [ $GTbar != $Zbar ]
then
  echo "check:  ./$nucI/$mydir/$GTdir/$outfile"
fi
if [ $Fbar != $Zbar ]
then
  echo "check:  ./$nucI/$mydir/$Fdir/$outfile"
fi
if [ $Tbar != $Zbar ]
then
  echo "check:  ./$nucI/$mydir/$Tdir/$outfile"
fi
echo
echo "if you like the results in the $outfile(s) then run:  ./$nucI/$mydir/$mycpsh"
echo
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ FIN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo



## FIN
