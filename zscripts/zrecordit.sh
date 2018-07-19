ls M0nu_header_???????????????.txt > M0nu_header_ZzzzzTEMP.txt 2> /dev/null
diffstuff=$(command diff    M0nu_header_ZzzzzTEMP.txt    M0nu_header_ZzzzzRECORD.txt)
if [ "$diffstuff" ]
then
  echo "recording the following changes in: `basename $PWD`"
  command diff    M0nu_header_ZzzzzTEMP.txt    M0nu_header_ZzzzzRECORD.txt
  command diff    M0nu_header_ZzzzzTEMP.txt    M0nu_header_ZzzzzRECORD.txt >> M0nu_header_ZzzzzNEW.txt
  echo '---------------------------------' >> M0nu_header_ZzzzzNEW.txt
else
  echo "nothing new to record in: `basename $PWD`..."
fi
mv    M0nu_header_ZzzzzTEMP.txt    M0nu_header_ZzzzzRECORD.txt
