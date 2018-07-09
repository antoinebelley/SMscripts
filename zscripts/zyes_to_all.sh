if [ $PWD != $IMASMS/zscripts ]
then
  echo 'you fool! exiting...'
  exit 1
fi

dir1=$IMAWRK/output
dir2=$IMAWRK/output_to_javier
dir3=$IMAWRK/debug_output

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
  fi
}

echo 'updating all relevant output directories with zscripts from $IMASMS...'
zreplace $dir1
zreplace $dir2
zreplace $dir3
