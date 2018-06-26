MYHOST=$(hostname)
if [ $MYHOST == 'cougar.triumf.ca' ]
then
  echo "I'm on cougar! updating SMscripts..."
elif [ $MYHOST == 'oak.arc.ubc.ca' ]
then
  echo "I'm on oak! updating SMscripts..."
  # goM0nu.sh
  sed -i "44s/que=batchmpi/que=oak     /" goM0nu.sh
  sed -i "45s/wall=144/wall=384/" goM0nu.sh
  sed -i "45s/\[1,192]/\[1,512\]/" goM0nu.sh
  sed -i "46s/ppn=12/ppn=32/" goM0nu.sh
  sed -i "46s/\[1,12\],/\[1,32\],/" goM0nu.sh
  sed -i "47s/vmem=60 /vmem=251/" goM0nu.sh
  sed -i "47s/\[1,60\], /\[1,251\],/" goM0nu.sh
  sed -i "48s/nth=12/nth=32/" goM0nu.sh
  sed -i "48s/\[1,12\],/\[1,32\],/" goM0nu.sh
  # nuM2nu.sh
  sed -i "50s/que=batchmpi/que=oak     /" nuM2nu.sh
  sed -i "51s/wall=144/wall=384/" nuM2nu.sh
  sed -i "51s/\[1,192]/\[1,512\]/" nuM2nu.sh
  sed -i "52s/ppn=12/ppn=32/" nuM2nu.sh
  sed -i "52s/\[1,12\],/\[1,32\],/" nuM2nu.sh
  sed -i "53s/vmem=60 /vmem=251/" nuM2nu.sh
  sed -i "53s/\[1,60\], /\[1,251\],/" nuM2nu.sh
  sed -i "54s/nth=12/nth=32/" nuM2nu.sh
  sed -i "54s/\[1,12\],/\[1,32\],/" nuM2nu.sh
  # nuqsub.sh
  sed -i "17s/myqtag='cougar'/myqtag='login1'/" nuqsub.sh
  sed -i "18s/myqidlength='6'/myqidlength='4'/" nuqsub.sh
  sed -i "24s/192/512/" nuqsub.sh
  sed -i "26s/12/32/" nuqsub.sh
  sed -i "28s/60/251/" nuqsub.sh
  sed -i "30s/12/32/" nuqsub.sh
else
  echo 'ERROR: host not recognized'
  echo 'exiting...'
  exit 1
fi
cp goM0nu.sh $IMA0NU
cp nuM2nu.sh sumM2nu.sh $IMA2NU
