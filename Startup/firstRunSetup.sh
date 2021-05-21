#!/usr/bin/env bash
sudo apt update

# This takes too much compute time...
# sudo apt upgrade -y

MISC="r-base python3-pydub ffmpeg libavcodec-extra58"
WEB="curl libcurl4-openssl-dev"

for pkg in $MISC $WEB; do
    if dpkg --get-selections | grep -q "^$pkg[[:space:]]*install$" >/dev/null; then
        echo -e "$pkg is already installed"
    else
	if sudo apt-get -qq install $pkg; then
	    echo "Successfully installed $pkg"
	else
	    echo "Error installing $pkg"
	fi
    fi
done
pip3 install vosk
pip3 install pydub

#cd vosk-api/python/example
#wget https://alphacephei.com/vosk/models/vosk-model-en-us-aspire-0.2.zip
#unzip vosk-model-en-us-aspire-0.2.zip
#mv vosk-model-en-us-aspire-0.2 model
#python3 ./test_simple.py test.wav

# run the R script
/usr/bin/Rscript ~/git/callrail_voice_to_text/R/GetCalls.R
# if this script can't find credentials it uses the script LoadApiKey.R

# run the python scripts
python3 ~/git/callrail_voice_to_text/python/convert_mp3_to_wav.py
python3 ~/git/callrail_voice_to_text/python/convert_wav_to_text.py

# run the last R script
/usr/bin/Rscript ~/git/callrail_voice_to_text/R/LoadText.R

cd ~/git/callrail_voice_to_text

# push updates to github
git add . && git commit -m "data updates" && git push origin HEAD
