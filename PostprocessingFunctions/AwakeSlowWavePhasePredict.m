function [vars, Graph, EEG] = AwakeSlowWavePhasePredict(EEG, vars, Graph)
% Predicts Fpz phase re-referencing to mastoids and deliver sound when subject is awake
% Includes code for a block design for playing sounds if desired
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
        vars.complatency=zeros(1000000,1); %store times from receiving data chunk to actually playing sound
        %initialize sham times (accidentally labeled 'shim' in variables),times when a 'sham sound' is played); stimtimes are initialized in the llamas app
        vars.shimCount= 1; %keep count of sham sounds
        vars.shimTimes= zeros(1000000,1); %for storing sham time data
        vars.shimcompLatency=zeros(100000,1); %for storing latency of sham played
        %for keeping track of stim block
        vars.ifblock=1;
        %storing stim block data
        vars.ifblocktracker=zeros(100000,1); %track when the block design was on (sounds allowed to play; value=1) vs off
        vars.ifblocktimes=zeros(100000,1); %track times when block design is switched from on to off and vice versa
        vars.ifblocktracker(1)=1;
        vars.ifblocktimes(1)=1;
        vars.countblocks=2;
        vars.currentblocktime=vars.stimblock; %current time of stim block
    end
    if ~isfield(vars, 'b_delta')
        

        vars.TriggerBuffer = EEG.fs; %send stim every second
        
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
            ref=mean(EEG.Recording((vars.currentPosition - vars.SamplesInChunk):vars.currentPosition - 1, 25:26),2); %find the mean of mastoid data
            sample =  EEG.Recording((vars.currentPosition - vars.SamplesInChunk):vars.currentPosition - 1, EEG.PrimaryChannel)-ref; % rereference eeg to mastoid
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
   % PredAngle = angle(Pred{1}(1, end) + sqrt(-1) * Pred{1}(2, end));
%     vars.X(:, vars.currentPosition - 1) = X(:, end, 1, 1);
%     vars.Angles(vars.currentPosition - 1) = PredAngle;
 %   fprintf('hi: %f\n', PredAngle); 
 
       
            if (vars.currentPosition - vars.TriggerBuffer) > vars.LastStimPosition
                %calculate and store mags, movs and delp
              
                      
                      
                if vars.ifblock==1
                   if rand(1) >= vars.shimpercent %only play sound for a preset percentage of time
                      PsychPortAudio('Start', vars.audio_port, vars.repetitions, vars.ChunkTime + vars.SlowWaveDelay, 0);
                      %sound(Sound, fsSound)
                      vars.StimTimes(vars.StimCount) = round(vars.currentPosition + vars.SlowWaveDelay * EEG.fs); %store the stim time
                      vars.complatency(vars.StimCount)= toc(vars.clock); %store the time from chunk delivery to sound playing (the computational latency)
                      vars.StimCount = vars.StimCount + 1;
                      %display values
                      Mag = norm(Pred{1}(:, end));
                      vars.allMags(end+1) = Mag;
                      idx = (vars.currentPosition-EEG.fs*30-1):(vars.currentPosition-1);
                      if idx(1) >= 1
                        delp = mean(envelope(filter(vars.b_delta, vars.a_delta, EEG.Recording(idx,9)), length(idx), 'rms'));
                        vars.alldelps(end+1) = delp;             
                        movs = mean(envelope(filter(vars.b_mov, vars.a_mov, EEG.Recording(idx,9)), length(idx), 'rms'));
                        vars.allmovs(end+1) = movs; 
                        disp('movs is ' + string(movs))
                        disp('delp is ' + string(delp))
                        disp('Mag is ' + string(Mag))
                      end
                      disp(vars.StimCount)
                      toc  
                      vars.LastStimPosition = vars.currentPosition;
                    else
                      disp('Sham! No stim delivered');
                      %store sham times and other sham information
                      vars.shimTimes(vars.shimCount) = round(vars.currentPosition + vars.SlowWaveDelay * EEG.fs);
                      vars.shimcomplatency(vars.shimCount)= toc(vars.clock);
                      vars.shimCount = vars.shimCount + 1;
                      vars.LastStimPosition = vars.currentPosition;      
                   end
                       
                end
            end
          
        if vars.stimblock ~=0 %check that a block design has been set
        if vars.currentPosition-vars.currentblocktime >= 0 %check that the desired block design time has been reached
            if vars.ifblock==1
                vars.ifblock = 0;
                disp('stim turned off');
                %store block design data
                vars.ifblocktracker(vars.countblocks)=0;
                vars.ifblocktimes(vars.countblocks)=vars.currentPosition;
                vars.countblocks=vars.countblocks+1;
                
            else
                vars.ifblock = 1;
                disp('stim turned on');
                vars.ifblocktracker(vars.countblocks)=1;
                vars.ifblocktimes(vars.countblocks)=vars.currentPosition;
                vars.countblocks=vars.countblocks+1;
            end
            vars.currentblocktime = vars.currentblocktime+vars.stimblock;
        end
        end
tic
end
end
