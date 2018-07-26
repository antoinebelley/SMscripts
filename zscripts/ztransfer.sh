GTbar=${1}
Fbar=${2}
Tbar=${3}
oakdir=/global/home/cgpayne/oakwork/imsrg_code/ragnar_imsrg/work/scripts/output
cougdir=/home/cgpayne/cougwork/imsrg_code/ragnar_imsrg/work/scripts/output

if [ $HOSTNAME = 'cougar.triumf.ca' ]
then
  scp *${GTbar}* *${Fbar}* *${Tbar}* oak:${oakdir}
elif [ $HOSTNAME = 'oak.arc.ubc.ca' ]
then
  scp *${GTbar}* *${Fbar}* *${Tbar}* cougar:${cougdir}
else
  echo 'ERROR: host not recognized'
  echo 'exiting...'
  exit 1
fi
