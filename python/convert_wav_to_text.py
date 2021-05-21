#!/usr/bin/env python3
from vosk import Model, KaldiRecognizer, SetLogLevel
import sys
import os
import glob
import wave
from pathlib import Path

SetLogLevel(0)

home = str(Path.home())
modelDir = os.path.join(home,"git","callrail_voice_to_text","Data","SpeechModel","model")

if not os.path.exists(modelDir):
    print ("Please download the model from https://alphacephei.com/vosk/models and unpack as 'model' in the folder:" + modelDir)
    exit (1)

model = Model(modelDir)
wavFileDir = os.path.join(home, "git","callrail_voice_to_text","Data","SoundEncodeToWav")
# Establish destination directory, attmept to create the directory  
try:  
    os.mkdir(wavFileDir)
except OSError as error:  
    print(error)

destinationDir = os.path.join(home , "git","callrail_voice_to_text","Data","WavToTextResults")

for wavFile in glob.glob(wavFileDir+"/*.wav"):
    try:
        filePathOut = destinationDir + "/" + os.path.splitext(os.path.basename(wavFile))[0] + ".txt"
        if os.path.exists(filePathOut):
            print("Results allready existed for:" + filePathOut)
            # os.remove(filePathOut)
        else:
            print("Generating results file:" + filePathOut)
            wf = wave.open(wavFile, "rb")
            if wf.getnchannels() != 1 or wf.getsampwidth() != 2 or wf.getcomptype() != "NONE":
                print ("Audio file must be WAV format mono PCM.")
                exit (1)
            rec = KaldiRecognizer(model, wf.getframerate())
            fileOut = open(filePathOut,"a")
            fileOut.write("[\n")
            while True:
                data = wf.readframes(4000)
                if len(data) == 0:
                    break
                if rec.AcceptWaveform(data):
                    fileOut.write( rec.Result() + ",\n")
            fileOut.write('{"end":1}\n]')
            fileOut.close
    except EOFError as error:
        # Output expected EOFErrors.
        print("EOFError occured" )
    except Exception as exception:
        # Output unexpected Exceptions.
        print("unexpected exception occured")
        # Logging.log_exception(exception, False)
