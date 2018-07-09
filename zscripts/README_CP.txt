zchain.sh
    This grabs specified (see the parameters at the top) M0nu TBME output files from imsrg++,
        then gets the relevant "barcodes" and creates a group run file for ../goM0nu.sh called "goM0nuChain.sh"
            and moves it to the M0nu ShellModel directory.
    Hence, a chain of runs for some Z over values of A can easily be submitted to the que by just running this script. 

zgroup.sh
    This is identical to ./zchain.sh described above, except that it is for one nucleus over a range of values for emax and hw.

zheader.sh
    This script removes a specified string of characters from all the existing M0nu header files in the output directory.
    NOTE: editting these header files should be taken with significant precaution!

zlsit.sh
    This script lists all the files from the most recent runs from imsrg++ to the output directory.
    It is dependant on the maintinance of "M0nu_header_ZzzzzNEW.txt" - see ./zrecordit.sh described below.

zMEC.sh
    This is an important script! It combines GT TBMEs with their MECs from imsrg++ output, to be used for M2nu calculations.
    The 'GTfile' and 'MECfile' must have been created by imsrg++ before this script can be executed.
    NOTE: the script doesn't work all the time, given the 'GTfile' and 'MECfile' don't have the same number of entries.
        I should've fixed that... it's why we can't run MECs for phenomenology.
        An obvious fix would be to fill a zero in every blank entry for both 'GTfile' and 'MECfile' but I couldn't think of how to do that nicely in time.

zMECsub.sh
    This just submits a ./zMEC.sh run to the cluster que.

znewrecord.sh
    This (re)starts the M0nu barcode recording process - see ./zrecordit.sh described below.

zoffit.sh
    This will remove all the files with the given M0nu barcode (as the first argument to the script execution) from the imsrg++ output directory.
    Be careful with this sucker! Do you really want to remove those files? I only use this when the run failed and I feel like keeping things organized.

zpitem.sh
    Until you understand this script just by reading it over, I don't think you should use it... hence I won't describe it. ;P

zrecordit.sh
    This records all the existing imsrg++ M0nu output via the header files, and prints to "M0nu_header_ZzzzzRECORD.txt"
    It also records all the new imsrg++ M0nu output compared to the previous M0nu_header_ZzzzzRECORD.txt, and print to "M0nu_header_ZzzzzNEW.txt" (kind of haphazardly).

zswitchit.sh
    This script will add a string in 'switch' to all the M0nu files of a certain barcode (see the first two arguments to the script).
    For example, sometimes I want to change all the files with barcode=abcde from *${barcode}*.* to *${barcode}*_OLD*.*
    The 'place' parameter decides what spot to add in the desired string.

ztransfer.sh
    This script will scp identified GT, F, and T barcode files to oak or cougar, depending on $HOSTNAME.

zunswitchit.sh
    This script will undo the switch made from ./zswitchit.sh described above.

zyes_to_all.sh
    Sometimes I edit these zscripts in the current directory, with 20/20-foresight.
    But I want to keep all the existing zscripts consistent though (see below).
    So this script will empty all the relevant imsrg++ output directories of their versions of the zscripts, and then copy the "base" zscripts (ie, ./z*.sh) over.

zyes_to_base.sh
    Sometimes I edit these zscripts from an imsrg++ output directory, because they're pretty damn janky lol.
    But I want to keep all the existing zscripts consistent though (see above).
    So this script will empty all the "base" zscripts, and then copy over the updated version of the zscripts into this "base" directory.

