#!/bin/bash
##  nuM2nu.sh
##  by: Charlie Payne
##  copyright (c): 2016-2018
## DESCRIPTION
##  this script will automatically run nushellx and/or nutbar for an M2nu calculation
##  it will pull the relevant Gamow-Teller operator information from an IMSRG evolution that has already been run
##  after it is complete, to get the final NME summation you can execute sumM2nu.sh (following a successful run of this script)
##  in particular, we calculate the decay: (ZI,A) -> (ZK,A) + e + v [fictituous intermediate state] -> (ZF,A) + 2e + 2v, where ZI=Z, ZK=Z+1, and ZF=Z+2
##  with: initial (I) -> intermediate (K) -> final (F)
##  using 'BARE' for the flow is a special case whereby the sp/int is set phenomenologically via nushellx
##  alternatively, to manually set sp/int use the -o option, as described below (see "# override option 1" and "# override option 2" below)
##  NOTE: you must add in the intermediate nuclear ground state's (g.s.) J+ and summed excited states' (s.e.s.) J+ to "the g.s./s.e.s. if-else ladder" below
##  please add executions of nushellx and nutbar to your PATH and such via .bashrc
##  this will use nuqsub.sh from $imasms, as set below
## OPTIONS
##  -u for "usage": see script usage
##  -h for "help": less the relevant documentation and see script usage
##  -m for "MECs": find a GT operator with meson exchange currents (MECs)
##  -o <on|1|2> for "override": override the automatic search for *.int, *.sp, *_1b.op, and *_2b.op, giving the user the chance to manually choose them
##  -x <string> for "extra": an additional tag for the directory naming
## PARAMETERS
##  1) ZI=${1}        # atomic (proton) number of the initial nucleus (I)
##  2) A=${2}         # mass number of the decay
##  3) flow=${3}      # 'BARE', 'MAGNUS', 'HYBRID', etc
##  4) BB=${4}        # 'OS', 'HF', '3N', '2N' - acts as a descriptor to help find the GT operator in $imaout, see $filebase below
##  5) sp=${5}        # the desired space to use in nushellx, see: nushellx/sps/label.dat
##  6) int=${6}       # " " interaction " " " "
##  7) int3N=${7}     # a label for which 3N interaction file was used
##  8) emax=${8}      # keep consistent with M2nu operator files
##  9) hw=${9}        # " " " " " "
## 10) srun=${10}     # for eg) Q0QQQ = run stage 1, skip stage 2, and run stages 3-5
## 11) neigK=${11}    # the number of eigenstates to create for summing over the K excitation energies
## STAGES
##  stage 0 = making directories, setting up files and symlinks
##  stage 1 = the first nushellx calculation, for the initial nucleus (I)
##  stage 2 = the second nushellx calculations, for the intermediate nucleus (K)
##  stage 3 = the third nushellx calculation, for the final nucleus (F), and submit the symlinks
##  stage 4 = the nutbar calculation for the initial nucleus to the intermediate nucleus
##  stage 5 = the nutbar calculation for the intermediate nucleus to the final nucleus, and make the results copying script (the latter of which doesn't require any queing)
myUsage(){ echo "Usage ${1}: ${0} [-u for usage] [-h for help] [-m for MECs] [-o <on|1|2>] [-x <string>] <ZI> <A> <FLOW> <BB> <sp> <int> <int3N> <emax> <hw> <Q/0|Q/0|Q/0|Q/0|Q/0> <neigK>" 1>&2; exit 1; }
neigI=5              # number of eigenstates for nushellx to calculate for the initial nucelus (I)
maxJI=6              # maximum total angular momentum of the initial nucleus' state (I)
delJI=1              # step size for the total angular momentum calculations (I)
maxJK=6              # ...similar to above... (K)
delJK=1              # ...similar to above... (K)
neigF=5              # ...similar to above... (F)
maxJF=6              # ...similar to above... (F)
delJF=1              # ...similar to above... (F)
que=batchmpi           # to see which queues have been set, execute: qmgr -c "p s"
wall=144               # in [1,192],  walltime limit for qsub [hr]
ppn=12                 # in [1,12],   the number of CPUs to use for the qsub
vmem=60                # in [1,60],   memory limit for qsub [GB]
nth=12                 # in [1,12],   number of threads to use
snoozer=1              # set the sleep time between stages [s]
tagit='IMSRG'            # a tag for the symlinks below
catch='forM2nu'          # acts as a descriptor to help find the GT operator in $imaout, see $filebase below
catchGT='GamowTeller'    # " " " " " " " " " " " ", " " " (without MECs)
catchMEC='GTFULL'        # " " " " " " " " " " " ", " " " (with MECs)
imaout=$IMAOUT           # this must point to where the IMSRG output files live
imasms=$IMASMS           # " " " " " " nuqsub.sh script lives
imamyr=$IMAMYR           # " " " " " " final results may be copied to
mecon='MEC'
oron='on'
or1='1'
or2='2'
runon='Q'
runoff='0'
Zid=000000



# pre-parse the script parameters
ormanual='0' # this gets turned on by the override argument
while getopts ":uhmo:x:" myopt # filter the script options
do
  case "${myopt}" in
    u) # -u for "usage": see script usage
      myUsage 1;;
    h) # -h for "help": less the relevant documentation and see script usage
      sed -n '29,49p; 50q' $imasms/README_CP.txt | command less
      sed -n '2,40p; 41q' $imasms/nuM2nu.sh | command less
      myUsage 2
      ;;
    m) # -m for "MECs": find a GT operator with meson exchange currents (MECs)
      mecopt=$mecon;;
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
if [ ${#} -ne 11 ] # check that the right number of script paramters have been filled
then
  myUsage 5
fi
ZI=${1}        # atomic (proton) number of the initial nucleus (I)
A=${2}         # mass number of the decay
flow=${3}      # 'BARE', 'MAGNUS', 'HYBRID', etc
BB=${4}        # 'OS', 'HF', '3N', '2N' - acts as a descriptor to help find the GT operator in $imaout, see $filebase below
sp=${5}        # the desired space to use in nushellx, see: nushellx/sps/label.dat
int=${6}       # " " interaction " " " "
int3N=${7}     # a label for which 3N interaction file was used
emax=${8}      # keep consistent with M2nu operator files
hw=${9}        # " " " " " "
srun=${10}     # for eg) Q0QQQ = run stage 1, skip stage 2, and run stages 3-5
neigK=${11}    # the number of eigenstates to create for summing over the K excitation energies


# parse the input
if [ -z $override ]
then
  override='off'
elif [ $override = $oron ]
then
  echo
  echo "switching flow from '$flow' to 'HYBRID' (just accept it)..."
  echo
  flow='HYBRID' # if you remove this, you'll get what you deserve...
  if [ -z $extra ]
  then
    extra='override'
  else
    extra="override_${extra}"
  fi
fi
if [ -z $mecopt ]
then
  mecopt='off'
elif [ $mecopt = $mecon ]
then
  catch=${catch}${mecon} # this may need to change (or just use the -o option), depending on your file naming convention, see $filebase below
  if [ -z $extra ]
  then
    extra=$mecon
  else
    extra="${mecon}_${extra}"
  fi
fi
s1run=$(echo ${srun:0:1})
s2run=$(echo ${srun:1:1})
s3run=$(echo ${srun:2:1})
s4run=$(echo ${srun:3:1})
s5run=$(echo ${srun:4:1})
s123run=${s1run}${s2run}${s3run}
s123off=${runoff}${runoff}${runoff}
salloff=${runoff}${runoff}${runoff}${runoff}${runoff}
ZK=$(($ZI+1)) # atomic (proton) number of the intermediate nucleus (K)
ZF=$(($ZI+2)) # " " " " " final " (F)
if [ $ZF -gt 62 ]
then
  echo 'ERROR 2374: this nucleus is too heavy => extend the ELEM array!'
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
gsJK=-1  # the total angular momentum of the intermediate nuclear ground state
gsPK=-1  # the parity of the " " " ", 0 = positive, 1 = negative
sesJK=-1 # the total angular momentum of the intermediate nuclear excited states (to be summed over)
sesPK=-1 # the parity of the " " " " " " " ", 0 = positive, 1 = negative
if [ $nucK = 'example' ] # the g.s./s.e.s. if-else ladder
then
  gsJK=0
  gsPK=0
  sesJK=1
  sesPK=0
elif [ $nucK = 'sc48' ]
then
  gsJK=6
  gsPK=0
  sesJK=1
  sesPK=0
else
  echo 'ERROR 0429: the intermediate g.s./s.e.s. for this decay has not been set, please add them to the g.s./s.e.s. if-else ladder!'
  echo "nucK = $nucK"
  echo 'exiting...'
  exit 1
fi
if [ $delJI -eq 0 ]
then
  delJI=1 # seems to be a default that nushellx sets, even if maxJI=0
fi
if [ $delJK -eq 0 ]
then
  delJK=1 # " " " " " " " " " " "
fi
if [ $delJF -eq 0 ]
then
  delJF=1 # " " " " " " " " " " "
fi
quni="${mecopt}_hw${hw}_e${emax}" # this is just to make the qsub's name more unique


# pre-check
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo "NME       =  M2nu"
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo "mecopt    =  $mecopt"
echo "override  =  $override"
echo "extra     =  $extra"
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo "A         =  $A"
echo "nucI      =  $nucI"
echo "ZI        =  $ZI"
echo "neigI     =  $neigI"
echo "maxJI     =  $maxJI"
echo "delJI     =  $delJI"
echo "nucK      =  $nucK"
echo "ZK        =  $ZK"
echo "neigK     =  $neigK"
echo "maxJK     =  $maxJK"
echo "delJK     =  $delJK"
echo "nucF      =  $nucF"
echo "ZF        =  $ZF"
echo "neigF     =  $neigF"
echo "maxJF     =  $maxJF"
echo "delJF     =  $delJF"
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo "flow      =  $flow"
echo "BB        =  $BB"
echo "sp        =  $sp"
echo "int       =  $int"
echo "int3N     =  $int3N"
echo "emax      =  $emax"
echo "hw        =  $hw"
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo "srun      =  $s1run $s2run $s3run $s4run $s5run"
echo "gsJK      =  $gsJK"
echo "gsPK      =  $gsPK"
echo "sesJK     =  $sesJK"
echo "sesPK     =  $sesPK"
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
if [ $s1run != $runon ] && [ $s1run != $runoff ]
then
  echo 'ERROR 9004: invalid choice for srun'
  echo "s1run = $s1run"
  echo 'exiting...'
  exit 1
fi
if [ $s2run != $runon ] && [ $s2run != $runoff ]
then
  echo 'ERROR 8717: invalid choice for srun'
  echo "s2run = $s2run"
  echo 'exiting...'
  exit 1
fi
if [ $s3run != $runon ] && [ $s3run != $runoff ]
then
  echo 'ERROR 3721: invalid choice for srun'
  echo "s3run = $s3run"
  echo 'exiting...'
  exit 1
fi
if [ $s4run != $runon ] && [ $s4run != $runoff ]
then
  echo 'ERROR 8265: invalid choice for srun'
  echo "s4run = $s4run"
  echo 'exiting...'
  exit 1
fi
if [ $s5run != $runon ] && [ $s5run != $runoff ]
then
  echo 'ERROR 1483: invalid choice for srun'
  echo "s5run = $s5run"
  echo 'exiting...'
  exit 1
fi
if ! [[ $neigK =~ '^-?[0-9]+$' ]]
then
  echo 'ERROR 3529: neigK needs to be a number'
  echo "neigK = $neigK"
  echo 'exiting...'
  exit 1
fi
if [ $neigK -le 0 ]
then
  echo 'ERROR 8861: neigK needs to be a positive integer'
  echo "neigK = $neigK"
  echo 'exiting...'
  exit 1
fi



#----------------------------------- STAGE 0 -----------------------------------

# find the relevant files
echo 'finding the relevant files...'
echo
temppwd=$PWD
filebase="*" # NOTE: the following construction of $filebase may need to change (or just use the -o option), depending on your file naming convention
if [ $flow = 'BARE' ]
then
  filebase="${filebase}${flow}*${BB}*"
elif [ $int = 'magic' ] # this might also need to change, depending on your file naming convention
then
  filebase="${filebase}${int}*${BB}*"
else
  filebase="${filebase}${BB}*${int}*"
fi
filebase="${filebase}e${emax}*hw${hw}*A${A}*${catch}_"
intfile=${filebase}.int
spfile=${filebase}.sp
GT1bfile=${filebase}
if [ $mecopt = $mecon ]
then
  GT1bfile=${GT1bfile}${catchMEC}_1b.op
else
  GT1bfile=${GT1bfile}${catchGT}_1b.op
fi
GT2bfile=${filebase}
if [ $mecopt = $mecon ]
then
  GT2bfile=${GT2bfile}${catchMEC}_2b.op
else
  GT2bfile=${GT2bfile}${catchGT}_2b.op
fi
if [ $override = $oron ]
then
  echo 'manual OVERRIDE in effect...'
  echo
  echo "from:  $imaout"
  echo 'enter the name of the desired *_1b.op file:'
  echo '(make sure this file matches with the script parameters)'
  if [ $mecopt = $mecon ]
  then
    echo '(make sure this file has full MECs)'
  fi
  read GT1bfile
  echo 'enter the name of the desired *_2b.op file:'
  echo '(make sure this file matches with the script parameters)'
  if [ $mecopt = $mecon ]
  then
    echo '(make sure this file has full MECs)'
  fi
  read GT2bfile
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
    echo "sp   = $sp"
    echo "int  = $int"
    echo "GT1b = $GT1bfile"
    echo "GT2b = $GT2bfile"
    echo
  elif [ $ormanual = $or2 ] # override option 2 (fully manual)
  then
    echo "from:  $imaout"
    echo 'enter the name of the desired *.sp file:'
    read spfile
    echo 'enter the name of the desired *.int file:'
    read intfile
    echo
  else
    echo 'ERROR 1264: invalid choice for ormanual'
    echo "ormanual = $ormanual"
    echo 'exiting...'
    exit 1
  fi
fi
if [ ! -s $imaout/$intfile ] && [ $flow != 'BARE' ] && [ $ormanual != $or1 ]
then
  if [ $override = $oron ]
  then
    echo 'ERROR 7395: cannot find the given *.int file'
  else
    echo 'ERROR 4991: cannot find the relevant *.int file'
  fi
  echo "intfile = $intfile"
  echo 'exiting...'
  exit 1
fi
if [ ! -s $imaout/$spfile ] && [ $flow != 'BARE' ] && [ $ormanual != $or1 ]
then
  if [ $override = $oron ]
  then
    echo 'ERROR 1828: cannot find the given *.sp file'
  else
    echo 'ERROR 7059: cannot find the relevant *.sp file'
  fi
  echo "spfile = $spfile"
  echo 'exiting...'
  exit 1
fi
if [ ! -s $imaout/$GT1bfile ]
then
  if [ $override = $oron ]
  then
    echo 'ERROR 7763: cannot find the given *_1b.op file'
  else
    echo 'ERROR 5365: cannot find the relevant *_1b.op file'
  fi
  echo "GT1bfile = $GT1bfile"
  echo 'exiting...'
  exit 1
fi
if [ ! -s $imaout/$GT2bfile ]
then
  if [ $override = $oron ]
  then
    echo 'ERROR 8476: cannot find the given *_2b.op file'
  else
    echo 'ERROR 4552: cannot find the relevant *_2b.op file'
  fi
  echo "GT2bfile = $GT2bfile"
  echo 'exiting...'
  exit 1
fi
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
cd $imaout
if [ $s123run != $s123off ] && [ $flow != 'BARE' ] && [ $ormanual != $or1 ]
then
  echo -n "the *.int file is:   "
  ls $intfile
  echo -n "the *.sp file is:    "
  ls $spfile
fi
echo -n "the *1b.op file is:  "
ls $GT1bfile
echo -n "the *2b.op file is:  "
ls $GT2bfile
cd $temppwd
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo 'NOTE: if multiple files are listed per *.int, *.sp, *1b.op, or *2b.op => you got problems!'
if [ $override != $oron ]
then
  echo "filebase = $filebase"
fi
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo 'are these files acceptable? (Y/N)'
read inchagain
echo
if [ $inchagain = 'n' ] || [ $inchagain = 'N' ] || [ $inchagain = '0' ]
then
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
mydir=M2nu_${flow}_${BB}_${sp}_${int}_${int3N}_e${emax}_hw${hw}_neig${neigK}
if [ $mecopt = $mecon ]
then
  mydir=${mydir}_${mecon}
fi
if [ $extra ]
then
  mydir=${mydir}_${extra}
fi
mkdir -p $mydir
cd $mydir
nudirI=nushxI_data        # this directory will hold the nushellx data for $nucI
nudirKgs=gs_nushxK_data   # " " " " " " " " the ground state of $nucK
nudirK=nushxK_data        # " " " " " " " " $nucK
nudirF=nushxF_data        # " " " " " " " " $nucF
linkdir='nushx_symlinks'  # this directory just holds the symlinks script and output from its clutser run
KIdir=KI_nutbar           # this director will hold the < K | \sigma\tau | i > nutbar results
FKdir=FK_nutbar           #" " " " " < F | \sigma\tau | K > " "
mkdir -p $nudirI
mkdir -p $nudirKgs
mkdir -p $nudirK
mkdir -p $nudirF
mkdir -p $linkdir
if [ $s4run = $runon ]
then
  mkdir -p $KIdir
fi
if [ $s5run = $runon ]
then
  mkdir -p $FKdir
fi
sleep $snoozer

# copy over the relevant files from the IMSRG output directory for nushellx (*.int and *.sp) and nutbar (*.op)
echo 'copying over the relevant files...'
echo
if [ $s123run != $s123off ] && [ -s $imaout/$intfile ] && [ -s $imaout/$spfile ]
then
  cp $imaout/$intfile $imaout/$spfile $nudirI
  cp $imaout/$intfile $imaout/$spfile $nudirK
  cp $imaout/$intfile $imaout/$spfile $nudirKgs
  cp $imaout/$intfile $imaout/$spfile $nudirF
elif [ $s123run != $s123off ] && [ $flow != 'BARE' ] && [ $ormanual != $or1 ]
then
  echo 'ERROR 0610: cannot find the needed files for nushellx!'
  echo "spfile  = $spfile"
  echo "intfile = $intfile"
  echo 'exiting...'
  exit 1
fi
if [ $s4run = $runon ]
then
  cp $imaout/$GT1bfile $imaout/$GT2bfile $KIdir
fi
if [ $s5run = $runon ]
then
  cp $imaout/$GT1bfile $imaout/$GT2bfile $FKdir
fi
sleep $snoozer

# prepping all the relevant symlinks
echo 'prepping the relevant symlinks...'
echo
onebop=${flow}_M2nu_1b.op # the symlink name for the 1b op
twobop=${flow}_M2nu_2b.op # " " " " " 2b "
linksh=${linkdir}.sh # a script which will make additional symlinks, to be run after nushellx is done
cd $linkdir
rm -f $linksh # just in case it already exists
echo "cd $basedir/$mydir/$nudirI" >> $linksh
echo "for tempf in *.xvc *.nba *.prj *.sps *.sp *.lpt" >> $linksh
echo "do" >> $linksh
if [ $s4run = $runon ]
then
  echo "  ln -sf ../$nudirI/\$tempf ../$KIdir/\$tempf" >> $linksh # this will make the appropriate symlinks of the nushellx stuff from the $nudirI to the $KIdir
fi
echo "done" >> $linksh
echo "cd $basedir/$mydir/$nudirK" >> $linksh
echo "for tempf in *.xvc *.nba *.prj *.sps *.sp *.lpt" >> $linksh
echo "do" >> $linksh
if [ $s4run = $runon ]
then
  echo "  ln -sf ../$nudirK/\$tempf ../$KIdir/\$tempf" >> $linksh # this will make the appropriate symlinks of the nushellx stuff from the $nudirK to the $KIdir
fi
if [ $s5run = $runon ]
then
  echo "  ln -sf ../$nudirK/\$tempf ../$FKdir/\$tempf" >> $linksh # " " " " " " " " " " " " " " " $FKdir
fi
echo "done" >> $linksh
echo "cd $basedir/$mydir/$nudirF" >> $linksh
echo "for tempf in *.xvc *.nba *.prj *.sps *.sp *.lpt" >> $linksh
echo "do" >> $linksh
if [ $s5run = $runon ]
then
  echo "  ln -sf ../$nudirF/\$tempf ../$FKdir/\$tempf" >> $linksh # this will make the appropriate symlinks of the nushellx stuff from the $nudirF to the $FKdir
fi
echo "done" >> $linksh
chmod 755 $linksh # make it executable from shell
cd ..
if [ $s123run != $s123off ] && [ $flow != 'BARE' ] && [ $ormanual != $or1 ]
then
  cd $nudirI
  ln -sf $intfile ${tagit}.int
  ln -sf $spfile  ${tagit}.sp
  cd ..
  cd $nudirK
  ln -sf $intfile ${tagit}.int
  ln -sf $spfile  ${tagit}.sp
  cd ..
  cd $nudirKgs
  ln -sf $intfile ${tagit}.int
  ln -sf $spfile  ${tagit}.sp
  cd ..
  cd $nudirF
  ln -sf $intfile ${tagit}.int
  ln -sf $spfile  ${tagit}.sp
  cd ..
fi
if [ $s4run = $runon ]
then
  cd $KIdir
  ln -sf $GT1bfile $onebop
  ln -sf $GT2bfile $twobop
  cd ..
fi
if [ $s5run = $runon ]
then
  cd $FKdir
  ln -sf $GT1bfile $onebop
  ln -sf $GT2bfile $twobop
  cd ..
fi
sleep $snoozer
exit 1 # debug


#----------------------------------- STAGE 1 -----------------------------------

# run nushellx for the initial nucleus, $nucI
s1id=$Zid # stage 1 que id, as a backup...
nucIans=${nucI}.ans
nucIao=${nucIans}.o
#nucInushxo=${nucI}.term.o # (janky fix)
if [ $s1run = $runon ]
then
  cd $nudirI
  rm -f $nucIans # just in case it already exists
  rm -f $nucIao # " " " " " "
  #rm -f $nucInushxo # " " " " " " (janky fix)
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
  echo "running $nucI via qsub..."
  s1id=$($imasms/nuqsub.sh "bash -c \". $nucI.bat\"" $nucI "M2nu_nushx_${quni}_${neigK}" $que $wall $ppn $vmem $nth) # qsub nushellx
  sleep $snoozer
  echo "s1id(nus) = $s1id"
  echo
  cd ..
fi


#----------------------------------- STAGE 2 -----------------------------------

# run nushellx for the intermediate nucleus, $nucK
s2id=$Zid # stage 2 que id, as a backup...
nucKans=${nucK}.ans
nucKao=${nucKans}.o
if [ $s2run = $runon ]
then
  # first we'll calculate the g.s. energy
  cd $nudirKgs
  rm -f $nucKans # just in case it already exists
  rm -f $nucKao # " " " " " "
  if [ -s ../$nudirI/$nucIans ]
  then
    cp ../$nudirI/$nucIans $nucKans
  else
    echo "ERROR 1106: cannot find nucIans = $nucIans for nucKans editing"
    echo 'exiting...'
    exit 1
  fi
  sed -i "2s/${neigI}/1/" $nucKans # replace $neigI with 1 in line 2 of the file
  sed -i "6s/${ZI}/${ZK}/" $nucKans # replace $ZI with $ZK in line 6 of the file
  sed -i "8s/0.0, ${maxJI}.0, ${delJI}.0/${gsJK}.0, ${gsJK}.0, 1.0/" $nucKans # replace J choices in line 8
  sed -i "9s/0/${gsPK}/" $nucKans # replace parity choice in line 9
  echo "setting up $nucKans for nushellx of the g.s. energy..."
  shell $nucKans >> $nucKao # set up files for nushellx, and divert stdout to file
  sleep $snoozer
  echo
  if [ $s1id != $Zid ]
  then
    echo "running $nucK for the g.s. energy via qsub with -W on $s1id..."
    s2id=$($imasms/nuqsub.sh "bash -c \". $nucK.bat\"" $nucK "M2nu_nushx_${quni}_gs_${neigK}" $que $wall $ppn $vmem $nth $s1id) # qsub nushellx, and tell it to wait for $s1id to finish
  else
    echo "running $nucK for the g.s. energy via qsub..."
    s2id=$($imasms/nuqsub.sh "bash -c \". $nucK.bat\"" $nucK "M2nu_nushx_${quni}_gs_${neigK}" $que $wall $ppn $vmem $nth) # qsub nushellx
  fi
  sleep $snoozer
  echo "s2id(ngs) = $s2id"
  echo
  cd ..

  # now we'll calculate the J=${sesJK} excitation energies
  cd $nudirK
  rm -f $nucKans # just in case it already exists
  rm -f $nucKao # " " " " " "
  cp ../$nudirI/$nucIans $nucKans # already checked that it exists above
  sed -i "2s/${neigI}/${neigK}/" $nucKans # replace $neigI with $neigK in line 2 of the file
  sed -i "6s/${ZI}/${ZK}/" $nucKans # replace $ZI with $ZK in line 6 of the file
  sed -i "8s/0.0, ${maxJI}.0, ${delJI}.0/${sesJK}.0, ${sesJK}.0, 1.0/" $nucKans # replace J choices in line 8
  sed -i "9s/0/${sesPK}/" $nucKans # replace parity choice in line 9
  echo "setting up $nucKans for nushellx of the J=${sesJK} excitation energies..."
  shell $nucKans >> $nucKao # set up files for nushellx, and divert stdout to file
  sleep $snoozer
  echo
  echo "running $nucK for the J=${sesJK} excitation energies via qsub with -W on $s2id..."
  s2id=$($imasms/nuqsub.sh "bash -c \". $nucK.bat\"" $nucK "M2nu_nushx_${quni}_${neigK}" $que $wall $ppn $vmem $nth $s2id) # qsub nushellx, and tell it to wait for the previous $s2id to finish
  sleep $snoozer
  echo "s2id(ses) = $s2id"
  echo
  cd ..
fi


#----------------------------------- STAGE 3 -----------------------------------

# run nushellx for the final nucleus, $nucF
s3id=$Zid # stage 3 que id, as a backup...
nucFans=${nucF}.ans
nucFao=${nucFans}.o
if [ $s3run = $runon ]
then
  cd $nudirF
  rm -f $nucFans # just in case it already exists
  rm -f $nucFao # " " " " " "
  if [ -s ../$nudirI/$nucIans ]
  then
    cp ../$nudirI/$nucIans $nucFans
  else
    echo "ERROR 7469: cannot find nucIans = $nucIans for nucFans editing"
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
  if [ $s2id != $Zid ]
  then
    echo "running $nucF via qsub with -W on $s2id..."
    s3id=$($imasms/nuqsub.sh "bash -c \". $nucF.bat\"" $nucF "M2nu_nushx_${quni}_${neigK}" $que $wall $ppn $vmem $nth $s2id) # qsub nushellx, and tell it to wait for $s2id to finish
  else
    echo "running $nucF via qsub..."
    s3id=$($imasms/nuqsub.sh "bash -c \". $nucF.bat\"" $nucF "M2nu_nushx_${quni}_${neigK}" $que $wall $ppn $vmem $nth) # qsub nushellx
  fi
  sleep $snoozer
  echo "s3id(nus) = $s3id"
  echo
  cd ..
fi

# run $linksh, dependant on how I've run nushellx
if [ $srun != $salloff ]
then
  cd $linkdir
  if [ $s3id != $Zid ]
  then
    echo "running $linksh in $linkdir via qsub with -W on $s3id..."
    s3id=$($imasms/nuqsub.sh "./$linksh" $linkdir "M2nu_$quni" $que '1' '1' '1' '1' $s3id) # qsub $linksh, and tell it to wait for $s3id to finish
  elif [ $s2id != $Zid ]
  then
    echo "running $linksh in $linkdir via qsub with -W on $s2id..."
    s3id=$($imasms/nuqsub.sh "./$linksh" $linkdir "M2nu_$quni" $que '1' '1' '1' '1' $s2id) # qsub $linksh, " " " " " " $s2id " "
  elif [ $s1id != $Zid ]
  then
    echo "running $linksh in $linkdir via qsub with -W on $s1id..."
    s3id=$($imasms/nuqsub.sh "./$linksh" $linkdir "M2nu_$quni" $que '1' '1' '1' '1' $s1id) # qsub $linksh, " " " " " " $s1id " "
  else
    sleep $snoozer
    echo "running $linksh in $linkdir via qsub..."
    s3id=$($imasms/nuqsub.sh "./$linksh" $linkdir "M2nu_quni" $que '1' '1' '1' '1') # qsub $linksh
  fi
  sleep $snoozer
  echo "s3id(mls) = $s3id"
  echo
  cd ..
fi


#----------------------------------- STAGE 4 -----------------------------------

# run nutbar to get the < K | \sigma\tau | I > NMEs
s4id=$Zid # stage 4 que id, as a backup...
outfile4=nutbar_tensor1_${nucK}0.dat # this should contain the results! :)
nutrun4=nutbar_${nucK}0
nutrun4in=${nutrun4}.input
if [ $s4run = $runon ]
then
  cd $KIdir
  rm -f $nutrun4in # just in case it already exists
  if [ $flow != 'BARE' ] && [ $ormanual != $or1 ]
  then
    echo "$tagit" >> $nutrun4in
  else
    echo "$sp" >> $nutrun4in
  fi
  echo "${nucI}0" >> $nutrun4in
  echo "${nucK}0" >> $nutrun4in
  echo "${onebop} ${twobop}" >> $nutrun4in
  echo '0.0' >> $nutrun4in
  echo '1' >> $nutrun4in
  echo "${sesJK}.0" >> $nutrun4in
  echo "${neigK}" >> $nutrun4in
  echo '' >> $nutrun4in
  rm -f $outfile4 # just in case it already exists
  if [ $s3id != $Zid ]
  then
    echo "running nutbar for $nucI to $nucK via qsub with -W on $s3id..."
    s4id=$($imasms/nuqsub.sh "nutbar $nutrun4.input" $nutrun4 "M2nu_${neigK}_${quni}" $que $wall $ppn $vmem $nth $s3id) # qsub nutbar, and tell it to wait for $s3id to finish
  else
    echo "running nutbar for $nucI to $nucK via qsub..."
    s4id=$($imasms/nuqsub.sh "nutbar $nutrun4.input" $nutrun4 "M2nu_${neigK}_${quni}" $que $wall $ppn $vmem $nth) # qsub nutbar
  fi
  sleep $snoozer
  echo "s4id(nut) = $s4id"
  echo
  cd ..
fi


#----------------------------------- STAGE 5 -----------------------------------

# run nutbar to get the < F | \sigma\tau | K > NMEs
s5id=$Zid # stage 5 que id, as a backup...
outfile5=nutbar_tensor1_${nucF}0.dat # this should contain the results! :)
nutrun5=nutbar_${nucF}0
nutrun5in=${nutrun5}.input
if [ $s5run = $runon ]
then
  cd $FKdir
  rm -f $nutrun5in # just in case it already exists
  if [ $flow != 'BARE' ] && [ $ormanual != $or1 ]
  then
    echo "$tagit" >> $nutrun5in
  else
    echo "$sp" >> $nutrun5in
  fi
  echo "${nucK}0" >> $nutrun5in
  echo "${nucF}0" >> $nutrun5in
  echo "${onebop} ${twobop}" >> $nutrun5in
  echo "${sesJK}.0" >> $nutrun5in
  echo "${neigK}" >> $nutrun5in
  echo '0.0' >> $nutrun5in
  echo '1' >> $nutrun5in
  echo '' >> $nutrun5in
  rm -f $outfile5 # just in case it already exists
  if [ $s4id != $Zid ]
  then
    echo "running nutbar for $nucK to $nucF via qsub with -W on $s4id..."
    s5id=$($imasms/nuqsub.sh "nutbar $nutrun5.input" $nutrun5 "M2nu_${neigK}_${quni}" $que $wall $ppn $vmem $nth $s4id) # qsub nutbar, and tell it to wait for $s4id to finish
  else
    echo "running nutbar for $nucK to $nucF via qsub..."
    s5id=$($imasms/nuqsub.sh "nutbar $nutrun5.input" $nutrun5 "M2nu_${neigK}_${quni}" $que $wall $ppn $vmem $nth) # qsub nutbar
  fi
  sleep $snoozer
  echo "s5id(nut) = $s5id"
  echo
  cd ..
fi

# make $mycpsh for further automation
mycpsh='mycopies.sh' # a script to copy the results to $imamyr
totmyr="$imamyr/M2nu/$nucI/$mydir"
rm -f $mycpsh # just in case it already exists
echo "mkdir -p $imamyr/M2nu" >> $mycpsh
echo "mkdir -p $imamyr/M2nu/$nucI" >> $mycpsh
echo "mkdir -p $totmyr" >> $mycpsh
echo "mkdir -p $totmyr/$nudirI" >> $mycpsh
echo "mkdir -p $totmyr/$nudirKgs" >> $mycpsh
echo "mkdir -p $totmyr/$nudirK" >> $mycpsh
echo "mkdir -p $totmyr/$nudirF" >> $mycpsh
echo "mkdir -p $totmyr/$KIdir" >> $mycpsh
echo "mkdir -p $totmyr/$FKdir" >> $mycpsh
echo "cp $nudirI/${nucI}*.lpt $totmyr/$nudirI" >> $mycpsh
echo "cp $nudirKgs/${nucK}*.lpt $totmyr/$nudirKgs" >> $mycpsh
echo "cp $nudirK/${nucK}*.lpt $totmyr/$nudirK" >> $mycpsh
echo "cp $nudirF/${nucF}*.lpt $totmyr/$nudirF" >> $mycpsh
echo "cp $KIdir/$outfile4 $totmyr/$KIdir" >> $mycpsh
echo "cp $FKdir/$outfile5 $totmyr/$FKdir" >> $mycpsh
echo "cp -R sumM2nu_* $totmyr" >> $mycpsh # NOTE: technically none of these will exist until sumM2nu.sh is run
chmod 755 $mycpsh # make it executable from shell


# output some reminders to screen
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo
if [ $s1run = $runon ]
then
  echo "check:  ./$nucI/$mydir/$nudirI/${nucI}*.lpt"
fi
if [ $s2run = $runon ]
then
  echo "check:  ./$nucI/$mydir/$nudirKgs/${nucK}*.lpt"
  echo "check:  ./$nucI/$mydir/$nudirK/${nucK}*.lpt"
fi
if [ $s3run = $runon ]
then
  echo "check:  ./$nucI/$mydir/$nudirF/${nucF}*.lpt"
fi
if [ $s4run = $runon ]
then
  echo "check:  ./$nucI/$mydir/$KIdir/$outfile4"
fi
if [ $s5run = $runon ]
then
  echo "check:  ./$nucI/$mydir/$FKdir/$outfile5"
fi
echo
echo 'if you like the results and want to compile the final M2nu NME summation then run:'
echo "  ./sumM2nu.sh $ZI $A $mydir max def mine abin"
echo
echo "if you like the summation results, then run:  ./$nucI/$mydir/$mycpsh"
echo
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ FIN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo



## FIN
