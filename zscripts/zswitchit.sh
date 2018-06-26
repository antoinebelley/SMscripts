barcode=${1}
switch=${2}
place=BCM0

timestamp=$(ls M0nu_header_${barcode}*.txt)
timestamp=$(echo ${timestamp#M0nu_header_${barcode}})
timestamp=$(echo ${timestamp%.txt})
barcode=${barcode}${timestamp}

for File in *${barcode}*.sp *${barcode}*.int *${barcode}*.op
do
  New=$(echo $File | sed s/${place}/${switch}_${place}/)
  mv $File $New
done
