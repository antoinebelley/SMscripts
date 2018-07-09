All files/code/etc in this repository obey the following Copyright:
Copyright (c) Charlie Payne, 2016-2018

goM0nu.sh
    execution Ex1) ./goM0nu.sh 20 48 BARE fppn gx1apn none 4 10.49 s12 lfpnk cfzwc zzzzz
    execution Ex2) ./goM0nu.sh 20 48 MAGNUS IMSRGfp magic magic 10 16 s12 kisvb zzzzz zfrvk
    execution Ex3) ./goM0nu.sh 20 48 -x testing MAGNUS IMSRGfp magic magic 10 16 s12 kisvb itxbb zfrvk
    execution Ex4) ./goM0nu.sh 20 48 -o on HYBRID fppn gx1apn none 10 16 s12 kisvb itxbb zfrvk
    --------
    The last three arguments to the script are GT, F, and T barcodes (respectively), which allows the script to find the imsrg++ output (see the 'imaout' variable).
    Said imsrg++ output must have been calculated by executing imsrg++ (see /home/cgpayne/cougwork/imsrg_code/ragnar_imsrg/work/scripts) before using this script.
    To skip a certain GT, F, and/or T calculation, use "zzzzz" instead of an actual barcode (entering an invalid barcode will trigger an ERROR).
    See the script header info for descriptions of the options: -u (usage), -h (help), -o (override), and -x (extra).
    --------
    This script is noted out pretty well -> read all of it!
    It will take 0vbb output from imsrg++ (see the 'imaout' variable) and run nushellx/nutbar to calculate a final neutrinoless double-beta decay NME result.
    To execute this script properly, it must live in the ShellModel directory (for instance, my raw data is stored in /itch/cgpayne/SMcalc/M0nu, mmmmkay).
    You'll execute the script, via terminal, from said directory - not from this current directory!
    Since the script runs nushellx, and that sucker outputs a lot of data to memory, it should be in a scratch/itch directory (with a lot of empty sotrage).
    I just keep this script here (consistently updated with all my other copies of the same script) so that it gets backed up when I back up cougwork.
    I'm really happy I kept it here though, considering my /itch directory got fully destoryed in the dreaful cougar reboot of early 2018, just weeks before my thesis was due!
    Since the runs necessary to do these calculations are heafty (depending on the chosen nucleus and valence space), they are submitted to the cluster que SEQUENTIALLY.
    Hence, argument ${9} of ./nuqsub.sh (see script description below) will be used accordingly.
    This script also outputs a script which can be used to copy the final NME results to a (preferably secure and commonly backed up) local directory (see the 'imamyr' variable).
    NOTE: some of the script arguments are for labelling purposes, but make sure everything's consistent with the imsrg++ output files upon execution!
    NOTE: it is CRITICAL that the M0nu file output from imsrg++ have the "barcode" functionality in place for this script to work.
    NOTE: the analog to "goM0nu.sh" for M2nu = "nuM2nu.sh" + "sumM2nu.sh"

nuM2nu.sh
    execution Ex1) ./nuM2nu.sh 20 48 BARE OS fppn gx1apn none 4 10.49 QQQQQ 250
    execution Ex2) ./nuM2nu.sh 20 48 MAGNUS 3N IMSRGfp magic magic 10 16 Q0QQQ 250 MEC
    The "QQQQQ" argument is used to specify which stages (1-5, read the script header info) will be qued, and which will be skipped (designated by a "0").
    For instance, in Ex2 stages 1, 3, 4, and 5 are run, whereas stage 2 is skipped.
    Like ./goM0nu.sh, imsrg++ output must have been calculated by executing imsrg++ (see /home/cgpayne/cougwork/imsrg_code/ragnar_imsrg/work/scripts) before using this script.
    --------
    This script is noted out pretty well -> read all of it!
    It is meant to be run before ./sumM2nu.sh (see description below).
    It will take standard GT output (for 2vbb) from imsrg++ (see the 'imaout' variable) and run nushellx/nutbar to calculate Gamow-Teller NMEs,
        which are used in ./sumM2nu.sh to get two-neutrino double-beta decay NMEs.
    To execute this script properly, it must live in the ShellModel directory (for instance, my raw data is stored in /itch/cgpayne/SMcalc/M2nu, mmmmkay).
    You'll execute the script, via terminal, from said directory - not from this current directory!
    Since the script runs nushellx, and that sucker outputs a lot of data to memory, it should be in a scratch/itch directory (with a lot of empty sotrage).
    I just keep this script here (consistently updated with all my other copies of the same script) so that it gets backed up when I back up cougwork.
    I'm really happy I kept it here though, considering my /itch directory got fully destoryed in the dreaful cougar reboot of early 2018, just weeks before my thesis was due!
    Since the runs necessary to do these calculations are heafty (depending on the chosen nucleus and valence space), they are submitted to the cluster que SEQUENTIALLY.
    Hence, argument ${9} of ./nuqsub.sh (see script description below) will be used accordingly.
    NOTE: some of the script arguments are for labelling purposes, but make sure everything's consistent with the imsrg++ output files upon execution!
    NOTE: to run with MECs, the GT+MEC output from imsrg++ must have already been calculated (see ./zscripts/zMEC.sh and ./zscripts/zMECsub.sh).
        That is, a single file including both GT OBMEs + GTMEC OBMEs must exist (which can be created via ./zscripts/zMEC.sh) before this script can be used with the 'mecopt' option.

nuqsub.sh
    execution Ex1) ./nuqsub.sh "bash -c \". ca48.bat\"" ca48 "M0nu_nushx_hw16_e10" batchmpi 144 12 60 12
    execution Ex2) ./nuqsub.sh "nutbar nutbar_ca480.input" nutbar_ca480 "M0nu_hw16_e10_kisvb_GT" debug 144 12 60 12 912322
    The first argument should always be in double-quotes, and the second and third arguments only require quotes if they have spaces in them (I do them sometimes anyways, just in case).
    If the nineth argument is non-empty, the job will be put on hold (H) on the que until the given qsub id (ie, the argument value) has finished running.
    --------
    This script is noted out pretty well -> read all of it!
    It is a simple script that submits jobs to the cluster que using PBS.
    To get a good grip of what's required to run the script, read over the script argument descriptions.
    Argument ${9} can be used to hold (H) a run on the que and wait until a certain job on the cluster has completed before being qued (Q) for running (R).
    I orginally wrote it to submit nushellx and nutbar runs, hence naming it with 'nu', but now it's general for whatever run.
    NOTE: to make a PBS submission, this script makes a PBS script called 'mypbsfile', which is then executed.

sumM2nu.sh
    execution Ex1) ./sumM2nu.sh 20 48 M2nu_BARE_OS_fppn_gx1apn_none_e4_hw10.49_neig250 max def lit
    execution Ex2) ./sumM2nu.sh 20 48 M2nu_MAGNUS_3N_IMSRGfp_magic_magic_e10_hw16_neig250 max def mine abin
    The sixth argument decides whether or not to use the literature convention or my convention for "X" in Equation (7.1) in my thesis.
    The seventh argument decides whether or not to run with an experimental correction to the lowest lying 1+ state, or fully ab-initio (see Equation (7.1) in my thesis).
    --------
    This script is noted out pretty well -> read all of it!
    After running ./nuM2nu.sh (see description above) properly, this script will sum up all the relevant GT NMEs into a two-neutrino double-beta decay NME result.
    Probably the most technical option is whether or not you want to run "fully ab initio" or "energy corrected" - see the 'abinopt' arguement.
    For an explicit example of what I mean, see Equation (7.1) of my thesis.
    The final results of the summation of these GT NMEs into a M2nu NME is printed out to the 'outfile' aight.
    Copying the final NME results to a (preferably secure and commonly backed up) local directory was done manually.
    I meant to write a script to copy the appropriate stuff over automatically, but something silly got in the way, and I ran out of time.
    NOTE: I found that no queing of runs was necessary for these calculations, it's just done via terminal.
    NOTE: both results with and without a quenching factor are calculated, so don't panic about chosing a 'qf' if you don't care about it (you can always set it to 1 if you're paranoid).

updem.sh
    This script updates the M0nu and M2nu scripts in the relevant directories, dependant on the hostname (cougar or oak).

zscripts/
    This directory holds some quick bash scripts that I found useful for my imsrg++ output directories.
    I called them 'zscripts' because they all start with 'z' so that they'll appear at the bottom (grouped together) from other *.dat and *.txt files and such.
    I don't really know why I put this directory here... it made sense at the time. :S

zz_bash_strnum/
    In order to manipulate numbers in files and make bash do decimal arithmetic, I had to make these sucky functions using sed and bc and stuff.
    Since said functions became useful for many bash scripts, I keep them updated in a skeleton file for copy/paste purposes.
    This directory holds that skeleton file in ./zz_bash_strnum/strnum.sh
    I don't really know why I put this directory here... it made sense at the time. :S

zzz_OLD/
    This holds old versions of all the current ./*.sh
    It's not super useful other than for debugging and such.
    I'm pretty sure the newer versions will be more useful like 99% of time.
    The "com" is for the three M2nu scripts being 'compatible' mmmkay.

