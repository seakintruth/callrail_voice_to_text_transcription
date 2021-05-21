import glob
import os
from pathlib import Path
from pydub import AudioSegment

home = str(Path.home())
sourceDir = os.path.join(home , "git","callrail_voice_to_text","Data","SoundAssets")

if not os.path.exists(sourceDir):
    print ("The expected source directory was expected at:" + sourceDir)
    exit (1)

destinationDir = os.path.join(home , "git","callrail_voice_to_text","Data","SoundEncodeToWav")
# Establish destination directory, attmept to create the directory  
try:  
    os.mkdir(destinationDir)
except OSError as error:  
    print(error)

for sourceFile in glob.glob(sourceDir+"/*.mp3"):
    destinationFilePath = destinationDir + "/" + os.path.splitext(os.path.basename(sourceFile))[0] + ".wav"
    if os.path.exists(destinationFilePath):
        print("Converted destination allready exists:" + destinationFilePath)
    else:
        sound = AudioSegment.from_mp3(sourceFile)
        sound.export(destinationFilePath,format="wav", parameters=["-bitexact","-acodec","pcm_s16le"])
        print("Created destination file:" + destinationFilePath)
