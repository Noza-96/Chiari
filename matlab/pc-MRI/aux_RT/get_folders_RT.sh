find ../../../patient-data/s101_aa/flow -maxdepth 4 -ipath "*/*RT/*" -and \( -name "*_P_*" -or -name "*_P" \) > ./aux_RT/folders.txt
sed -i 's|_P.*||' ./aux_RT/folders.txt
sed -i 's|../../../patient-data/s101_aa/flow||' ./aux_RT/folders.txt
sort ./aux_RT/folders.txt -o ./aux_RT/folders.txt
sed -i 's|/||' ./aux_RT/folders.txt

find ../../../patient-data/s101_aa/flow -maxdepth 4 -ipath "*/*RT/*" -and \( -name "*_*" ! -name "*_P_*" ! -name "*_P" ! -name "*_MAG_*" ! -name "*_MAG" ! -name "*DS_Store*" \) > ./aux_RT/folders_.txt
sed -i 's|../../../patient-data/s101_aa/flow||' ./aux_RT/folders_.txt
sort ./aux_RT/folders_.txt -o ./aux_RT/folders_.txt
sed -i 's|/||' ./aux_RT/folders_.txt

find ../../../patient-data/s101_aa/flow -maxdepth 4 -ipath "*/*RT/*" -and \( -name "*_MAG_*" -or -name "*_MAG" \) > ./aux_RT/folders_MAG.txt
sed -i 's|../../../patient-data/s101_aa/flow||' ./aux_RT/folders_MAG.txt
sort ./aux_RT/folders_MAG.txt -o ./aux_RT/folders_MAG.txt
sed -i 's|/||' ./aux_RT/folders_MAG.txt

find ../../../patient-data/s101_aa/flow -maxdepth 4 -ipath "*/*RT/*" -and \( -name "*_P_*" -or -name "*_P" \) > ./aux_RT/folders_P.txt
sed -i 's|../../../patient-data/s101_aa/flow||' ./aux_RT/folders_P.txt
sort ./aux_RT/folders_P.txt -o ./aux_RT/folders_P.txt
sed -i 's|/||' ./aux_RT/folders_P.txt
