# Dependancies
- Linux, any distro with an apt package manager, like Debian/Ubuntu/Arch
- [Python3](https://www.python.org/downloads/)
- [R](cran.r-project.org/)

# Credentials 
APIs keys are in the [Credentials Directory](/Credentials), update the dumy values to yours from call rail.

Treat API Keys as passwords because they are.

# callrail_voice_to_text project
Using the call rail api to pull down the audio for all calls, then use a vosk speech to [text model](https://alphacephei.com/vosk/models/vosk-model-en-us-aspire-0.2.zip) from to translate to text, and export all to a spreadsheet.

Later versions could use machine learning to determine the likleyhood of calls being categorized as leads, and lead categorization, ignore, feedback.

# APIs
## Call Rail documentation:
- https://apidocs.callrail.com/#conventions

##  Speech to text framework and model used
[VOSK](https://alphacephei.com/vosk/models)
Scripts currently configured so that transcriptions are created with model
[vosk-model-en-us-aspire-0.2](https://alphacephei.com/vosk/models/vosk-model-en-us-aspire-0.2.zip)
Other models can be swapped out, like this other model as it's generic accuracy is claimed to be a bit better:
[vosk-model-en-us-daanzu-20200905](https://alphacephei.com/vosk/models/vosk-model-en-us-daanzu-20200905.zip)

To use a new model, download and unziped in the directory: Data/SpeechModel then renamed to "Data/SpeechModel/model"

## Setup and Usage
### On Windows 10
machine setup a debian or ubuntu instance of [Windows subsystem for linux terminal](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

### First Run
 - Establish a [ssh key]|(https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/connecting-to-github-with-ssh) on github for this project
 - From the Linux Terminal run these commands
**) 
```
cd ~/
mkdir git
cd git
git clone git@github.com:seakintruth/callrail_voice_to_text_transcription.git
```

### From the Linux Termial
Run the startup script: 
```
~/git/callrail_voice_to_text/Startup/startup.sh
```

### The speech to text Reports are generated here:
- [Reports/PreviousMonth-Transcribed.xlsx](Reports/PreviousMonth-Transcribed.xlsx)
- [Reports/AllTime-Transcribed.xlsx](Reports/AllTime-Transcribed.xlsx)
