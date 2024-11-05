function [tau,rb,resnorm] = estTimeConstant(mt,fs,wvfrms,varargin)
%% ESTTIMECONSTANT Estimate time constant using method of Peterchev et al.
%% 2013 (lsqcurvefit)
%  
%   Inputs 
%   ------ 
%   mt : vector
%        threshold values, same size as pws
%   fs : scalar
%        sampling frequency in Hz of waveform
%   wvfrms : array
%            num_timepoints x num_pws array of waveform recordings 
%   Optional Inputs 
%   --------------- 
%   tau_m0 : double
%            starting point for time constant estimation in sec
%   tau_m_lb : double
%              lower bound for time constant estimation in sec
%   tau_m_ub : double
%              upper bound for time constant estimation in sec
%   mt_b0 : double
%           starting point for estimation of rheobase (same units as mt)
%   mt_b_lb : double
%             lower bound for rheobase estimation
%   mt_b_ub : double
%             upper bound for rheobase estimation
%   Outputs 
%   ------- 
%   tau : double
%         time constant estimation in µs
%   rb : double
%        rheobase amplitude estimation in same units as mt
%   resnorm : double
%             squared norm of residual, output of lsqcurvefit
%   Examples 
%   --------------- 
%
%
% OBJECTIVE:
% The objective of this code is to estimate the strength-duration (SD) time
% constant and rheobase from cTMS neural strength-duration curve data
% for a single subject. 
% 
% BACKGROUND:
% Peterchev et al. 2013 used two methods for estimation of the
% strength-duration time constant with cTMS. The first approach,
% implemented here, estimates individual SD time constant and rheobase for
% each subject. Thus, the two parameters are estimated independently of
% those for any other subjects. 
% 
% INSTRUCTIONS:
% Run file estTimeConstant_example_cTMS.m for example use. 
% 
% The recorded E-field waveforms are in data array ctms1_wvfrm.wvfrm in
% example file ctms1_wvfrm_11_26_2008.mat.
% 
% One needs to use recordings of the electric field (E-field) pulse
% waveform used in the specific device and study. The waveform should then
% be stored in MATLAB in the same way as the ctms1_wvfrm structure. The
% E-field waveforms may have to be preprocessed to ensure two things:
% 1) the baseline before the pulse is zero mean, and
% 2) the peak amplitude of the E-field waveforms (excluding small transient
% switching spikes) is the same across all waveforms and is normalized to
% unity (1). 
% 
% The example is for 3 waveform (pulse width) conditions, but can be
% extended to more than three conditions.
% 
% REFERENCES:
% 
% Peterchev AV, Goetz SM, Westin GG, Luber B, Lisanby SH. Pulse width
% dependence of motor threshold and input-output curve characterized with
% controllable pulse parameter transcranial magnetic stimulation. Clin
% Neurophysiol. 2013 Jul;124(7):1364-72.
% doi: https://doi.org/10.1016/j.clinph.2013.01.011
% 
% Menon, P., Pavey, N., Aberra, A. S., van den Bos, M. A. J., Wang, R.,
% Kiernan, M. C., Peterchev, A. V.*, and Vucic, S.* Dependence of cortical
% neuronal strength-duration properties on TMS pulse shape. Clin
% Neurophysiol 2023; 150: 106-118 * equal contribution.
% doi: https://doi.org/10.1016/j.clinph.2023.03.012
%
% AUTHORS:	Aman Aberra, Angel Peterchev, (c) 2005-2024 
% VERSION:	08/23/2024

% For lsqcurve fitting - input parameters
in.tau_m0 = 200e-6;				% [sec] neural time constant initial value (guess)
in.tau_m_lb = in.tau_m0/100;  % neural time constant low bound
in.tau_m_ub = in.tau_m0*100;   % neural time constant upper bound
in.mt_b0 = min(mt)/2;            % [% MSO] rheobase initial value (guess)
in.mt_b_lb = in.mt_b0/100;     % rheobase lower bound
in.mt_b_ub = in.mt_b0*100;    % rheobase upper bound
in.display = 'final'; % 'off', 'none', 'final', 'final-detailed', 'iter', or 'iter-detailed'
in = sl.in.processVarargin(in,varargin); 
if isrow(mt)
    mt = mt'; 
end
options = optimoptions(@lsqcurvefit,'MaxFunEvals',2e3,...
                       'Algorithm','trust-region-reflective',...
                        'Display',in.display);
[param,resnorm,residual,exitflag,output,lambda,jacobian] = lsqcurvefit(@mt_mtcalc,...
                [in.tau_m0,in.mt_b0],wvfrms,ones(size(mt)),[in.tau_m_lb,in.mt_b_lb],...
                [in.tau_m_ub,in.mt_b_ub],options);
tau = param(1)*1e6; % time constant in us
rb = param(2); % rheobase
       
    function mt_mt = mt_mtcalc(param,wvfrms) % outputs ratio of model threshold to target threshold (closer to 1 is better)
        % param(1) = membrane time const. (tau_m)
        % param(2) = depolarization threshold volt. relative to pulse amplitude (%)
        %           (rheobase)
        % wvfrms = matrix of waveforms in columns
        % fs
        tau_m = param(1);   % membrane time const.
        mt_b = param(2);    % depolarization threshold volt. relative to pulse amplitude (%)
        b = 1/(1+2*tau_m*fs).*[1 1];                % coefficients of low pass filter modeling neural memebrane 
        a = [1 (1-2*tau_m*fs)/(1+2*tau_m*fs)];      % coefficients of low pass filter modeling neural memebrane      
        mt_mt = (mt_b./max(filter(b,a,wvfrms),[],1)')./mt;
    end

end