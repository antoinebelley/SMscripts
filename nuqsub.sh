#!/bin/bash
## this bash shell script will create a PBS script and qsub it to the cluster
## the stdout of this script is the qsubbed job ib
## it will put the output in the $PWD from which the script is called
## if argumement ${9} is not empty, then this qsubbed job will wait on H until the job in ${9} has finished
##  By: Charlie Payne
##  Copyright (C): 2018
##  License: see LICENSE (GNU GPL v3)
mycmd=${1}        # the terminal execution command, eg) for nushellx it is like '. ca48.bat' and for nutbar it is 'nutbar nutbar_ca480.input'
myrun=${2}        # the run name, eg) for nushellx it is the basename of *.ans and for nutbar it is the basename of *.input
mybarcode=${3}    # an additional barcode to make the run name more unqiue in the qsub (if undesired then enter 'off')
myque=${4}        # to see which queues have been set, execute: qmgr -c "p s"
mywall=${5}       # in [1,$mywallmax],  walltime limit for qsub [hr]
myppn=${6}        # in [1,$myppnmax],   the number of CPUs to use for the qsub
myvmem=${7}       # in [1,$myvmemmax],  memory limit for qsub [GB]
mynth=${8}        # in [1,$mynthmax],   number of threads to use
pastid=${9}       # a currently running qsub id, or leave it empty
myqtag='cougar'              # the cluster tag that appears in the job id
myqidlength='6'              # the number of digits in the job id (this could change over time, keep it update!)
myemail='cgpayne@triumf.ca'  # this email will receive job completion alerts


# pre-check
mywallmin=1
mywallmax=192
myppnmin=1
myppnmax=12
myvmemmin=1
myvmemmax=60
mynthmin=1
mynthmax=12
if [ $mywall -lt $mywallmin ]
then
  mywall=$mywallmin
elif [ $mywall -gt $mywallmax ]
then
  mywall=$mywallmax
fi
if [ $myppn -lt $myppnmin ]
then
  myppn=$myppnmin
elif [ $myppn -gt $myppnmax ]
then
  myppn=$myppnmax
fi
if [ $myvmem -lt $myvmemmin ]
then
  myvmem=$myvmemmin
elif [ $myvmem -gt $myvmemmax ]
then
  myvmem=$myvmemmax
fi
if [ $mynth -lt $mynthmin ]
then
  mynth=$mynthmin
elif [ $mynth -gt $mynthmax ]
then
  mynth=$mynthmax
fi
if [ -z $pastid ]
then
  pastid=000000
fi


# create the run script for qsub using PBS
mypbsfile=${myrun}.pbs
rm -f $mypbsfile # just in case it already exists
echo '#!/bin/bash' >> $mypbsfile
echo "#PBS -q $myque" >> $mypbsfile # this determines which queue to use
if [ $mybarcode = 'off' ]
then
  echo "#PBS -N ${myrun}" >> $mypbsfile # this names the qsub job
else
  echo "#PBS -N ${mybarcode}_${myrun}" >> $mypbsfile # " " " " "
fi
echo "#PBS -d $PWD" >> $mypbsfile # this determines where the output of the qsub job will live
echo "#PBS -l walltime=${mywall}:00:00" >> $mypbsfile # this limits how long the qsub job will run
echo "#PBS -l nodes=1:ppn=${myppn}" >> $mypbsfile # this limits how many CPUs on the node the qsub job can use
echo "#PBS -l vmem=${myvmem}gb" >> $mypbsfile # this limits how much virtual memory on the node the qsub job can use
echo '#PBS -m ae' >> $mypbsfile # this means the cluster will send an email once the qsub job is done (see line below)
echo "#PBS -M $myemail" >> $mypbsfile # this sets said email for the cluster to talk to (see line above)
echo '#PBS -j oe' >> $mypbsfile # this joins the stdout of the qsub job into an output file (see line below)
echo "#PBS -o ${myrun}.pbs.o" >> $mypbsfile # this names the stdout file (see line above)
if [ $pastid != 000000 ]
then
  echo "#PBS -W depend=afterok:${pastid}.${myqtag}" >> $mypbsfile # this holds the current qsub job until $pastid is done running
fi
echo 'echo "--v-- pbs script RUN at: `date` --v--"' >> $mypbsfile # echo the submission start time
echo 'cd $PBS_O_WORKDIR' >> $mypbsfile # this changes the directory to the relevant one
echo "export OMP_NUM_THREADS=${mynth}" >> $mypbsfile # this sets the number of threads to parallelize on
echo "$mycmd" >> $mypbsfile # THIS IS THE RUN LINE
echo 'echo "--^--  pbs script FIN at: `date` --^--"' >> $mypbsfile # on oak, can't do "qstat -f $PBS_JOBID" on non-interactive shell

# qsub the sucker
myid=$(qsub $mypbsfile) # call the command and capture the stdout
myid=${myid:0:${myqidlength}} # get the job id
echo $myid # this may be captured as an stdout of this script


## FIN
