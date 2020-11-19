clc;clear;close all;
addpath('D:\ProgramFile\MatlabR2019b\work\codes\Speech\SpeechAddNoise\results_speech\dataset');
%% Algorithm
% SNR=[-5 0 5 10 15];
clc;
ov=4;                                                      %overlap factor
inc=128;                                                 %increment
nw=inc*ov;                                             %window length
W=hamming(nw,'periodic');                %hamming window
W=W/sqrt(sum(W(1:inc:nw).^2));        %normalize window                 
method='spJSLMP';                              %'LpADM'
% SNR=[-5 0 5 10 15];
tic
for i=1:1
%     length(SNR)
   filename1=['rec_REF_',num2str(i),'.wav']; %filename=['CrackMusic',num2str(SNR(i)),'.wav'];
    [GT,~]=audioread('rec_GT_1.wav');
    [LSAR,~]=audioread('rec_LSAR_1.wav');
    [s,fs]=audioread(filename1);
    filename2=['rec_ORG_',num2str(i),'.wav'];
    [clean,~]=audioread(filename2); 
    Y1=enframe(clean,W,inc);
    Y2=enframe(GT,W,inc);
    Y3=enframe(LSAR,W,inc);
    Y=enframe(s,W,inc); %enframe,specify window type and inc
    rec=zeros(size(Y)); 
    p=2;q1=1;q2=q1;
    tic
    for j=1394:1394  %size(Y,1)
        if strcmp(method,'spJSLMP')
            if j==1
                [rec(j,:),flag]=spJSLMP(Y(j,:),q1,q2,p,'normal');                 %JSLMP DCT filter 
            else
                rec(j,:)=spJSLMP(Y(j,:),q1,q2,p,'normal',rec(j-1,:)');
            end
        elseif strcmp(method,'LpADM')
            if j==1
                [rec(j,:)]=LpADM(Y(j,:)',0.9,1);                 %JSLMP DCT filter 
            else
                rec(j,:)=LpADM(Y(j,:)',0.9,1,rec(j-1,:)');
            end
        end
          figure;plot(Y1(j,:),'r');xlim([0 length(rec(j,:))]);title('Original');
          figure;plot(rec(j,:),'b');xlim([0 length(rec(j,:))]);title('Proposed_rec');
%           figure;plot(Y2(j,:),'k');xlim([0 length(rec(j,:))]);title('GT');
%           hold  on;plot(Y(j,:),'r');
          figure; plot(Y3(j,:),'-');xlim([0 length(rec(j,:))]);title('LSAR');
          figure;plot(Y(j,:));xlim([0 length(rec(j,:))]);title('REF')
%           plot(Y1(j,:),'r');legend('SAR','JS','Lp','true');
    end
     toc
%     X=v_overlapadd(rec,W,inc);              %reconstruct
%     filename3=['rec_',method,'_',num2str(i),'.wav'];
%     audiowrite(filename3,X,fs);
end
