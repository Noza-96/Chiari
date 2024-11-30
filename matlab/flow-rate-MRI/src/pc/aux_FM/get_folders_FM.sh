find ../../dat/s101/flow/20240606am-card/dcm -maxdepth 4 -ipath "*/*FM/*" -and \( -name "*FilteredSeries_*" \) > ./aux_FM/folders.txt
sed -i 's|FilteredSeries.*|FilteredSeries|' ./aux_FM/folders.txt
sed -i 's|../../dat/s101/flow/20240606am-card/dcm||' ./aux_FM/folders.txt
sort ./aux_FM/folders.txt -o ./aux_FM/folders.txt
sed -i 's|/||' ./aux_FM/folders.txt

find ../../dat/s101/flow/20240606am-card/dcm -maxdepth 4 -ipath "*/*FM/*" -and \( -name "*FilteredSeries_*" \) > ./aux_FM/folders_.txt
sed -i 's|../../dat/s101/flow/20240606am-card/dcm||' ./aux_FM/folders_.txt
sort ./aux_FM/folders_.txt -o ./aux_FM/folders_.txt
sed -i 's|/||' ./aux_FM/folders_.txt
