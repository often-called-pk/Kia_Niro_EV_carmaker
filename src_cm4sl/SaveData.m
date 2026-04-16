

file = '2026_03_19_18_22_35_vehicle_signals_log';
Data = readtable(file);

%% OXTS

%% Load CSV
file = '2026_03_19_18_22_36_imu_can_log';
T = readtable(file, 'TextType', 'string');

%% Extract signals with their own time vectors
idx_speed   = strcmp(Data.signal,'speed_kmh');
idx_rpm     = strcmp(Data.signal,'rpm');
idx_steer   = strcmp(Data.signal,'steer_raw');
idx_current = strcmp(Data.signal,'battery_current');
idx_voltage = strcmp(Data.signal,'battery_voltage');
idx_soc     = strcmp(Data.signal,'SoC');   % in your screenshot it is 'SoC', not 'soc'
idx_Brake_Pedal     = strcmp(Data.signal,'brake_pedel');  

time_speed   = Data.time(idx_speed);
time_rpm     = Data.time(idx_rpm);
time_steer   = Data.time(idx_steer);
time_current = Data.time(idx_current);
time_voltage = Data.time(idx_voltage);
time_soc     = Data.time(idx_soc);
time_Brake   = Data.time(idx_Brake_Pedal);

%% REMOVE OFFSET BETWEEN OBD AND OXTS
time_shift_obd = 0;   % [s]

time_speed   = time_speed   - time_shift_obd -1.16;
time_rpm     = time_rpm     - time_shift_obd - 1.05;
time_steer   = time_steer   - time_shift_obd ;
time_current = time_current - time_shift_obd -1.3;
time_voltage = time_voltage - time_shift_obd -1.3;
time_soc     = time_soc     - time_shift_obd;

Speed      = Data.value(idx_speed);
RPM_rmotor = Data.value(idx_rpm);
Steer      = Data.value(idx_steer);
B_current  = Data.value(idx_current);
B_voltage  = Data.value(idx_voltage);
SoC        = Data.value(idx_soc);
Brake      = Data.value(idx_Brake_Pedal);



%% Basic cleaning
RPM_rmotor(RPM_rmotor > 60000) = 0;

% Remove duplicate timestamps if needed for interpolation
[time_speed,   ia] = unique(time_speed,   'stable'); Speed      = Speed(ia);
[time_rpm,     ia] = unique(time_rpm,     'stable'); RPM_rmotor = RPM_rmotor(ia);
[time_steer,   ia] = unique(time_steer,   'stable'); Steer      = Steer(ia);
[time_current, ia] = unique(time_current, 'stable'); B_current  = B_current(ia);
[time_voltage, ia] = unique(time_voltage, 'stable'); B_voltage  = B_voltage(ia);
[time_soc,     ia] = unique(time_soc,     'stable'); SoC        = SoC(ia);

%% Fix battery current if decoded as unsigned instead of signed
raw_current_unsigned = uint16(round(B_current * 10));
raw_current_signed   = typecast(raw_current_unsigned, 'int16');
B_current_fixed      = double(raw_current_signed) * 0.1-0.9;

%% Steering conversion
steer_center = 32757;
steer_right  = 27956;
steer_left   = 37612;

counts_half = (steer_left - steer_right) / 2;
deg_half    = 2.66 * 360 / 2;
scale       = deg_half / counts_half;

steer_deg = (Steer - steer_center) * scale;

%% Build common time base for combined calculations
t0 = max([time_speed(1), time_rpm(1), time_current(1), time_voltage(1)]);
tf = min([time_speed(end), time_rpm(end), time_current(end), time_voltage(end)]);

dt = 0.01;   % 10 ms common base
t_common = (t0:dt:tf)';

Speed_i      = interp1(time_speed,   Speed,           t_common, 'linear');
RPM_rmotor_i = interp1(time_rpm,     RPM_rmotor,      t_common, 'linear');
B_current_i  = interp1(time_current, B_current_fixed, t_common, 'linear');
B_voltage_i  = interp1(time_voltage, B_voltage,       t_common, 'linear');

%% Calculated data
i_ratio = 10.65;
wheel_radius = 0.3;

Power = B_current_i .* B_voltage_i * 1e-3;      % kW
omega_rmotor = RPM_rmotor_i .* (2*pi/60);       % rad/s

Torque_rmotor = 1e3 * (Power ./ omega_rmotor);  % Nm

% Avoid nonsense values at low speed / invalid divisionsti
Torque_rmotor(abs(omega_rmotor) < 1) = 0;
Torque_rmotor(RPM_rmotor_i < 1) = 0;
Torque_rmotor(abs(Torque_rmotor) > 280) =250;

Torque_rwheel = Torque_rmotor * i_ratio;

%% Plot raw signals against time
% figure(1);
% 
% subplot(2,2,1)
% plot(time_speed, Speed)
% ylabel('Speed [km/h]')
% xlabel('Time [s]')
% grid on
% 
% subplot(2,2,2)
% plot(time_rpm, RPM_rmotor)
% ylabel('RPM')
% xlabel('Time [s]')
% ylim([0,10000])
% grid on
% 
% subplot(2,2,3)
% yyaxis left
% plot(time_voltage, B_voltage)
% ylabel('Voltage [V]')
% 
% yyaxis right
% plot(time_current, B_current_fixed)
% ylabel('Current [A]')
% 
% xlabel('Time [s]')
% grid on
% legend('Voltage','Current')
% 
% subplot(2,2,4)
% plot(t_common, Power)
% ylabel('Power [kW]')
% xlabel('Time [s]')
% grid on
% legend('Power')
% 
% 
% figure()
% 
% yyaxis left
% h1 = plot(time_voltage, B_voltage, 'Color', [0 0.4470 0.7410], 'LineWidth', 2);
% ylabel('Voltage [V]', 'FontSize', 15)
% 
% yyaxis right
% h2 = plot(time_current, B_current_fixed, 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 2);
% ylabel('Current [A]', 'FontSize', 15)
% 
% grid on
% grid minor
% box on
% 
% xlabel('Time [s]', 'FontSize', 15)
% title('Battery Voltage and Current', 'FontSize', 17, 'FontWeight', 'bold')
% 
% legend([h1 h2], {'Battery Voltage', 'Battery Current'}, ...
%     'Location', 'best', ...
%     'FontSize', 15)
% 
% set(gca, 'FontSize', 15, 'LineWidth', 1.1)
% 
% %% Torques
% figure(2)
% 
% subplot(2,2,1)
% yyaxis left
% plot(t_common, Torque_rmotor)
% ylabel('Motor Torque [Nm]')
% xlabel('Time [s]')
% grid on
% legend('Motor Torque')
% hold on
% yyaxis right
% plot(time_current, B_current_fixed)
% ylabel('Current [A]')
% 
% subplot(2,2,2)
% plot(t_common, Torque_rwheel)
% ylabel('Wheel Torque [Nm]')
% xlabel('Time [s]')
% grid on
% legend('Wheel Torque')

%% SoC
% figure(3)
% plot(time_soc, SoC)
% ylabel('State of Charge [%]')
% xlabel('Time [s]')
% grid on
% legend('SoC')

%% Handling
% figure(4)
% plot(time_steer, steer_deg)
% ylabel('Steering angle [deg]')
% xlabel('Time [s]')
% grid on
% legend('Steering angle')

%% Comparison speed vs RPM
% figure(5)
rpm_new = (60/(2*pi)) * i_ratio * (Speed_i/3.6) / wheel_radius;

% plot(t_common, rpm_new)
% hold on
% plot(t_common, RPM_rmotor_i)
% grid on
% hold off
% xlabel('Time [s]')
% ylabel('RPM')
% title('Comparison of Speed vs RPM')
% legend('Calculated RPM', 'Measured RPM')

%% Calculate slip
den = max(abs(rpm_new), abs(RPM_rmotor_i));
den = max(den, 1000);
slip = abs(rpm_new - RPM_rmotor_i) ./ den;

% figure(6)
% plot(t_common, slip)
% xlabel('Time [s]')
% ylabel('Slip [-]')
% grid on
% title('Slip estimate')

%% Calculate accumulated energy
Power_W = B_current_i .* B_voltage_i;
E_J  = cumtrapz(t_common, Power_W);
E_Wh = E_J / 3600;

% figure(7)
% set(gcf, 'Color', 'w')
% 
% plot(t_common, E_Wh, 'Color', [0 0.4470 0.7410], 'LineWidth', 2)
% 
% grid on
% grid minor
% box on
% 
% xlabel('Time [s]', 'FontSize', 15)
% ylabel('Energy [Wh]', 'FontSize', 15)
% title('Accumulated Energy Consumption', 'FontSize', 17, 'FontWeight', 'bold')
% 
% legend('Energy Consumption', ...
%     'Location', 'best', ...
%     'FontSize', 15)
% 
% set(gca, ...
%     'FontSize', 15, ...
%     'LineWidth', 1.5)
% 


ti = 0;
tf = 67.8;

%% Raw signals
idx_speed_win   = (time_speed   >= ti) & (time_speed   <= tf);
idx_rpm_win     = (time_rpm     >= ti) & (time_rpm     <= tf);
idx_voltage_win = (time_voltage >= ti) & (time_voltage <= tf);
idx_current_win = (time_current >= ti) & (time_current <= tf);
idx_soc_win     = (time_soc     >= ti) & (time_soc     <= tf);
idx_steer_win   = (time_steer   >= ti) & (time_steer   <= tf);

time_speed_win   = time_speed(idx_speed_win);
Speed_win        = Speed(idx_speed_win);

time_rpm_win     = time_rpm(idx_rpm_win);
RPM_rmotor_win   = RPM_rmotor(idx_rpm_win);

time_voltage_win = time_voltage(idx_voltage_win);
B_voltage_win    = B_voltage(idx_voltage_win);

time_current_win = time_current(idx_current_win);
B_current_win    = B_current_fixed(idx_current_win);

time_soc_win     = time_soc(idx_soc_win);
SoC_win          = SoC(idx_soc_win);

time_steer_win   = time_steer(idx_steer_win);
steer_deg_win    = steer_deg(idx_steer_win);

%% Signals based on t_common
idx_common_win = (t_common >= ti) & (t_common <= tf);

t_common_win      = t_common(idx_common_win);
Power_win         = Power(idx_common_win);
Torque_rmotor_win = Torque_rmotor(idx_common_win);
Torque_rwheel_win = Torque_rwheel(idx_common_win);
rpm_new_win       = rpm_new(idx_common_win);
RPM_rmotor_i_win  = RPM_rmotor_i(idx_common_win);
slip_win          = slip(idx_common_win);
E_Wh_win          = E_Wh(idx_common_win);
% figure();


% %% Powertrain Plot
% subplot(2,2,1)
% plot(time_speed_win, Speed_win)
% ylabel('Speed [km/h]')
% xlabel('Time [s]')
% grid on
% 
% subplot(2,2,2)
% plot(time_rpm_win, RPM_rmotor_win)
% ylabel('RPM')
% xlabel('Time [s]')
% ylim([0,10000])
% grid on
% 
% subplot(2,2,3)
% yyaxis left
% plot(time_voltage_win, B_voltage_win)
% ylabel('Voltage [V]')
% 
% yyaxis right
% plot(time_current_win, B_current_win)
% ylabel('Current [A]')
% 
% xlabel('Time [s]')
% grid on
% legend('Voltage','Current')
% 
% subplot(2,2,4)
% plot(t_common_win, Power_win)
% ylabel('Power [kW]')
% xlabel('Time [s]')
% grid on
% legend('Power')
% figure()
% %% Torque PLOT
% subplot(2,2,1)
% plot(t_common_win, Torque_rmotor_win)
% ylabel('Motor Torque [Nm]')
% xlabel('Time [s]')
% grid on
% legend('Motor Torque')
% 
% subplot(2,2,2)
% plot(t_common_win, Torque_rwheel_win)
% ylabel('Wheel Torque [Nm]')
% xlabel('Time [s]')
% grid on
% legend('Wheel Torque')
% 
% %% Steer Plot 
% figure()
% plot(time_steer_win, steer_deg_win)
% ylabel('Steering angle [deg]')
% xlabel('Time [s]')
% grid on
% legend('Steering angle')
% figure()
% 
% 

% %% Extract Torque values
% idx_torque_window = (t_common >= ti) & (t_common <= tf);
% Torque_14_18 = Torque_rwheel(idx_torque_window);
% Time_14_18   = t_common(idx_torque_window);
% Time_14_18_shifted = Time_14_18 - Time_14_18(1);
% torque_ts = timeseries(Torque_14_18, Time_14_18_shifted);
% figure
% plot(Time_14_18, Torque_14_18)
% grid on
% xlabel('Time [s]')
% ylabel('Motor Torque [Nm]')
% title('Motor torque from 14 s to 18 s')






%% Helper functions
toInt16LE = @(b1,b2) double(typecast(uint16(uint16(b1) + bitshift(uint16(b2),8)), 'int16'));
toUInt16LE = @(b1,b2) double(uint16(b1) + bitshift(uint16(b2),8));

toInt32LE = @(b1,b2,b3,b4) double(typecast(uint32( ...
    uint32(b1) + ...
    bitshift(uint32(b2),8) + ...
    bitshift(uint32(b3),16) + ...
    bitshift(uint32(b4),24)), 'int32'));

parseHexBytes = @(s) uint8(hex2dec(split(erase(strtrim(s), '"')))).';

%% Preallocate containers

% 0x601
t601 = [];
PosLat = [];
PosLon = [];

% 0x603
t603 = [];
VelNorth = [];
VelEast = [];
VelDown = [];
Speed2D = [];

% 0x604
t604 = [];
VelForward = [];
VelLateral = [];

% 0x606
t606 = [];
AccelForward = [];
AccelLateral = [];
AccelDown = [];
AccelSlip = [];

% 0x60A
t60A = [];
AngleTrack = [];
AngleSlip = [];
Curvature = [];
Radius = [];

% 155 brake pedal position
t155 = [];
BrakePedalPos = [];

% 156 throttle position
t156 = [];
ThrottlePos = [];

% 607h (1543) - HeadingPitchRoll
Heading = [];
Pitch   = [];
Roll    = [];
t607    = [];

% 608h (1544) - RateVehicle
AngRateX = [];
AngRateY = [];
AngRateZ = [];
t608     = [];

% 60Eh (1550) - AngAccelVehicle
AngAccelX = [];
AngAccelY = [];
AngAccelZ = [];
t60E      = [];



%% Decode row by row
for i = 1:height(T)

    msg_id = T.arbitration_id(i);   % decimal
    data_str = T.data(i);
    time_i = T.time(i);

    bytes = parseHexBytes(data_str);
    n = numel(bytes);

    switch msg_id

        case 1537   % 0x601 LatitudeLongitude
            if n >= 8
                PosLat(end+1,1) = toInt32LE(bytes(1),bytes(2),bytes(3),bytes(4)) * 1e-7;
                PosLon(end+1,1) = toInt32LE(bytes(5),bytes(6),bytes(7),bytes(8)) * 1e-7;
                t601(end+1,1) = time_i;
            end

        case 1539   % 0x603 Velocity
            if n >= 8
                VelNorth(end+1,1) = toInt16LE(bytes(1), bytes(2)) * 0.01;
                VelEast(end+1,1)  = toInt16LE(bytes(3), bytes(4)) * 0.01;
                VelDown(end+1,1)  = toInt16LE(bytes(5), bytes(6)) * 0.01;
                Speed2D(end+1,1)  = toUInt16LE(bytes(7), bytes(8)) * 0.01;
                t603(end+1,1) = time_i;
            end

        case 1540   % 0x604 VelocityLevel
            if n >= 4
                VelForward(end+1,1) = toInt16LE(bytes(1), bytes(2)) * 0.01;
                VelLateral(end+1,1) = toInt16LE(bytes(3), bytes(4)) * 0.01;
                t604(end+1,1) = time_i;
            end

        case 1542   % 0x606 AccelLevel
            if n >= 8
                AccelForward(end+1,1) = toInt16LE(bytes(1), bytes(2)) * 0.01;
                AccelLateral(end+1,1) = toInt16LE(bytes(3), bytes(4)) * 0.01;
                AccelDown(end+1,1)    = toInt16LE(bytes(5), bytes(6)) * 0.01;
                AccelSlip(end+1,1)    = toInt16LE(bytes(7), bytes(8)) * 0.01;
                t606(end+1,1) = time_i;
            end

        case 1546   % 0x60A TrackSlipCurvature
            if n >= 6
                AngleTrack(end+1,1) = toUInt16LE(bytes(1), bytes(2)) * 0.01;
                AngleSlip(end+1,1)  = toInt16LE(bytes(3), bytes(4)) * 0.01;

                curv = toInt16LE(bytes(5), bytes(6)) * 0.0001;
                Curvature(end+1,1) = curv;

                if abs(curv) > 1e-12
                    Radius(end+1,1) = 1 / curv;
                else
                    Radius(end+1,1) = NaN;
                end

                t60A(end+1,1) = time_i;
            end
        case 341   % 0x155 throttle pedal position
            if n >= 8
                ThrottlePos(end+1,1) = toUInt16LE(bytes(6), bytes(7));
                t155(end+1,1) = time_i;
            end
            
        
        case 342   % 0x156 throttle position
            if n >= 8
                
                BrakePedalPos(end+1,1) = toUInt16LE(bytes(6), bytes(7));
                
                t156(end+1,1) = time_i;
            end
        case 1543   % 607h - HeadingPitchRoll
            if n >= 6
                Heading(end+1,1) = 0.01 * toUInt16LE(bytes(1), bytes(2)); % deg
                Pitch(end+1,1)   = 0.01 * toInt16LE(bytes(3), bytes(4));  % deg
                Roll(end+1,1)    = 0.01 * toInt16LE(bytes(5), bytes(6));  % deg
                t607(end+1,1)    = time_i;
            end
    
        case 1544   % 608h - RateVehicle
            if n >= 6
                AngRateX(end+1,1) = 0.01 * toInt16LE(bytes(1), bytes(2)); % deg/s
                AngRateY(end+1,1) = 0.01 * toInt16LE(bytes(3), bytes(4)); % deg/s
                AngRateZ(end+1,1) = 0.01 * toInt16LE(bytes(5), bytes(6)); % deg/s
                t608(end+1,1)     = time_i;
            end
            
    
        
        case 1550   % 60Eh - AngAccelVehicle
            if n >= 6
                AngAccelX(end+1,1) = 0.1 * toInt16LE(bytes(1), bytes(2)); % deg/s^2
                AngAccelY(end+1,1) = 0.1 * toInt16LE(bytes(3), bytes(4)); % deg/s^2
                AngAccelZ(end+1,1) = 0.1 * toInt16LE(bytes(5), bytes(6)); % deg/s^2
                t60E(end+1,1)      = time_i;
            end
    end
end

%% Convert latitude / longitude to local X-Y [m]
% Reference point = first valid GPS point
lat0 = PosLat(1);
lon0 = PosLon(1);

R_earth = 6378137; % [m]

dLat = deg2rad(PosLat - lat0);
dLon = deg2rad(PosLon - lon0);

X = R_earth * dLon .* cosd(lat0);   % East [m]
Y = R_earth * dLat;                 % North [m]



% % Plot GPS trajectory in X-Y
% figure('Name','GPS Trajectory','Units','normalized','Position',[0.12 0.12 0.65 0.75])
% 
% plot(X, Y, '-', 'LineWidth', 1.5)
% hold on
% plot(X(1), Y(1), 'go', 'MarkerSize', 10, 'LineWidth', 2)
% plot(X(end), Y(end), 'ro', 'MarkerSize', 10, 'LineWidth', 2)
% 
% grid on
% grid minor
% axis equal
% 
% xlabel('X [m]', 'FontSize', 16)
% ylabel('Y [m]', 'FontSize', 16)
% title('Vehicle Trajectory in Local X-Y Coordinates', 'FontSize', 18)
% 
% legend('Trajectory','Start','End','Location','best')
% set(gca, 'FontSize', 14, 'LineWidth', 1.2)

%% Plot 0x603 Velocity
% figure(9)
% plot(t603, VelNorth, 'LineWidth', 1.2)
% hold on
% plot(t603, VelEast, 'LineWidth', 1.2)
% plot(t603, VelDown, 'LineWidth', 1.2)
% plot(t603, Speed2D, 'LineWidth', 1.2)
% grid on
% xlabel('Time [s]')
% ylabel('Velocity [m/s]')
% title('0x603 - Velocity')
% legend('VelNorth','VelEast','VelDown','Speed2D')

% %% Plot 0x604 VelocityLevel
% figure('Color','w')
% 
% plot(t604, VelForward*3.6, 'LineWidth', 1.8)
% hold on
% plot(time_speed, Speed, 'LineWidth', 1.8)
% 
% grid on
% grid minor
% box on
% 
% xlabel('Time [s]', 'FontSize', 14)
% ylabel('Velocity [km/h]', 'FontSize', 14)
% title('Vehicle Velocity: OXTS vs OBD', 'FontSize', 14, 'FontWeight', 'bold')
% 
% legend('OXTS Velocity', 'OBD Velocity', ...
%     'Location', 'best', ...
%     'FontSize', 14)
% 
% set(gca, 'FontSize', 16, 'LineWidth', 1.1)

%% Plot 0x606 AccelLevel


% % Plot all the acc. 
% plot(t606, AccelForward, 'LineWidth', 1.2)
% hold on
% % plot(t606, AccelLateral, 'LineWidth', 1.2)
% %plot(t606, AccelDown, 'LineWidth', 1.2)
% %plot(t606, AccelSlip, 'LineWidth', 1.2)
% grid on
% xlabel('Time [s]')
% ylabel('Acceleration [m/s^2]')
% title('0x606 - AccelLevel')
% legend('AccelForward') %,'AccelLateral') %'AccelDown','AccelSlip')
% Plot some part of the data
% idx_14_18 = (t606 >= ti) & (t606 <= tf);
% figure();
% plot(t606, AccelForward, 'LineWidth', 1.2)
% grid on
% xlabel('Time [s]')
% ylabel('Acceleration [m/s^2]')
% title('0x606 - AccelForward from 12.5 to 18 s')
% legend('AccelForward')
% 
% figure();
% plot(t606(idx_14_18), AccelForward(idx_14_18), 'LineWidth', 1.2)
% grid on
% xlabel('Time [s]')
% ylabel('Acceleration [m/s^2]')
% title('0x606 - AccelForward from 12.5 to 18 s')
% legend('AccelForward')




%% Plot 0x60A angles
% figure(12)
% plot(t60A, AngleTrack, 'LineWidth', 1.2)
% hold on
% plot(t60A, AngleSlip, 'LineWidth', 1.2)
% grid on
% xlabel('Time [s]')
% ylabel('Angle [deg]')
% title('0x60A - Track / Slip Angles')
% legend('AngleTrack','AngleSlip')

%% Plot Curvature and Radius
% figure(13)
% yyaxis left
% plot(t60A, abs(Curvature), 'LineWidth', 1.2)
% ylabel('Curvature [1/m]')
% 
% yyaxis right
% plot(t60A, abs(Radius), 'LineWidth', 1.2)
% ylabel('Radius [m]')
% 
% grid on
% xlabel('Time [s]')
% title('0x60A - Curvature and Radius')
% legend('Curvature','Radius')

for i=1:length(ThrottlePos)
    if ThrottlePos(i)>=16256
        ThrottlePos(i)=(ThrottlePos(i)-16255)./10.23;
        

    end

end



for i=1:length(BrakePedalPos)
    if BrakePedalPos(i)>17449 || BrakePedalPos(i)<17000
        BrakePedalPos(i)=0;

    else
        BrakePedalPos(i)=(BrakePedalPos(i)-17001)./((17448-17001))*100;


    end
end 


% figure()
% 
% subplot(2,1,1)
% plot(t155,ThrottlePos,'r','LineWidth', 1.2)
% grid on
% ylabel('Throttle')
% %xlim([28,34])
% 
% subplot(2,1,2)
% 
% yyaxis left
% plot(t156, BrakePedalPos, 'b', 'LineWidth', 1.2)
% ylabel('Brake DWM')
% hold on 
% plot(time_Brake,Brake)
% ylim([0,100])
% grid on


% Inputs
m = 2000;          % kg
g = 9.81;          % m/s^2
Crr = 0.015;       % rolling resistance coefficient
rho = 1.225;       % air density [kg/m^3]
Cd = 0.29;         % drag coefficient
A = 2.45;           % frontal area [m^2]

% Speed in m/s
v = VelForward;

% Longitudinal acceleration
ax = smoothdata(AccelForward, 'sgolay', 100);

% Resistive forces
Frr = Crr * m * g * ones(size(v));
Faero = 0.5 * rho * Cd * A .* v.^2;

% Estimated traction force
Fx = m .* ax + Frr + Faero;

Torque_calc_motor= Fx*0.3/i_ratio;
% figure()
% plot(t604, Torque_calc_motor, 'r', 'LineWidth', 1.2)
% hold on
% plot(t_common, Torque_rmotor, 'b', 'LineWidth', 1.2)
% plot(t155, ThrottlePos, 'y', 'LineWidth', 1.2)
% plot(t156, BrakePedalPos, 'k', 'LineWidth', 1.2)
% grid on
% 
% xlabel('Time [s]')
% ylabel('Value')
% title('Motor Torque, Throttle and Brake')
% legend('Calculated motor torque (ax,v)', 'Measured motor torque (rpm,current,voltage)', 'Throttle position', 'Brake pedal position', 'Location', 'best')
% figure;
% 
% subplot(3,1,1)
% %plot(t607, Heading, 'LineWidth', 1.2); hold on
% plot(t607, Pitch,   'LineWidth', 1.2)
% plot(t607, Roll,    'LineWidth', 1.2)
% grid on
% xlabel('Time [s]')
% ylabel('Angle [deg]')
% title('Pitch')
% legend('Pitch','Roll')
% fh = findall(0,'Type','Figure');
% set(findall(fh, '-property', 'fontsize'), 'fontsize', 20)
% 
% subplot(3,1,2)
% %plot(t608, AngRateX, 'LineWidth', 1.2); hold on
% plot(t608, AngRateY, 'LineWidth', 1.2)
% %plot(t608, AngRateZ, 'LineWidth', 1.2)
% grid on
% xlabel('Time [s]')
% ylabel('Rate [deg/s]')
% title('RateVehicle-Y')
% legend('AngRateY')
% fh = findall(0,'Type','Figure');
% set(findall(fh, '-property', 'fontsize'), 'fontsize', 20)
% 
% 
% subplot(3,1,3)
% plot(t60E, AngAccelX, 'LineWidth', 1.2); hold on
% plot(t60E, AngAccelY, 'LineWidth', 1.2)
% plot(t60E, AngAccelZ, 'LineWidth', 1.2)
% grid on
% xlabel('Time [s]')
% ylabel('Accel [deg/s^2]')
% title('60Eh - AngAccelVehicle')
% legend('AngAccelX','AngAccelY','AngAccelZ')
% 
% figure()
% plot(t607, Heading, 'LineWidth', 1.2); hold on
% plot(t608, AngRateZ, 'LineWidth', 1.2)
% xlabel('Time [s]')
% ylabel('heading and angular rate [deg/s]')
% title('60Eh - Z degree')
% legend('Heading','YawRate')
% 
% 
% 
% figure()
% 
% yyaxis left
% plot(t156, BrakePedalPos, 'k', 'LineWidth', 1.2)
% ylabel('Brake Pedal Position')
% ylim([0,100])
% 
% yyaxis right
% hold on
% plot(t604, VelForward*3.6, 'LineWidth', 1.2)
% ylabel('Velocity [km/h]')
% ylim([0,40])
% % xlim([0,65])
% 
% grid on
% xlabel('Time [s]')
% title('Brake vs Velocity')
% legend('Brake Pedal Position', 'Velocity', 'Location', 'best')
% 
% 
% figure('Name','Motor Torque Comparison', ...
%        'Units','normalized', 'Position',[0.08 0.12 0.78 0.72])
% 
% plot(t604, Torque_calc_motor, 'Color', [0 0.45 0.74], 'LineWidth', 2.5)
% hold on
% plot(t_common, Torque_rmotor, 'Color', [0.85 0.33 0.10], 'LineWidth', 2.5)
% 
% grid on
% grid minor
% xlabel('Time [s]', 'FontSize', 18)
% ylabel('Motor Torque [Nm]', 'FontSize', 18)
% title('Motor Torque Comparison', 'FontSize', 20)
% 
% legend({'Calculated motor torque','Measured motor torque'}, ...
%        'Location','northoutside', ...
%        'Orientation','horizontal', ...
%        'FontSize', 14, ...
%        'Box','off')
% 
% set(gca, 'FontSize', 16, 'LineWidth', 1.2)
% 
% 
% figure('Color','w')
% 
% plot(t606, AccelForward, 'Color', [0 0.4470 0.7410], 'LineWidth', 2)
% hold on
% plot(t606, AccelLateral, 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 2)
% 
% grid on
% grid minor
% box on
% 
% xlabel('Time [s]', 'FontSize', 15)
% ylabel('Acceleration [m/s^2]', 'FontSize', 15)
% title('Vehicle Acceleration: Longitudinal vs Lateral', 'FontSize', 17, 'FontWeight', 'bold')
% 
% legend('Longitudinal Acceleration', 'Lateral Acceleration', ...
%     'Location', 'best', ...
%     'FontSize', 15)
% 
% set(gca, ...
%     'FontSize', 15, ...
%     'LineWidth', 1.8)

%% =========================
% SPEED PROFILE FOR SIMULINK
% ==========================

% Fenêtre que tu veux rejouer
ti = 0;
tf = 67.8;

% Pas de temps voulu pour Simulink
dt_ref = 0.01;   % 10 ms

% Enlever doublons sur t604
[t604_u, ia] = unique(t604, 'stable');
VelForward_u = VelForward(ia);   % m/s

% Garder seulement la fenêtre voulue
idx_v = (t604_u >= ti) & (t604_u <= tf);
t_v = t604_u(idx_v);
v_mps = VelForward_u(idx_v);

% Recaler le temps pour commencer à 0
t_v = t_v - t_v(1);

% Nettoyage léger
v_mps = fillmissing(v_mps, 'linear');
v_mps(v_mps < 0) = 0;

% Petit lissage pour éviter un profil trop bruité
v_mps = smoothdata(v_mps, 'movmean', 5);

% Re-échantillonnage uniforme
t_ref = (0:dt_ref:t_v(end))';
v_ref_mps = interp1(t_v, v_mps, t_ref, 'pchip', 'extrap');
v_ref_mps(v_ref_mps < 0) = 0;

% Version km/h si besoin
v_ref_kmh = 3.6 * v_ref_mps;

% Format recommandé pour Simulink
speed_profile_mps = timeseries(v_ref_mps, t_ref);
speed_profile_kmh = timeseries(v_ref_kmh, t_ref);

% Format matrice possible aussi
speed_profile_mat_mps = [t_ref, v_ref_mps];
speed_profile_mat_kmh = [t_ref, v_ref_kmh];

% Envoyer dans le workspace
assignin('base', 'speed_profile_mps', speed_profile_mps);
assignin('base', 'speed_profile_kmh', speed_profile_kmh);
assignin('base', 'speed_profile_mat_mps', speed_profile_mat_mps);
assignin('base', 'speed_profile_mat_kmh', speed_profile_mat_kmh);

if exist('speed_cm','var')

    % Récupération du signal CarMaker
    t_cm = speed_cm.Time(:);
    v_cm = squeeze(speed_cm.Data);

    % Recaler le temps à 0
    t_cm = t_cm - t_cm(1);

    % Garder la même fenêtre que le speed profile
    idx_cm = (t_cm >= 0) & (t_cm <= t_ref(end));
    t_cm_w = t_cm(idx_cm);
    v_cm_w = v_cm(idx_cm);

    % Interpolation sur la même base de temps que le profil
    v_cm_ref = interp1(t_cm_w, v_cm_w, t_ref, 'linear', 'extrap');

    % Plot comparaison
    figure()
    plot(t_ref, v_ref_mps, 'LineWidth', 2)
    hold on
    plot(t_ref, v_cm_ref, 'LineWidth', 2)
    grid on
    xlabel('Time [s]')
    ylabel('Speed [m/s]')
    title('Speed Profile vs CarMaker Speed')
    legend('Speed profile','CarMaker speed','Location','best')

else
    warning('La variable speed_cm n''existe pas dans le workspace.');
end

%% =========================
% MEASURED CURRENT FOR COMPARISON
% ==========================

[time_current_u, ia] = unique(time_current, 'stable');
B_current_u = B_current_fixed(ia);

idx_i = (time_current_u >= ti) & (time_current_u <= tf);
t_i = time_current_u(idx_i);
i_meas = B_current_u(idx_i);

% Recaler le temps à 0
t_i = t_i - t_i(1);

% Interpolation sur le même temps que le speed profile
i_meas_ref = interp1(t_i, i_meas, t_ref, 'linear', 'extrap');

current_meas_ts = timeseries(i_meas_ref, t_ref);
current_meas_mat = [t_ref, i_meas_ref];

assignin('base', 'current_meas_ts', current_meas_ts);
assignin('base', 'current_meas_mat', current_meas_mat);

%% =========================
% REAL VS CARMAKER CURRENT
% ==========================

% Vérifier que la simu a bien créé I_cm_real
if ~exist('I_cm_real','var')
    error('La variable I_cm_real n''existe pas dans le workspace. Ajoute un To Workspace sur current_real dans Simulink.');
end

% --- COURANT REEL DEJA PREPARE ---
% t_ref
% i_meas_ref

% --- COURANT CARMAKER ---
t_cm = I_cm_real.Time(:);
i_cm = squeeze(I_cm_real.Data);

% Recaler le temps à 0
t_cm = t_cm - t_cm(1);

% Garder la même fenêtre temporelle que le profil
idx_cm = (t_cm >= 0) & (t_cm <= t_ref(end));
t_cm_w = t_cm(idx_cm);
i_cm_w = i_cm(idx_cm);

% Interpoler CarMaker sur la même base de temps que le réel
i_cm_ref = interp1(t_cm_w, i_cm_w, t_ref, 'linear', 'extrap');

% Si les signes sont inversés, décommente la ligne suivante
% i_cm_ref = -i_cm_ref;

% --- PLOT COURANT ---
figure()
plot(t_ref, i_meas_ref, 'LineWidth', 2)
hold on
plot(t_ref, i_cm_ref, 'LineWidth', 2)
grid on
xlabel('Time [s]')
ylabel('Current [A]')
title('Real vs CarMaker Battery Current')
legend('Real current','CarMaker current','Location','best')


%% =========================
% REAL VS CARMAKER ENERGY
% ==========================

if exist('V_cm_real','var')

    % --- TENSION REELLE ---
    [time_voltage_u, ia] = unique(time_voltage, 'stable');
    B_voltage_u = B_voltage(ia);

    idx_v = (time_voltage_u >= ti) & (time_voltage_u <= tf);
    t_vreal = time_voltage_u(idx_v);
    v_real = B_voltage_u(idx_v);

    t_vreal = t_vreal - t_vreal(1);
    v_real_ref = interp1(t_vreal, v_real, t_ref, 'linear', 'extrap');

    % --- TENSION CARMAKER ---
    t_vcm = V_cm_real.Time(:);
    v_cm = squeeze(V_cm_real.Data);

    t_vcm = t_vcm - t_vcm(1);

    idx_vcm = (t_vcm >= 0) & (t_vcm <= t_ref(end));
    t_vcm_w = t_vcm(idx_vcm);
    v_cm_w = v_cm(idx_vcm);

    v_cm_ref = interp1(t_vcm_w, v_cm_w, t_ref, 'linear', 'extrap');

    % --- PUISSANCE ---
    P_real_W = v_real_ref .* i_meas_ref;
    P_cm_W   = v_cm_ref   .* i_cm_ref;

    % --- ENERGIE CUMULEE ---
    E_real_Wh = cumtrapz(t_ref, P_real_W) / 3600;
    E_cm_Wh   = cumtrapz(t_ref, P_cm_W)   / 3600;

    figure()
    plot(t_ref, E_real_Wh, 'LineWidth', 2)
    hold on
    plot(t_ref, E_cm_Wh, 'LineWidth', 2)
    grid on
    xlabel('Time [s]')
    ylabel('Energy [Wh]')
    title('Real vs CarMaker Accumulated Energy')
    legend('Real energy','CarMaker energy','Location','best')

else
    warning('V_cm_real n''existe pas. Comparaison energie ignoree.');
end

%% =========================
% REAL VS CARMAKER VOLTAGE
% ==========================

if exist('V_cm_real','var')

    % --- TENSION REELLE ---
    [time_voltage_u, ia] = unique(time_voltage, 'stable');
    B_voltage_u = B_voltage(ia);

    idx_v = (time_voltage_u >= ti) & (time_voltage_u <= tf);
    t_vreal = time_voltage_u(idx_v);
    v_real = B_voltage_u(idx_v);

    % Recaler le temps à 0
    t_vreal = t_vreal - t_vreal(1);

    % Interpoler sur la même base de temps
    v_real_ref = interp1(t_vreal, v_real, t_ref, 'linear', 'extrap');

    % --- TENSION CARMAKER ---
    t_vcm = V_cm_real.Time(:);
    v_cm = squeeze(V_cm_real.Data);

    t_vcm = t_vcm - t_vcm(1);

    idx_vcm = (t_vcm >= 0) & (t_vcm <= t_ref(end));
    t_vcm_w = t_vcm(idx_vcm);
    v_cm_w = v_cm(idx_vcm);

    v_cm_ref = interp1(t_vcm_w, v_cm_w, t_ref, 'linear', 'extrap');

    % --- PLOT VOLTAGE ---
    figure()
    plot(t_ref, v_real_ref, 'LineWidth', 2)
    hold on
    plot(t_ref, v_cm_ref, 'LineWidth', 2)
    grid on
    xlabel('Time [s]')
    ylabel('Voltage [V]')
    ylim([340 420])
    title('Real vs CarMaker Battery Voltage')
    legend('Real voltage','CarMaker voltage','Location','best')

else
    warning('V_cm_real n''existe pas. Comparaison tension ignoree.');
end