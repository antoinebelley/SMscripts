gtfile=${1}
mecfile=${2}
extra=${3}
que=batchmpi
wall=1
ppn=1
vmem=1
nth=1
$IMASMS/nuqsub.sh "./zMEC.sh ${gtfile} ${mecfile} ${extra}" 'crunchMEC' 'off' $que $wall $ppn $vmem $nth
