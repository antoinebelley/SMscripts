if [ $PWD != $IMASMS/zscripts ]
then
  echo 'you fool! exiting...'
  exit 1
fi

dir0=$IMAWRK/debug_output
dir1=$IMAWRK/output
dir2=$IMAWRK/output_Ca48
dir3=$IMAWRK/output_Ge76
dir4=$IMAWRK/output_Se82
dir5=$IMAWRK/output_to_javier
dir6=$IMAWRK/output_to_mihai

zreplace(){
  local dir=${1}
  local myerr="$(cd $dir 2>&1)"
  if [[ $myerr = *"No such file or directory"* ]]
  then
    echo $myerr
    echo 'copying failed, directory skipped...'
  else
    cd $dir
    pwd
    rm -f z*.sh
    cp $IMASMS/zscripts/z*.sh .
    cd $IMASMS/zscripts
  fi
}

echo 'updating all relevant output directories with zscripts from $IMASMS...'
zreplace $dir0
zreplace $dir1
zreplace $dir2
zreplace $dir3
zreplace $dir4
zreplace $dir5
zreplace $dir6
