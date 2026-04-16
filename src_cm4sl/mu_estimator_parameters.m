% ------ MU Motor Front / 2 Wheels Rear -------
g = 9.81;

lf = 1.214;
lr = 1.505;
h_cg = 0.55;

tw_f = 1.571;
tw_r = 1.581;

r0 = 0.344;
cs_tyre = 2.0e5;

eps_vx = 0.5;
fz_min = 300;
fz_max = 6000;

re_min = 0.28;
re_max = 0.33;

mu_min = 0.0;
mu_max = 1.5;

front_bias_brake = 0.6;
rear_bias_brake  = 0.4;

front_bias_drive = 1.0;
rear_bias_drive  = 0.0;

steer_th = 0.01;
ay_th = 0.5;
slip_angle_th = 1.0;

ay_strong_th = 1.5;
slip_angle_strong_th = 3.0;

i_front = 10.65;   

% g = 9.81;                 % gravité [m/s^2]
% 
% % Géométrie véhicule
% lf = 1.10;                % distance CG -> essieu avant [m]
% lr = 1.60;                % distance CG -> essieu arrière [m]
% h_cg = 0.55;              % hauteur CG [m]
% tw_f = 1.56;              % voie avant [m]
% tw_r = 1.56;              % voie arrière [m]
% 
% % Pneus
% r0 = 0.33;                % rayon nominal roue [m]
% cs_tyre = 2.0e5;          % raideur verticale pneu [N/m]
% 
% % Filtres
% tau_vx = 0.10;
% tau_ax = 0.10;
% tau_mu = 0.20;
% tau_slip = 0.10;
% tau_omega = 0.05;
% 
% % Protections numériques
% eps_vx = 0.5;             % évite division par zéro
% fz_min = 300;             % charge mini roue [N]
% fz_max = 6000;            % charge maxi roue [N]
% re_min = 0.28;            % rayon effectif mini [m]
% re_max = 0.33;            % rayon effectif maxi [m]
% mu_min = 0.0;
% mu_max = 1.5;
% 
% % Seuils logiques
% brake_th = 5;             % %
% throttle_th = 5;          % %
% 
% % Répartition simplifiée de Fx si on part de ax global
% front_bias_brake = 0.6;   % 60% avant en freinage
% rear_bias_brake  = 0.4;
% front_bias_drive = 1.0;   % traction avant par défaut
% rear_bias_drive  = 0.0;
% 
% %--------------- MU GLOBAL --------------------------
% g = 9.81;          % gravite [m/s^2]
% 
% lf = 1.10;         % CG -> essieu avant [m]
% lr = 1.60;         % CG -> essieu arriere [m]
% h_cg = 0.55;       % hauteur CG [m]
% 
% mu_min = 0.0;
% mu_max = 1.5;
% 
% steer_th = 0.01;
% ay_th = 0.5;
% slip_angle_th = 1.0;      % si slip angle en degres
% 
% ay_strong_th = 1.5;
% slip_angle_strong_th = 3.0;

