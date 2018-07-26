intlabel=magic
#intlabel=BARE
BB=3N
#BB=OS
ARRemax=("10" "12")
#ARRemax=("4")
ARRhw=("16" "24")
#ARRhw=("10.49")
Z=20
A=48
date=180726
gfile=goM0nuGroup.sh
preopt=''
line='MAGNUS IMSRGfp magic magic'
#line='BARE fppn gx1apn none'

Zbar=zzzzz
rm -f $gfile
echo "echo 'starting a group run...'" >> $gfile
for hw in "${ARRhw[@]}"
do
  for emax in "${ARRemax[@]}"
  do
    GTbar=$(ls *${intlabel}*${BB}*e${emax}*hw${hw}*A${A}*_GT_*${date}*.int)
    GTbar=${GTbar#*_GT_}
    GTbar=${GTbar%??????????.int}
    if [ -z $GTbar ]
    then
      GTbar=$Zbar
    fi
    Fbar=$(ls *${intlabel}*${BB}*e${emax}*hw${hw}*A${A}*_F_*${date}*.int)
    Fbar=${Fbar#*_F_}
    Fbar=${Fbar%??????????.int}
    if [ -z $Fbar ]
    then
      Fbar=$Zbar
    fi
    Tbar=$(ls *${intlabel}*${BB}*e${emax}*hw${hw}*A${A}*_T_*${date}*.int)
    Tbar=${Tbar#*_T_}
    Tbar=${Tbar%??????????.int}
    if [ -z $Tbar ]
    then
      Tbar=$Zbar
    fi
    if [ ! -z "$preopt" ]
    then
      MYRUN="./goM0nu.sh ${preopt} ${Z} ${A} ${line} ${emax} ${hw} s12 ${GTbar} ${Fbar} ${Tbar}"
    else
      MYRUN="./goM0nu.sh ${Z} ${A} ${line} ${emax} ${hw} s12 ${GTbar} ${Fbar} ${Tbar}"
    fi
    echo "$MYRUN"
    echo "sleep 2" >> $gfile
    echo "$MYRUN" >> $gfile
  done
done
chmod 755 $gfile
mv $gfile $IMA0NU
