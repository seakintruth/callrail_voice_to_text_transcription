#!/usr/bin/env bash

# run the R script
/usr/bin/Rscript ../R/GetCalls.R
# if this script can't find credentials it uses the script LoadApiKey.R

# run the python scripts
python3 ../python/convert_mp3_to_wav.py
python3 ../python/convert_wav_to_text.py

# run the last R script
/usr/bin/Rscript ../R/LoadText.R

cd ../

# push updates to github
git add . && git commit -m "data updates" && git push origin HEAD
