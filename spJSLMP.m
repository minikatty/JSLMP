%--------------------------------------------------------
%objective function:
%     J(w(n),v(n))=1/p*[y(n)-x(n)^T*w(n)-v(n)_k]^p+
%   lambda_1||w(n)||_q1^q1+lambda_2||v(n)||_q2^q2
%                 0<=q2,q2<=1
%                      1<p<2  
%--------------------------------------------------------
function [res,flag]=spJSLMP(y,q1,q2,p,sym,x_int)
Max=max(abs(y));
y=y./Max;
L=length(y);iter_max=2e4;tol=1e-8;N=L;
n=1;flag=0;H=dctmtx(L);I=eye(L);
eta1=1e-2;eta2=2e-2;
lambda1=eta1/L;lambda2=eta2/L;        %adaptive filter parameters
if (nargin<6)
    w_prev=zeros(N,1); w_new=w_prev;          %primary adaptive filter tap weights
else                                                
     w_prev=x_int;w_new=w_prev; 
end 
   v_prev=zeros(L,1);                                               %secondary adaptive filter tap weights
%H=dctmtx(L);                                                       %speech deniose  with DCT
    tau=1e-8;                                                         % cliping threshold 
    var=zeros(iter_max,1);
%------------------------Adam Parameter+ VSS Setting---------------------------
m1=zeros(N,1);v1=m1;m2=zeros(L,1);v2=m2;epsilon1=1e-8;
alpha=1e-3;beta1=0.9;beta2=1-1e-3;epsilon=1e-8;alpha1=5;
mu=0.2;mu_max=mu;mu_min=1e-3;mu_pre=mu; 
% label=0;
%-----------------------------------------------------------------------------
if (q1==0)
    g1=@(X,e,w_prev)(-X*abs(e)^(p-1)*sign(e)+lambda1*alpha1*...
    sign(w_prev).*gfun(alpha1,w_prev));
elseif (q1==1)
    g1=@(X,e,w_prev)(-X*abs(e)^(p-1)*sign(e)+lambda1.*sign(w_prev));    
else
    if  strcmp(sym,'reweighted')
      g1=@(X,e,w_prev)((lambda1*q1./(abs(w_prev).^(1-q1)+epsilon1))...
    .*sign(w_prev)-X*abs(e)^(p-1)*sign(e));
    elseif strcmp(sym,'normal')
    g1=@(X,e,w_prev)((lambda1*q1./(abs(w_prev).^(1-q1)+epsilon1))...
    .*sign(w_prev)-X*abs(e)^(p-1)*sign(e)); 
    else        
       error('argument ''sym''  is wrong.');
    end    
end

if (q2==0)
     g2=@(Ik,e,v_prev)(-Ik*abs(e)^(p-1)*sign(e)+lambda2*alpha1*...
    sign(v_prev).*gfun(alpha1,v_prev));
elseif (q2==1)
    g2=@(Ik,e,v_prev)(-Ik*abs(e)^(p-1)*sign(e)+lambda2.*sign(v_prev));
else
    if strcmp(sym,'reweighted')
        g2=@(Ik,e,v_prev)((lambda2*q2./(abs(v_prev).^(1-q2)+epsilon1))...
    .*sign(v_prev)-Ik*abs(e)^(p-1)*sign(e));
    elseif strcmp(sym,'normal')
        g2=@(Ik,e,v_prev)((lambda2*q2./(abs(v_prev).^(1-q2)+epsilon1))...
    .*sign(v_prev)-Ik*abs(e)^(p-1)*sign(e));
    else
        error('argument ''sym''  is wrong.');
    end
end

while (n~=1 && norm(w_prev-w_new)>tol && n<=iter_max) || n==1    
    k=mod(n,L)+1; 
    d=y(k);
    X=H(k,:)'; Ik=I(k,:)';    
    w_prev=w_new;
%     MSD(n)=sum((w_prev-w_true).^2);
    e=d-X'*w_prev-Ik'*v_prev;
    var(n)=abs(e);
    gra1=g1(X,e,w_prev); % primary gradient
    gra2=g2(Ik,e,v_prev); % secondary gradient   
    
    if flag      
        m1=beta1*m1+(1-beta1)*gra1;                  % update bias first moment estimate
        v1=beta2*v1+(1-beta2)*(gra1.*gra1);            % update biased second raw moment estimate
        m11=m1/(1-beta1^(n+1));                  % compute biased-corrected first moment estimate
        v11=v1/(1-beta2^(n+1));                     % compute biased-corrected second raw moment estimate
        %alpha1_new(n)=alpha*sqrt(1-beta2^(n+1))/(1-beta1^(n+1));
        w_new=w_prev-alpha*m11./(sqrt(v11)+epsilon);% update parameters 
                                                         
        m2=beta1*m2+(1-beta1)*gra2;                  % update bias first moment estimate
        v2=beta2*v2+(1-beta2)*(gra2.*gra2);         % update biased second raw moment estimate
        m21=m2/(1-beta1^(n+1));                          % compute biased-corrected first moment estimate
        v21=v2/(1-beta2^(n+1));
        v_new=v_prev-alpha*m21./(sqrt(v21)+epsilon);     
        v_prev=v_new;        
         if (var(n)<=tau) && (n>3e3)
                flag=0;
%                 label=n;
                continue;
         end
         
    else        
%-------------------------------------------------
    % VSS mechanism      
        mu_new=0.9999999*mu_pre+1e-1*e^2;
%     mu_new=0.95*mu_old+5e1*e^2;
         if  mu_new>mu_max
                mu=mu_max;
        elseif mu_new<mu_min
                mu=mu_min;
         else
                mu=mu_new;    
         end
         mu_pre=mu_new;
    %-------------------------------------------------     
    w_new=w_prev-mu*gra1;         %gama= mu*lambda
    v_new=v_prev-mu*gra2;
    v_prev=v_new; 
    end 
    n=n+1;    
end    
% JSLMP.para=w_new;

% JSLMP.flag=flag;
% JSLMP.label=label;
res=H*w_new.*Max;
end