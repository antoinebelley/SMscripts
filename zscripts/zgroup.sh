intlabel=new_magic
BB=3N
ARRemax=("4")
ARRhw=("16")
Z=20
A=48
date=180201
gfile=goM0nuGroup.sh
line="MAGNUS IMSRGfp magic magic"

Zbar=zzzzz
rm -f $gfile
echo "echo 'starting a group run...'" >> $gfile
for hw in "${ARRhw[@]}"
do
  for emax in "${ARRemax[@]}"
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
    echo "./goM0nu.sh ${Z} ${A} ${line} ${emax} ${hw} s12 ${GTbar} ${Fbar} ${Tbar}"
    echo "sleep 2" >> $gfile
    echo "./goM0nu.sh ${Z} ${A} ${line} ${emax} ${hw} s12 ${GTbar} ${Fbar} ${Tbar}" >> $gfile
  done
done
chmod 755 $gfile
mv $gfile $IMA0NU
