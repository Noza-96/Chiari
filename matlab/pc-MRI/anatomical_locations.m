clear all;
anatomy.location = {"FM", "C1", "C2", "C3",  "C4-C3", "C4"};

Dz = [-52.937,-67.492, -80.944,-104.147 , -113.412, -122.158]; 
anatomy.Dz = -(Dz-Dz(1));
% anatomy.FM = -45; % s101-a
% anatomy.FM = -55; % s101-b
% anatomy.FM = -58; % s101-aa

anatomy.FM = -56; % s101-aa
% anatomy.FM = -57; % s101-b
