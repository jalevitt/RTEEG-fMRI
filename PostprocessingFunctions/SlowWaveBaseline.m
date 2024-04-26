function [vars, Graph, EEG] = SlowWaveBaseline(EEG, vars, Graph)
% obtain baseline measures for slow wave stim

if vars.SamplesInChunk > 0 
    if ~isfield(vars, 'PhasePredictor')
        addpath('/home/lewislab/Desktop/EEG-LLAMAS-add_function/EEG-LLAMAS/PhasePredictors');
        if EEG.PrimaryChannel == 17
            fprintf('loading Fpz predictor...')
            load('03-30-2023 12-38_FpZ_3subs_mastoids_trainall.mat', 'results');
        elseif EEG.PrimaryChannel == 6
            fprintf('loading C4 predictor...')
            load('03-29-2023 16-55_C4_3subs_mastoids_trainall.mat', 'results');
        else
            fprintf('WARNING! NO PREDICTOR FOR THIS CHANNEL')
        end
        vars.PhasePredictor = resetState(results(1).net);
        vars.SlowWaveDelay = .000;
        vars.Angles = zeros(1000000, 1);
        vars.X = zeros(3, 1000000);
       
    end
    if ~isfield(vars, 'b_delta')
        
       
        vars.TriggerBuffer = EEG.fs*2.5; %at least 2.5 seconds between each data calculation
        
        vars.allMags = 0;
        vars.alldelps = 0;
        vars.allmovs = 0;
        
        
        BandPass_SlowWave= designfilt('bandpassiir', ...
            'PassbandFrequency1', 0.4, ...
            'Passbandfrequency2', 2, ...
            'StopbandFrequency1', 0.01,...
            'StopbandFrequency2', 6, ...
            'StopbandAttenuation1', 20, ...
            'StopbandAttenuation2', 20, ...
            'PassbandRipple', 1, ...
            'DesignMethod', 'butter', ...
            'SampleRate', 200);

        [vars.b, vars.a] = tf(BandPass_SlowWave);
        
        delta_filter = designfilt('bandpassiir', ...
            'PassbandFrequency1', 1, ... 
            'Passbandfrequency2', 4, ... 
            'StopbandFrequency1', .01,...
            'StopbandFrequency2', 9, ...
            'StopbandAttenuation1', 20, ...
            'StopbandAttenuation2', 20, ...
            'PassbandRipple', 1, ...
            'DesignMethod', 'butter', ...
            'SampleRate', EEG.fs);
        [vars.b_delta, vars.a_delta] = tf(delta_filter);
        
        mov_filter = designfilt('highpassiir', ...
            'PassbandFrequency',20, ... 
            'StopbandFrequency', 5,...
            'StopbandAttenuation', 30, ...
            'PassbandRipple', 1, ...
            'DesignMethod', 'butter', ...
            'SampleRate', EEG.fs);
        [vars.b_mov, vars.a_mov] = tf(mov_filter);
        
        hp_filter = designfilt('highpassiir', ...
            'PassbandFrequency', 0.4, ... 
            'StopbandFrequency', 0.01,...
            'StopbandAttenuation', 40, ...
            'PassbandRipple', 0.1, ...
            'DesignMethod', 'butter', ...
            'SampleRate', EEG.fs);
        [vars.b_hp, vars.a_hp] = tf(hp_filter);
        vars.zhp = zeros(6,1); %filter initial conditions  
        
        
    end
    if ~vars.UseKalman
        if(vars.currentPosition - vars.SamplesInChunk)-1 <= 0
        %rereference eeg data to the mastoids
            ref=mean(EEG.Recording((vars.currentPosition - vars.SamplesInChunk):vars.currentPosition - 1, 25:26),2);
            sample =  EEG.Recording((vars.currentPosition - vars.SamplesInChunk):vars.currentPosition - 1, EEG.PrimaryChannel)-ref;
            sample = [0; sample];
        else
            ref=mean(EEG.Recording((vars.currentPosition - vars.SamplesInChunk)-1:vars.currentPosition - 1, 25:26),2);
            sample =  EEG.Recording((vars.currentPosition - vars.SamplesInChunk)-1:vars.currentPosition - 1, EEG.PrimaryChannel)-ref;
        end
    else
        if(vars.currentPosition - vars.SamplesInChunk)-1 <= 0
            ref = mean(EEG.Kalman_Signal((vars.currentPosition - vars.SamplesInChunk):vars.currentPosition - 1,25:26),2);
            sample =  EEG.Kalman_Signal((vars.currentPosition - vars.SamplesInChunk):vars.currentPosition - 1, EEG.KalmanPrimary)-ref;
            sample = [0; sample];
        else
            ref=mean(EEG.Kalman_Signal((vars.currentPosition - vars.SamplesInChunk)-1:vars.currentPosition - 1, 25:26),2);
            sample =  EEG.Kalman_Signal((vars.currentPosition - vars.SamplesInChunk)-1:vars.currentPosition - 1, EEG.KalmanPrimary)-ref;
        end
    end
    
%     [sample, vars.zhp] = filter(vars.b_hp, vars.a_hp, sample(2:end), vars.zhp);
%     sample = [0; sample];
    [FiltSample, vars.z] = filter(vars.b, vars.a, sample(2:end), vars.zhp); 
    vars.zhp=vars.z; 
    X = zeros(3, length(sample) - 1, 1, 1);
    X(1, :, 1, 1) = sample(2:end);
    X(2, :, 1, 1) = diff(sample);
    X(3, :, 1, 1) = FiltSample;
    
    [vars.PhasePredictor, Pred] = predictAndUpdateState(vars.PhasePredictor, {X});
    %PredAngle = angle(Pred{1}(1, end) + sqrt(-1) * Pred{1}(2, end));    
    if (vars.currentPosition - vars.TriggerBuffer) > vars.LastStimPosition
        
        Mag = norm(Pred{1}(:, end));
        vars.allMags(end+1) = Mag;
        idx = (vars.currentPosition-EEG.fs*30-1):(vars.currentPosition-1);
        if idx(1) >= 1
        delp = mean(envelope(filter(vars.b_delta, vars.a_delta, EEG.Recording(idx,9)), length(idx), 'rms'));
        vars.alldelps(end+1) = delp;

         movs = mean(envelope(filter(vars.b_mov, vars.a_mov, EEG.Recording(idx,9)), length(idx), 'rms'));
         vars.allmovs(end+1) = movs; 
         disp('delp is ' + string(delp) + ', movs is ' + string(movs) + ' and mags is ' + string(Mag))
        end
                    
          
          
          vars.LastStimPosition=vars.currentPosition;          
         
   end
end

end
