%% Example of using function estTimeConstant for estimation of strength-
%% duration time constant and rheobase.
% See details inestTimeConstant.m
%
% AUTHOR:		Angel Peterchev, Aman Aberra (c) 2005-2024 
% VERSION:		08/23/2024

%% Load data

% Load motor threhold data
% example motor threshold data for cTMS1 pulses with PW = 30, 60, 120 us
pw = [30 60 120];
mt = [90.39130435 56.30434783 41.60869565]; % [%MSO] (cTMS1 has 120% Magstin Rapid MSO max output) average MTs for 23 for PW = 30, 60, 120 us (Peterchev et al 2013 Clin Neurophys)

% Load waveform data
load ctms1_wvfrm_11_26_2008.mat      % load cTMS E-field waveforms
wvfrm_all = ctms1_wvfrm;
fs = wvfrm_all.fs;                 % sampling frequency [Hz]
t = wvfrm_all.t;                   % time vector
i_pw = find(sum(wvfrm_all.pw' == pw,2));  % PW index
pw = wvfrm_all.pw(:,i_pw);         % PW [us]
wvfrms = wvfrm_all.wvfrm(:,i_pw);  % waveform array

%% Estimate time constant

opts = struct(); % structure used for specifying optional arguments, 
                 % pass in after default arguments
opts.tau_m0 = 200e-6;   % neural time constant initial value (guess)
opts.tau_m_lb = opts.tau_m0/100;  % neural time constant low bound
opts.tau_m_ub = opts.tau_m0*100;   % neural time constant upper bound
opts.mt_b0 = min(mt)/2;            % rheobase initial value (guess)
opts.mt_b_lb = opts.mt_b0/100;     % rheobase lower bound
opts.mt_b_ub = opts.mt_b0*100;    % rheobase upper bound
opts.display = 'final-detailed'; % 'off', 'none', 'final', 'final-detailed', 'iter',
                        % or 'iter-detailed'
[tau,rb,resnorm] = estTimeConstant(mt,fs,wvfrms,opts);

%% Plotting

% Plot E-field waveforms
fig = figure(1); 
ax = subplot(2,1,1);
plot(ax,t*1e6,wvfrms); 
xlabel(ax,'Time (\mus)'); ylabel(ax,'E-field (norm.)'); 
title(ax,'E-field pulse waveforms');

% Plot neural time constant and rheobase
ax2 = subplot(2,1,2); 
plot(ax2,pw,mt,'-o'); 
xlabel(ax2,'Pulse width (\mus)'); ylabel(ax2,'Threshold (%MSO)'); 
title(ax2,sprintf('Time constant = %.3f \\mus, Rheobase = %.3f %%MO, |Residual|^2 = %.3f',tau,rb,resnorm));