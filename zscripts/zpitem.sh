test=${1}
if [ -z $test ]
then
  test='false'
fi
if [ $test = 'true' ]
then
  ./zrecordit.sh
  record=M0nu_header_ZzzzzRECORD.txt
  temp=M0nu_header_ZzzzzTEMP.txt
  cp $record $temp
  lnum=$(wc -l $temp)
  lnum=${lnum% $temp}
  for ((i=1; i<=$lnum; i++))
  do
    header=$(sed -n "${i}p" $temp)
    barcode=${header#M0nu_header_}
    barcode=${barcode%??????????.txt}
    check=$(ls *${barcode}*) # this method will fail in the unlikely occurance that more than one header has the same barcode...
    if [ "$check" = $header ]
    then
      echo "removing: $barcode"
      ./zoffit.sh $barcode
    fi
  done
  rm -f $temp
else
  echo "understand this script first, it's risky..."
fi
