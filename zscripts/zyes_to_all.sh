if [ $PWD != $IMASMS/zscripts ]
then
  echo 'you fool! exiting...'
  exit 1
fi

dir1=$IMARUN/output
dir2=$IMARUN/output_to_javier
dir3=$IMARUN/debug_output

zreplace(){
  local dir=${1}
  cd $dir
  pwd
  rm -f z*.sh
  cp $IMASMS/zscripts/z*.sh .
}

echo 'updating all relevant output directories with zscripts from $IMASMS...'
zreplace $dir1
zreplace $dir2
zreplace $dir3
