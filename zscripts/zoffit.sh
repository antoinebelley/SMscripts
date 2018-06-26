if [ -z "$(echo -e "$@" | tr -d '[:space:]')" ]
then
  echo 'you fool! exiting...'
  exit 1
else
  for barcode in "$@"
  do
    timestamp=$(ls M0nu_header_${barcode}*.txt)
    timestamp=$(echo ${timestamp#M0nu_header_${barcode}})
    timestamp=$(echo ${timestamp%.txt})
    if [ $timestamp ]
    then
      barcode="${barcode}${timestamp}"
      rm -f *${barcode}*.txt
      rm -f *${barcode}*.op
      rm -f *${barcode}*.sp
      rm -f *${barcode}*.int
      rm -f *${timestamp}*.dat
      sed -i "/$barcode/d" M0nu_header_ZzzzzNEW.txt
      sed -i "/$barcode/d" M0nu_header_ZzzzzRECORD.txt
    else
      echo "not able to match barcode=$barcode with a timestamp, cancelling removal..."
    fi
  done
fi
