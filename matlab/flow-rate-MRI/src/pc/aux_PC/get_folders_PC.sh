find ../../dat/s101/flow/before/dcm -maxdepth 4 -ipath "*/*PC/*" -and \( -name "*_P_*" -or -name "*_P" \) > ./aux_PC/folders.txt
sed -i 's|_P.*||' ./aux_PC/folders.txt
sed -i 's|../../dat/s101/flow/before/dcm||' ./aux_PC/folders.txt
sort ./aux_PC/folders.txt -o ./aux_PC/folders.txt
sed -i 's|/||' ./aux_PC/folders.txt

find ../../dat/s101/flow/before/dcm -maxdepth 4 -ipath "*/*PC/*" -and \( -name "*_*" ! -name "*_P_*" ! -name "*_P" ! -name "*_MAG_*" ! -name "*_MAG" ! -name "*DS_Store*" \) > ./aux_PC/folders_.txt
sed -i 's|../../dat/s101/flow/before/dcm||' ./aux_PC/folders_.txt
sort ./aux_PC/folders_.txt -o ./aux_PC/folders_.txt
sed -i 's|/||' ./aux_PC/folders_.txt

find ../../dat/s101/flow/before/dcm -maxdepth 4 -ipath "*/*PC/*" -and \( -name "*_MAG_*" -or -name "*_MAG" \) > ./aux_PC/folders_MAG.txt
sed -i 's|../../dat/s101/flow/before/dcm||' ./aux_PC/folders_MAG.txt
sort ./aux_PC/folders_MAG.txt -o ./aux_PC/folders_MAG.txt
sed -i 's|/||' ./aux_PC/folders_MAG.txt

find ../../dat/s101/flow/before/dcm -maxdepth 4 -ipath "*/*PC/*" -and \( -name "*_P_*" -or -name "*_P" \) > ./aux_PC/folders_P.txt
sed -i 's|../../dat/s101/flow/before/dcm||' ./aux_PC/folders_P.txt
sort ./aux_PC/folders_P.txt -o ./aux_PC/folders_P.txt
sed -i 's|/||' ./aux_PC/folders_P.txt
