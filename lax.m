
% Function lax(Nspace,Ntime,Real_Tau,Params,varargin)
%
% Simulates traffic flow.
% lax and lax wendroff methods are used
%
% Input:
%
%   Nspace  	integer, number of spatial grid points
%
%   Ntime    	integer, number of time steps
%
%   Real_Tau     real, time step in units of critical time step > 1 unstable.
%
%   Params       parameters, [LENGHT,MAXIMUM VELOCITY, MAXIMUM DENSITY]
%
%   varargin    lax or lax
%               output a Contour, ColourPlot, SnapShot, or
%               conservedervative plots 
%                problems to be solved :
%               Stoplight, Overdense, or Underdense simulations.
%                
% Output:
%     plots( Contour, ColourPlot, SnapShot, or conservedervative )  traffic flow stimulation 
%  
%
function [a,x,t] = lax(Nspace,Ntime,Real_Tau,Params,varargin)
%% paramter verification
cp = false;

lxwen = false;
ss = false;
intg = false;
over_dense = false;
conserved = false;
lx = false;
stop_light = false;

cont = false;
un_dens = false;
if nargin > 4
    for i = 1:nargin-4
        if strcmp(varargin{i},'SnapShot')
            ss = true;
        elseif strcmp(varargin{i},'ColourPlot')
            cp = true;
        
        elseif strcmp(varargin{i}, 'Stoplight')
            stop_light = true;
        elseif strcmp(varargin{i}, 'Integrator')
            intg = true;
        elseif strcmp(varargin{i}, 'Contour')
            cont = true;
        elseif strcmp(varargin{i}, 'Conserve')
            conserved = true;
       
        elseif strcmp(varargin{i}, 'Lax Wendroff')
            lxwen = true;
         elseif strcmp(varargin{i}, 'Lax')
            lx = true;
         elseif strcmp(varargin{i}, 'Underdense')
            un_dens = true;   
       
        elseif strcmp(varargin{i}, 'Overdense')
            over_dense = true;
      
        end
    end
elseif nargin < 4
    disp('More Values Required')
end
%% paramters declartion and setting


L = Params(1); VM = Params(2); DM = Params(3);

x = linspace(-L/2,L/2,Nspace);
h = x(2) - x(1);

Tau = Real_Tau*(h/VM);
t = 0:Tau:Ntime*Tau;
t = t(1:end-1);

b = VM*Tau/h;
b_t = (VM*(Tau/h))^2;

%Initial Conditions
a = zeros(Nspace,Ntime);
[~, bcfirst] = min(abs(x+400));
[~, bcsecond] = min(abs(x));

if Real_Tau > 1
    disp('Warning, usnatabilty may occur')
end

   
    
    
%% lxwen  

if lxwen
        
    if stop_light
        a(bcfirst:bcsecond,1) = 1;
        a(bcsecond,1) = 1/2;
    elseif un_dens
        a(:,1) = 0.9 - 0.8*exp(-x.^2/400);
    elseif over_dense
        a(:,1) = 0.1 + 0.8*exp(-x.^2/400);
    else 
        disp('choose either "Stoplight", "Overdense", or "Underdense"')
    end
    
    
    cars_num = zeros(1,Ntime);
    conservederve = zeros(1,Ntime);
    for n=2:Ntime
        t(n) = (n-1)*Tau;
        F = @(a) a - a.^2/DM;
        c = @(a) 1 - a/DM;
        c2 = @(a) a/DM;
        for i=2:Nspace-1
            
            a(i,n) = a(i,n-1) - b/2*(F(a(i+1,n-1)) - F(a(i-1,n-1))) ...
                + b_t/2*(((c(a(i+1,n-1)) - c2(a(i,n-1)))*(F(a(i+1,n-1)) ...
                - F(a(i,n-1)))) - (c(a(i-1,n-1)) - c2(a(i,n-1))) ...
                * (F(a(i,n-1)) - F(a(i-1,n-1))));
            a(1,n) = 0.5*(1+b+b_t)*a(end, n-1) + 0.5*(1-b-b_t)*a(2,n-1);
            a(end,n) = 0.5*(1+b+b_t)*a(end-1, n-1) + 0.5*(1-b-b_t)*a(1,n-1);
            
            cars_num(n) = h * ((a(1,n) + a(end,n))/2 + sum(a(2:(end-1),n)));
            conservederve(n) = 1 - (cars_num(n)/cars_num(2));
            
        end
        
        if mod(n,10) == 0 && ss
            plot(x,a(:,n),'r');
            axis([x(1) x(end) min(a(:,1)) max(a(:,1))])
            xlabel('x');ylabel('Density of cars')
            title('Density of cars snapshot simulation')
            drawnow
            hold on
        end
    end
        
    hold off
  
%%



elseif lx        
    if stop_light %if a stop light,sudden shock
        a(bcfirst:bcsecond,1) = 1;
    elseif un_dens %if undesied 
        a(:,1) = 0.9 - 0.8*exp(-x.^2/400);
    elseif over_dense
        a(:,1) = 0.1 + 0.8*exp(-x.^2/400);
    else 
        disp('choose "Stoplight", "Overdense", or "Underdense"')
    end
                
    First_p = zeros(Nspace);
    second_p = zeros(Nspace);
    
    for i = 1:Nspace
        if i == 1 || i == Nspace
            First_p(i,i) = 1;
            second_p(i,i) = 1;
        else
            First_p(i,i-1) = 0.5*(1+b);
            First_p(i,i+1) = 0.5*(1-b);
            second_p(i,i-1) = -0.5*b/DM;
            second_p(i,i+1) = 0.5*b/DM;
        end
    end
    
    cars_num = zeros(1,Ntime);
    conservederve = zeros(1,Ntime);
    h = (x(end) - x(1))/length(x);
    for n = 1:Ntime-1
        
        a(:,n+1) = First_p*a(:,n) + second_p*(a(:,n).^2);
        a(1,n+1) = 0.5*(1+b)*a(end,n) + 0.5*(1-b)*a(2,n);
        a(end,n+1) = 0.5*(1+b)*a(end-1,n) + 0.5*(1-b)*a(1,n);
        cars_num(n) = h * ((a(1,n) + a(end,n))/2 + sum(a(2:(end-1),n)));
        conservederve(n) = 1 - (cars_num(n)/cars_num(1));
        
        if mod(n,10) == 0 && ss
            plot(x,a(:,n+1),'b');
            axis([x(1) x(end) min(a(:,1)) max(a(:,1))])
            xlabel('x');ylabel('cars Density')
            title('cars density snapshot simulation')
            drawnow
            hold on
        end
    end
     else
    disp('select "Lax" or "Lax Wendroff" methods')
end
        
   

%%  ploting Plots

if cp%%colourplot condition 
    imagesc([0 Ntime*Tau],[x(1) x(end)],a);colorbar;
    xlabel('Time');
    ylabel('Spatial Grid');
    zlabel('Density of cars');
    title('Colour plot of density of cars');
end


if cont% contour plot condition
    contour(t,x,a);
    xlabel('Time');
    ylabel('Spatial Grid');
    zlabel('Density of cars');
    title('Contour plot of traffic flow density');
    colorbar;
    
end

if intg
    plot(t(1:end-1),cars_num(1:end-1),'o');
    xlabel('time')
    ylabel('#of cars')
    title('#of cars at given time')
end

if conserved %conservederved
    plot(t,conservederve,'o');
    xlabel('Time')
    ylabel('conservedervation flow')
    title('conservation of cars through the simulation');
end
                

end
