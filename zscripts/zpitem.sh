test=${1}
if [ -z $test ]
then
  test='false'
fi
if [ $test = 'true' ]
then
  echo
  echo 'MAKING SAFETY!'
  cd ..
  THEDATE=$(date +%y%m%d)
  tar -zcvf `basename $OLDPWD`_${THEDATE}.tar.gz `basename $OLDPWD`
  cd $OLDPWD
  echo
  echo 'START'
  record=M0nu_header_ZzzzzRECORD.txt
  temp=M0nu_header_ZzzzzTEMP.txt # this temp is important...
  ./znewrecord.sh
  echo 'v----------------------------------------------------------------v'
  oldrecnum=$(wc -l $record)
  oldrecnum=${oldrecnum%$record}
  echo "number of lines in old $record = $oldrecnum"
  echo '^----------------------------------------------------------------^'
  ./zlist.sh
  echo 'v----------------------------------------------------------------v'
  oldlsnum=$(./zlist.sh | wc -l)
  echo "number of lines in old ./zlist.sh stdout = $oldlsnum"
  echo '^----------------------------------------------------------------^'
  oldval=$(bc <<< "scale=3; $oldlsnum / 6")
  echo "++++++++++++ CHECK:    $oldlsnum / 6 = $oldval ?= $oldrecnum"
  cp $record $temp
  echo '-------------------------------------------------------------------------------------------------------------------------^^^ old ^^^'
  chemp='off'
  for ((i=1; i<=$oldrecnum; i++))
  do
    header=$(sed -n "${i}p" $temp)
    barcode=${header#M0nu_header_}
    barcode=${barcode%??????????.txt}
    check=$(ls *${barcode}*) # this method will fail in the unlikely occurance that more than one header has the same barcode...
    if [ "$check" = $header ]
    then
      chemp='on'
      echo "removing: $barcode"
      ./zoffit.sh $barcode
    fi
  done
  if [ $chemp = 'on' ]
  then
    sleep 3
    echo '-------------------------------------------------------------------------------------------------------------------------vvv new vvv'
    echo 'v----------------------------------------------------------------v'
    newrecnum=$(wc -l $record)
    newrecnum=${newrecnum%$record}
    echo "number of lines in new $record = $newrecnum"
    echo '^----------------------------------------------------------------^'
    ./zlist.sh
    echo 'v----------------------------------------------------------------v'
    newlsnum=$(./zlist.sh | wc -l)
    echo "number of lines in new ./zlist.sh stdout = $newlsnum"
    echo '^----------------------------------------------------------------^'
    newval=$(bc <<< "scale=3; $newlsnum / 6")
    echo "++++++++++++ CHECK:    $newlsnum / 6 = $newval ?= $newrecnum"
  else
    echo 'nada!'
    echo '-------------------------------------------------------------------------------------------------------------------------vvv new vvv'
    echo 'nothing was removed...'
  fi
  rm -f $temp
  echo 'FIN'
else
  echo "understand this script first, it's (somewhat) risky..."
fi
