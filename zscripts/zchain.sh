intlabel=magic
BB=3N
emax=8
hw=16
Z=22
Amin=44
Amax=58
date=17083
chfile=goM0nuChain.sh
line="MAGNUS IMSRGfp magic magic"

Zbar=zzzzz
rm -f $chfile
for ((A=$Amin; A<=$Amax; A+=2))
do
  GTbar=$(ls *${intlabel}*${BB}*e${emax}*hw${hw}*A${A}*_GT_*${date}*.int)
  GTbar=${GTbar#*GT_}
  GTbar=${GTbar%??????????.int}
  if [ -z $GTbar ]
  then
    GTbar=$Zbar
  fi
  Fbar=$(ls *${intlabel}*${BB}*e${emax}*hw${hw}*A${A}*_F_*${date}*.int)
  Fbar=${Fbar#*F_}
  Fbar=${Fbar%??????????.int}
  if [ -z $Fbar ]
  then
    Fbar=$Zbar
  fi
  Tbar=$(ls *${intlabel}*${BB}*e${emax}*hw${hw}*A${A}*_T_*${date}*.int)
  Tbar=${Tbar#*T_}
  Tbar=${Tbar%??????????.int}
  if [ -z $Tbar ]
  then
    Tbar=$Zbar
  fi
  echo "./goM0nu.sh ${Z} ${A} ${line} ${emax} ${hw} s12 ${GTbar} ${Fbar} ${Tbar} chain"
  echo "sleep 2" >> $chfile
  echo "./goM0nu.sh ${Z} ${A} ${line} ${emax} ${hw} s12 ${GTbar} ${Fbar} ${Tbar} chain" >> $chfile
done
chmod 755 $chfile
mv $chfile $IMA0NU
