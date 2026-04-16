clc
clear all
close all
%run('SaveData.m')
close all
Table_SoCvsOCV=load("SoC_to_Voltage_LUT_10000-GON.mat");
load('Battery_A123_Pack_204s2p_Final.mat')
OCV=Table_SoCvsOCV.LUT.Voltage_V;
SoC_bp = Table_SoCvsOCV.LUT.SoC_percent;

dOCV_dSoC = gradient(OCV, SoC_bp);

figure()
subplot(2,1,1)
plot(SoC_bp, OCV, 'o-', 'LineWidth', 0.1)
grid on
xlabel('SoC [-]')
ylabel('OCV [V]')
title('OCV vs SoC')

subplot(2,1,2)
plot(SoC_bp, dOCV_dSoC, 'o-', 'LineWidth', 1.5)
grid on
xlabel('SoC [-]')
ylabel('dOCV/dSoC [V per unit SoC]')
title('Derivative of OCV vs SoC')


%% Derivate R0

R0 = Battery.R0_LUT(:,3).*(2/204);
SoC_L=Battery.SOC_LUT;
dR0 = gradient(R0, SoC_L);


figure()
subplot(2,1,1)
plot(SoC_L, R0, 'o-', 'LineWidth', 1.5)
grid on
xlabel('SoC [-]')
ylabel('OCV [V]')
title('OCV vs SoC')

subplot(2,1,2)
plot(SoC_L, dR0, 'o-', 'LineWidth', 1.5)
grid on
xlabel('SoC [-]')
ylabel('dOCV/dSoC [V per unit SoC]')
title('Derivative of OCV vs SoC')

current_data = [time_current(:), B_current_fixed(:)];
figure(3)
plot(time_current(:),B_current_fixed(:))