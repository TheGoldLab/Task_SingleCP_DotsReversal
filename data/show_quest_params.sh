#!/bin/bash
pilot15="2019_04_29_11_04" 
pilot16="2019_04_29_14_07"
pilot17="2019_04_30_10_33"
pilot18="2019_04_30_14_54"
pilot19="2019_04_30_15_51"

dataPath="SingleCP_DotsReversal/raw"

i=15
for pilot in $pilot15 $pilot16 $pilot17 $pilot18 $pilot19 
do
  echo "pilot $i"
  grep --color -A2 psiParamsQuest "$dataPath/$pilot/consoleDump_$pilot.log"
  i=$(($i+1))
done
