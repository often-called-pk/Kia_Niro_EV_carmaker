%% MATLAB Code: Generate TWO Separate 2D Torque Maps (Positive & Negative)
% Inputs:
%   - acc_pedal (0 to 1)
%   - brake_pedal (0 to 1)
%   - motor_RPM
%
% Output:
%   - rpm_bp
%   - pedal_bp_positive   (0 to 1)
%   - pedal_bp_negative   (-1 to 0)
%   - torque_table_positive   : Drive torque map   [Nm]
%   - torque_table_negative   : Regen torque map   [Nm]  (will be negative values)
clear; clc; close all;

%% 1. Define breakpoints
rpm_bp = 0:250:14125;                    % RPM axis
pedal_bp_positive = 0:0.05:1;            % Positive pedal (Acc only)
pedal_bp_negative = -1:0.05:0;           % Negative pedal (Brake only)

%% 2. Motor torque characteristics
function t_max_drive = max_drive_torque(rpm)
    const_torque = 255;      % Nm - Peak drive torque
    base_rpm     = 5616;     % RPM - Corner speed (constant torque to constant power)
    
    % Provide maximum torque from 0 up to base_rpm (Constant Torque Region)
    if rpm <= base_rpm
        t_max_drive = const_torque;
    else
        % Power limit at higher speeds (Constant Power Region)
        base_omega = base_rpm * 2 * pi / 60;
        max_power  = const_torque * base_omega;   % Watts
        
        omega = rpm * 2 * pi / 60;
        t_max_drive = max_power / omega;
    end
end

function t_max_regen_mag = max_regen_torque_mag(rpm)
    const_regen_torque = 255;   % Nm - Maximum regen torque magnitude
    fade_rpm           = 500;   % RPM - Speed below which regen fades to zero (approx 10 km/h)
    base_rpm_regen     = 5616;  % RPM - Corner speed for regen (constant torque to constant power)
    
    if rpm <= fade_rpm
        % 1. Low-Speed Fade-Out: Linearly taper torque to 0 at 0 RPM
        t_max_regen_mag = const_regen_torque * (rpm / fade_rpm);
        
    elseif rpm <= base_rpm_regen
        % 2. Constant Torque Region: Maximum regen capacity
        t_max_regen_mag = const_regen_torque;
        
    else
        % 3. Constant Power Region: Reduce torque at high speeds to protect battery/inverter
        base_omega = base_rpm_regen * 2 * pi / 60;
        max_regen_power = const_regen_torque * base_omega; % Watts
        
        omega = rpm * 2 * pi / 60;
        t_max_regen_mag = max_regen_power / omega;
    end
end

%% 3. Generate Positive Torque Table (Drive)
torque_table_positive = zeros(length(rpm_bp), length(pedal_bp_positive));
for i = 1:length(rpm_bp)
    current_rpm = rpm_bp(i);
    t_max = max_drive_torque(current_rpm);
    
    for j = 1:length(pedal_bp_positive)
        pedal = pedal_bp_positive(j);
        torque_table_positive(i, j) = pedal * t_max;   % Always positive or zero
    end
end

%% 4. Generate Negative Torque Table (Regen/Brake)
torque_table_negative = zeros(length(rpm_bp), length(pedal_bp_negative));
for i = 1:length(rpm_bp)
    current_rpm = rpm_bp(i);
    t_max_regen = max_regen_torque_mag(current_rpm);
    
    for j = 1:length(pedal_bp_negative)
        pedal = pedal_bp_negative(j);                 % pedal is negative
        torque_table_negative(i, j) = pedal * t_max_regen;  % Results in negative torque
    end
end

%% 5. Display information
disp('✅ Two separate 2D Torque Maps generated successfully!');
disp(['   RPM breakpoints          : ' num2str(length(rpm_bp)) ' points (0 - ' num2str(max(rpm_bp)) ' RPM)']);
disp(['   Positive pedal points    : ' num2str(length(pedal_bp_positive)) ' (0 to 1)']);
disp(['   Negative pedal points    : ' num2str(length(pedal_bp_negative)) ' (-1 to 0)']);
disp(['   torque_table_positive size : [' num2str(size(torque_table_positive)) ']']);
disp(['   torque_table_negative size : [' num2str(size(torque_table_negative)) ']']);

%% 6. Plot both maps
figure('Position', [100 100 1200 500]);
% Positive Torque Map
subplot(1,2,1);
surf(pedal_bp_positive, rpm_bp, torque_table_positive);
shading interp;
xlabel('Accelerator Pedal (0 to 1)');
ylabel('Motor RPM');
zlabel('Torque (Nm)');
title('Positive Torque Map (Drive)');
colorbar; grid on; view(-45,30);

% Negative Torque Map
subplot(1,2,2);
surf(pedal_bp_negative, rpm_bp, torque_table_negative);
shading interp;
xlabel('Brake Pedal (-1 to 0)');
ylabel('Motor RPM');
zlabel('Torque (Nm)');
title('Negative Torque Map (Regen/Braking)');
colorbar; grid on; view(-45,30);
colormap jet;

%% 7. Save the variables
save('motor_torque_maps_2D_separate.mat', ...
     'rpm_bp', 'pedal_bp_positive', 'pedal_bp_negative', ...
     'torque_table_positive', 'torque_table_negative', '-v7.3');
disp('💾 Saved as motor_torque_maps_2D_separate.mat');

% Motor Parameters - from specs

Rs = 32;
PP = 2;
J = 0.00019;
B = 0.001;
Ke_Vpp_krpm = 100;
Vdc = 335/2;
Tmax = 0.6;
L1 = 0.028;
Lm = 0.060;
Ldq = L1+Lm;
Ke = Ke_Vpp_krpm*60/(2*pi*1000);
M = Ke/(sqrt(3)*PP);
T2Iconversion = 2/(3*M*PP);

% PID gains for current
Kc_p = 32;
Kc_i = 2E3;
Kc_d = 0;
% PID gains for speed
Ks_p = 0.001;
Ks_i = 0.01;