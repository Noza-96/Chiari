close all;
clear;
blue = [0, 0.4470, 0.7410]	; red = [0.6350, 0.0780, 0.1840]; green = [62 150 81]./255; yellow = [0.9290, 0.6940, 0.1250]; black = [0, 0, 0]; white = [1, 1, 1]; gray = [0.5, 0.5, 0.5];

load("pressure_drop.mat")
Y  = fft(p);

M=10;
pp=fft(p)/length(p);
am=pp(2:M+1);
fm= 1i*2*pi*[1:M];
pF=0;

for m=1:M
    pF=pF+am(m)*exp(fm(m)*t) +conj(am(m)) * exp(-fm(m)*t);
end

figure

    plot(t,pF,'-',LineWidth=1.5,Color=blue)
    hold on 
    % plot(t,p,'-',LineWidth=1.5,Color='r')
    plot(t,t*0,'--',LineWidth=1,Color='k')  
    set(gca,'LineWidth',1,'TickLength',[0.01 0.01])
    set(gca,'FontSize',12)
    xlabel("$t/T$",Interpreter="latex",FontSize=20)
    ylabel("$\Delta p \,\,[{\rm Pa}]$",Interpreter="latex",FontSize=20)
    set(gcf,'Position',[200,200,300,200]) 
    ylim([-10,18])
    
sstt="Delta_p";
print(sstt,'-depsc')