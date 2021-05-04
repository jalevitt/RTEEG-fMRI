function [vars] = SlowWavePhasePredict(EEG, vars)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if ~isfield(vars, 'PhasePredictor')
    load('LSTM2_shift_35ms.mat')
    vars.PhasePredictor = PhaseNet;
    vars.SlowWaveDelay = .035;
end
if vars.UseSlowWaveStim && vars.SamplesInChunk > 0 
    if ~vars.UseKalman
        sample =  EEG.Recording((vars.currentPosition - vars.SamplesInChunk)-1:vars.currentPosition - 1, EEG.PrimaryChannel);
    else
        sample =  EEG.Kalman_Signal((vars.currentPosition - vars.SamplesInChunk)-1:vars.currentPosition - 1, EEG.PrimaryChannel);
    end
    [FiltSample, vars.z] = filter(vars.b, vars.a, sample(2:end), vars.z);
    X = zeros(3, length(sample) - 1, 1, 1);
    X(1, :, 1, 1) = sample(2:end);
    X(2, :, 1, 1) = diff(sample);
    X(3, :, 1, 1) = FiltSample;
    [vars.PhasePredictor, Pred] = predictAndUpdateState(vars.PhasePredictor, {X});
    PredAngle = angle(Pred{1}(1, end) + sqrt(-1) * Pred{1}(2, end));
    Mag = norm(Pred{1}(:, end)); 
    if (vars.currentPosition - vars.TriggerBuffer) > vars.LastStimPosition
        if Mag > EEG.Threshold && (PredAngle > -pi/10 && PredAngle < p/10)
            PsychPortAudio('Start', vars.audio_port, vars.repetitions, vars.ChunkTime + vars.SlowWaveDelay, 0);
            %sound(Sound, fsSound)
            vars.StimTimes(vars.StimCount) = vars.currentPosition;
            vars.StimCount = vars.StimCount + 1;
            vars.LastStimPosition = vars.currentPosition;
        end
    end
end
end