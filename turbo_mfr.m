function [iat, mfr_turbo_max, power_max, inj_flow_max] = turbo_mfr(eta_comp, max_boost)

% [iat, mfr_turbo_max, power_max, inj_flow_max] = turbo_mfr(eta_comp,
                % max_boost)

% Check if variables already exist. Assign standard values if not              
p_amb_abs = 14.7; % Sea level pressure
t_amb = 85; % Standard temperature
displ = 3000; % 2JZ-GE engine displacement
cyl_num = 6; % 2JZ-GE cylinder number
VE = .85; % Average VE
pre_press_drop = .2; % Pressure drop across compressor intake piping
post_press_drop = 1; % Pressure drop across charge piping and I/C
eta_ic = .8; % Intercooler efficiency
ic_temp = 34; % I/C cooling temp in deg F
bsfc = .65; % Brake-specific fuel consumption in lb/hp-hr
AFR = 12.5; % approximate gasoline air-fuel ratio


% Compute naturally-aspirated volumetric flow rate.
speed = linspace(3000, 6500, 100); % vector of engine speeds in rpm
n = 2;          % rev/cycle (4-stroke engine)

vfr_na_ideal = (displ./16.39 .* speed/n) ./ 1728; % vector of
                % naturally-aspirated volumetric flow rates over engine
                % speed range in cfm
vfr_na = vfr_na_ideal .* VE; % Multilply by volumetric efficiency
                % to get actual VFR in cfm

                
% Compute turbo intake air temps using PR, comp efficiency, and max boost
t_amb_abs = t_amb + 460; % convert to absolute temperature
p_comp_in = p_amb_abs - pre_press_drop; % accounting for pressure drop
                % pre-compressor
p_comp_out = p_amb_abs + max_boost + post_press_drop; % assuming max boost
                % achieved by min speed in vector above and accounting for
                % post-compressor pressure drop
comp_pr = p_comp_out ./ p_comp_in; % pressure ratio across compressor

t_out_abs = t_amb_abs .* (comp_pr.^0.283); % Ideal intake air temp rise
t_rise_ideal = t_out_abs - t_amb_abs;
t_rise_act = t_rise_ideal ./ eta_comp; % Actual temp rise accounting for
                % adiabatic compressor efficiency
pre_ic_iat = t_amb + t_rise_act; % Intake air temp in deg F 
                % with no fuel or I/C cooling effects


% Add in intercooler cooling effect
delta_t_ic = (pre_ic_iat - ic_temp) .* eta_ic;
% iat = pre_ic_iat - delta_t_ic;
iat = 70;
dr_ic = (pre_ic_iat+460)./(iat+460); % Calc the density ratio across I/C


% Compute flow rates after turbocharging
dr_comp = t_amb_abs./(t_amb_abs + t_rise_act) .* comp_pr; % Density ratio
                % across system w/o I/C
dr = dr_comp .* dr_ic; % Multiply by I/C density ratio to get total
vfr_turbo = vfr_na .* dr; % Turbocharged volumetric flow rate in cfm
mfr_turbo = vfr_turbo .* .069; % Turbocharged mass flow rate
mfr_turbo_max = max(mfr_turbo);
mfr_turbo_si = mfr_turbo ./ 2.2 ./ 60; % Converting to kg/s

subplot(2, 2, 1); plot(speed, mfr_turbo_si);
title('Turbo MFR vs Engine Speed')
xlabel('Engine Speed (rpm)')
ylabel('MFR (kg/s)')


% Compute power vector and graph
power = (mfr_turbo.*60) ./ AFR ./bsfc;
power_max = max(power);

subplot(2, 2, 2); plot(speed, power);
title('Power vs Engine Speed')
xlabel('Engine Speed (rpm)')
ylabel('Power (horsepower)')


% Compute individual injector flow rate in cc/min and graph
inj_flow = power .* bsfc .* 10.5 ./ cyl_num;
inj_flow_max = max(inj_flow);

subplot(2, 2, 3); plot(speed, inj_flow);
title('Individual Injector Flow Rate vs Engine Speed')
xlabel('Engine Speed (rpm)')
ylabel('Injector Flow Rate (cc/min)')


end