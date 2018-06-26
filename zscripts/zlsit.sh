myfile=M0nu_header_ZzzzzNEW.txt
maxline=$(wc -l $myfile)
maxline=${maxline%$myfile}
breakit='---------------------------------'

line='null'
lnum=$[${maxline}-1]
while [ "$line" != $breakit ] || [ $lnum -eq 1 ]
do
  line=$(sed -n "${lnum}p" $myfile)
  checkit=${line:0:1}
  if [ "$checkit" = '<' ]
  then
    barcode=${line#< M0nu_header_}
    barcode=${barcode:0:5}
    ls *${barcode}*
    echo $breakit
  fi
  lnum=$[${lnum}-1]
done
