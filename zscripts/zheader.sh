#line=" debugging = running with new optimization of KEYS ordering with decimalgen..."
line="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
somedate=171024

for file in M0nu_header_*${somedate}*.txt
do
  sed -e '1!b' -e '/"$line"/!d' $file >> temp_${file}
  mv temp_${file} $file
  rm -f temp_${file}
done
