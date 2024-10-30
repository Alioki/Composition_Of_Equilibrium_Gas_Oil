clc
clear
close all
%%

% eqn = (0.61/(1+ny*(200/350-1)))+(0.28/(1+ny*(200/105-1)))+(0.11/(1+ny*(200/37-1))) == 1;
% assume(ny>0 & ny<1)
% sl=solve(eqn,ny);
% a=double(sl);



%% given data
n=3;%componts number
phase=2; 

MF = xlsread('data.xlsx','C2:C4');%mol-fraction
Tc = xlsread('data.xlsx','D2:D4');%critcal temp (R)
Pc = xlsread('data.xlsx','E2:E4');%critcal pressure (psi)
W = xlsread('data.xlsx','F2:F4');% Acentric factor
Pv = xlsread('data.xlsx','G2:G4');%vapor pressure (psi)
temp = 160;%(F)
p = 1000;%(psi)
R = 10.73;

%% set paramiters
syms ny z
zz=zeros(1,phase);
ac = zeros(1,n);
alpha_sq = zeros(1,n);
aT = zeros(1,n);
b = zeros(1,n);
k_i=zeros(1,n);
x=zeros(1,n);
y=zeros(1,n);
in_coef=zeros(n);%interaction coefications
in_coef(1,[2 3])=[0.02 0.04];
in_coef([2 3],1)=[0.02 0.04];
aTT=zeros(1,phase);
bb=zeros(1,phase);
A=zeros(1,phase);
B=zeros(1,phase);
MF=MF';
APL=zeros(1,n);
BPL=zeros(1,n);
APG=zeros(1,n);
BPG=zeros(1,n);


POL = zeros(1,n);
POG = zeros(1,n);
ntime=4;
K=zeros(n);
alpha_h=0;
%% data proccess

for i=1:n  
    ac(i)= 0.45724*R^2*Tc(i)^2/Pc(i);  
end
for i=1:n  
    b(i)= 0.0778*R*Tc(i)/Pc(i);  
end
for i=1:n  
    alpha_sq(i)= 1+(0.3764+1.54226*W(i)-0.2699*W(i)^2)*(1-sqrt((temp+459.67)/Tc(i)));  
end
for i=1:n  
    aT(i)= ac(i)*alpha_sq(i)^2;  
end
    
cont=1/ntime;
% sprintf('Calculating i = %d, j = %d',0,0)
hWaitbar = waitbar(0,"waitbar"); % create the waitbar
for u=1:ntime
        waitbar(cont, hWaitbar, "waitbar") % update the waitbar
        cont = cont + 1/(ntime);
        pause(rand/10); 
    
    
    
if u==1
    
    for i=1:n  
    k_i(i)= Pv(i)/p;  
    end
%k_i=[3.992 0.2413 0.00340];
%k_i=[3.3736 0.1279 0.000823];
% k_i=[4.1298 0.2309 0.0028];
%k_i=[4 0.2357 0.0031];
%k_i=[3.9924 0.2359 0.0031]; 
    K=k_i;
end

eq_S=sum(MF(1:n)./(1+ny.*(1./K(1:n)-1)))==1;
sl=vpasolve(eq_S,ny,[0.00001 1]);
assume(ny>0 & ny<1)
nl=double(sl);
% pretty(simplify(eq_S))
% pretty(collect(eq_S))


    for i=1:n  
        x(i)= MF(i)/(1+(1-nl)*(K(i)-1));  
    end
    for i=1:n  
        y(i)= MF(i)/(1+nl*(1/K(i)-1));  
    end

    aTT(:)=0;
    for i=1:n
       for j=1:n
         aTT(1) = aTT(1)+x(i)*x(j)*sqrt(aT(i)*aT(j))*(1-in_coef(i,j));
       end
    end
    
    for i=1:n
       for j=1:n
         aTT(2) = aTT(2)+y(i)*y(j)*sqrt(aT(i)*aT(j))*(1-in_coef(i,j));
       end
    end
    bb(:)=0;
     for i=1:n
       
         bb(1) = bb(1)+x(i)*b(i);
       
    end
    
    for i=1:n
       
         bb(2) = bb(2)+y(i)*b(i);
       
    end
    
    for i=1:phase
        A(i)=aTT(i)*p/((R*(temp+459.67))^2);
    end
    for i=1:phase
        B(i)=bb(i)*p/(R*(temp+459.67));
    end
    
    for i=1:phase
        zeq = z^3-(1-B(i))*z^2+(A(i)-2*B(i)-3*B(i)^2)*z-(A(i)*B(i)-B(i)^2-B(i)^3)==0;
        assume(z>0 & z<1)
        zsl=solve(zeq,z);
        zn=double(zsl);
        zz(i) = zn;
    end

    
    for i=1:n
        alpha_h=0;
        for w=1:n
            alpha_h=alpha_h+x(w)*sqrt(aT(w))*(1-in_coef(i,w));
        end
           APL(i)=(1/aTT(1))*2*sqrt(aT(i))*alpha_h;
         BPL(i)=b(i)/bb(1);
    end
    
    for i=1:n
        alpha_h=0;
         for w=1:n
            alpha_h=alpha_h+y(w)*sqrt(aT(w))*(1-in_coef(i,w));
         end
            APG(i)=(1/aTT(2))*2*sqrt(aT(i))*alpha_h*(1-in_coef(i,1));
         BPG(i)=b(i)/bb(2);
    end
    
    
    
    for i=1:n
        L=(zz(1)-1)*BPL(i)-log(zz(1)-B(1))-(A(1)*(APL(i)-BPL(i))*log((zz(1)+(sqrt(2)+1)*B(1))/(zz(1)-(sqrt(2)-1)*B(1)))/(sqrt(8)*B(1)));
        POL(i)=exp(L);
    end
    for i=1:n
        L=(zz(2)-1)*BPG(i)-log(zz(2)-B(2))-(A(2)*(APG(i)-BPG(i))*log((zz(2)+(sqrt(2)+1)*B(2))/(zz(2)-(sqrt(2)-1)*B(2)))/(sqrt(8)*B(2)));
         POG(i)=exp(L);
         
    end
    
    for i=1:n
        K(i)=POL(i)/POG(i);
    end
    
      
end
close(hWaitbar);
K