# EEG-LLAMAS

EEG-LLAMAS (Low-Latency Artifact Mitigation Acquisition Software) is an
open-source platform intended to enable neurofeedback experiments using 
EEG-fMRI by removing BCG and Gradient artifacts in real time. BCG 
artifacts are removed using a unique Kalman filter based algorithm. 
(https://www.biorxiv.org/content/10.1101/2022.11.21.515651v2)
(https://pubmed.ncbi.nlm.nih.gov/37028736/)

Can also be used to collect EEG neurofeedback outside of the scanner.

To begin, open EEG_LLAMAS.mlapp and press run, or type 
EEG_LLAMAS into your command window. Check all settings in the main 
UI, the press 'Open Settings' and set the advanced settings. Then press 
'begin recording'. If everything is set up properly, you should begin 
streaming data in ~10 seconds or so. 

There are a few example postprocessing functions in the 'PostProcessing' 
directory to give you sense of the kind of things you can do with this app. 
But you can design your own functions to meet the needs of your experiment. 
Just create your stimuli functions, and add them to the postprocessing 
folder. Then, they will show up as options in the Setting UI.
Just make sure the header of your funtions follow the format:
[vars, Graph, EEG] = MyFunc(EEG, vars, Graph)

This app is currently optimized to work with 64 channel Braincap MR 
headsets, but can be adapted for other hardware.

For detailed instructions on how to use EEG-LLAMAS, please see the wiki: https://github.com/jalevitt/EEG-LLAMAS/wiki

EEG-LLAMAS is dependent upon Labstreaminglayer and PsychToolbox.

Under development by Joshua Levitt of the Lewis Neuro lab at MIT.
For more info, please communicate either via Github or by email at 
JaLevitt@mit.edu
