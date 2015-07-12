%% This file visulaized the calculated transfer rates
clear all; clc; fig=0;
close all;

%%

dir='C:\Users\Amirhossein\Google Drive\Research\Exciton\Data\test-rates\Transfer-(07,05)-Ex0_A2-iSub(1)-Length(00nm)-Center(00nm)-Ckappa(2.0)-to-(07,05)-Ex0_Ep-iSub(1)-Length(00nm)-Center(00nm)-Ckappa(2.0)-C2C( 1.2nm- 1.2nm)-Theta(000-090)-partition(1)\';
FileName=[dir,'transitionRates12.dat'];
kappa12=load(FileName);

FileName=[dir,'transitionRates21.dat'];
kappa21=load(FileName);

FileName=[dir,'theta.dat'];
theta=load(FileName);

FileName=[dir,'c2c.dat'];
c2c=load(FileName);

%%
% fig=fig+1; figure(fig); hold on; box on;
% surf(theta,c2c,kappa12,'EdgeColor','none');
% axis tight;
% 
% fig=fig+1; figure(fig); hold on; box on;
% surf(theta,c2c,kappa21,'EdgeColor','none');
% axis tight;

%%
nTheta = numel(theta);
fig=fig+1; figure(fig); box on;
plot(theta(1:nTheta),kappa12(1:nTheta),'-','LineWidth',3); hold on;
axis tight;

fig=fig+1; figure(fig); box on;
plot(theta(1:nTheta),kappa21(1:nTheta),'-','LineWidth',3); hold on;
axis tight;

%%
% fig=fig+1; figure(fig); hold on; box on;
% plot(c2c/1e-9,kappa12,'-k','LineWidth',3);
% 
% figure(fig); hold on; box on;
% plot(c2c/1e-9,kappa21,'-r','LineWidth',3);
% axis tight;
return;
%%
clear all;

r1=1;
r2=5;
thetaMax=2*pi;
thetaMin=0;
ntheta=100;
theta1=linspace(thetaMin,thetaMax,ntheta);
theta2=linspace(thetaMin,thetaMax,ntheta);
D=10;
y=zeros(ntheta,ntheta);

for i=1:ntheta
    for j=1:ntheta
%         y(i,j)=(r1*sin(theta1(i))-r2*sin(theta2(j)))^2+(D+r1*cos(theta1(i))-r2*cos(theta2(j)))^2;
        y(i,j)=(r1*sin(theta1(i)-theta1(j)))^2+(D+r2*cos(theta1(i)-theta1(j)))^2;
    end;
end;

fig=100;
fig=fig+1; figure(fig); box on;
surf(theta1,theta2,y);
axis equal;
axis tight;