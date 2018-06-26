ls M0nu_header_???????????????.txt > M0nu_header_ZzzzzTEMP.txt
diff	M0nu_header_ZzzzzTEMP.txt	M0nu_header_ZzzzzRECORD.txt
diff	M0nu_header_ZzzzzTEMP.txt	M0nu_header_ZzzzzRECORD.txt >> M0nu_header_ZzzzzNEW.txt
echo '---------------------------------' >> M0nu_header_ZzzzzNEW.txt
mv	M0nu_header_ZzzzzTEMP.txt	M0nu_header_ZzzzzRECORD.txt
