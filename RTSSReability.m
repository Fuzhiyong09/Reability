clc
warning off
%-----------������������Ԥ��ģ�͵Ŀɿ�������----------------------%
clear Pf_m
%% �����ȡ��������
M = 125; 
nsample = 100;
j = 1;

for i = 1:nsample
	%% �������ѵ�����ű�
    K = 15 ; %���Լ�26< = K< =40
    a = (randperm(125))';%ԭʼ��������Ǵ�41��ʼ�����Լ�40������41:120����������
    b = a(1:(M-K),:);% ��ȡѵ�����ű�
    c = a(M-K+1:end,:); % ��ȡ���Լ��ű�
	
	%% ��ȡѵ����
    P_train = Trail(b,1:8); %ȷ��ѵ�������շ����ؼ��� 
    T_train = Trail(b,10);%��ȡλ��ѵ����
    
    [p_train, ps_input]= mapminmax(P_train',0,1);  %�������ݹ�һ��
    [t_train, ps_output]= mapminmax(T_train',0,1); 
    %% ��ȡ���Լ�
    P_test = Trail(c,1:8); %ȷ�����Լ��շ����ؼ���
    T_test = Trail(c,10);  %��ȡ��һ�����λ�Ʋ��Լ�    
    
    p_test = mapminmax('apply', P_test',ps_input);  %�������ݷ���һ��
    %% �������ɭ�ֻع���
    model = regRF_train(P_train,T_train,1000,7); 
    net = newff(p_train, t_train,[8,8]);
   
    % ����������
    net.trainParam.showWindow = false;  % �رյ���
    net.trainParam.showCommandLine = false;
    net.trainParam.epochs = 1000; % �������������
    net.trainParam.goal = 1e-3;
    net.trainParam.lr = 0.01;

    net = train(net, p_train, t_train); % ѵ������
    
    %% λ��Ԥ��
    rfPreTr = regRF_predict(P_train,model);  
    rfPreT = regRF_predict(P_test,model);
    
    bpPretr = sim(net,p_train);  
    bpPret = sim(net,p_test );
    
    %������ݷ���һ��
    bpPreTr = mapminmax('reverse', bpPretr, ps_output);
    bpPreT = mapminmax('reverse', bpPret, ps_output);
    
	%% ���ؿ���ģ�����
	Gx = zeros(K,1);Tx = zeros(K,1);Fx = zeros(K,1); %��ʼ������
	
	%��⹦�ܺ���
	for n = 1:K; %��ͬ����¼���״̬����
		if rfPreT(n) * T_test(n)<0;
		  Gx(n) = 0;
		  Tx(n) = 1;
		elseif abs(rfPreT(n))> abs(T_test(n)); %���Լ�λ�ƾ���ֵ����ԭʼλ�ƾ���ֵ
		  Gx(n) = abs(T_test(n))/abs(rfPreT(n));
		  Tx(n) = 1 - Gx(n);
		else  %���Լ�λ�ƾ���ֵ����ԭʼλ�ƾ���ֵ
		  Gx(n) = abs(rfPreT(n))/abs(T_test(n));
		  Tx(n) = 1 - Gx(n);
		end
	
	    Fx(n) = 0.25* Gx(n)./Tx(n) - 1;
	    if Fx(n) < 0
			Rorf(j) = 1;
	    else 
			Rorf(j) = 0;
        end 
        
		if bpPreT(n) * T_test(n)<0;
		  Gxb(n) = 0;
		  Txb(n) = 1;
		elseif abs(bpPreT(n))> abs(T_test(n)); %���Լ�λ�ƾ���ֵ����ԭʼλ�ƾ���ֵ
		  Gxb(n) = abs(T_test(n))/abs(bpPreT(n));
		  Txb(n) = 1 - Gxb(n);
		else  %���Լ�λ�ƾ���ֵ����ԭʼλ�ƾ���ֵ
		  Gxb(n) = abs(bpPreT(n))/abs(T_test(n));
		  Txb(n) = 1 - Gxb(n);
		end
	
	    Fxb(n) = 0.25*Gxb(n)./Txb(n) - 1;
	    if Fxb(n) < 0
			Robp(j) = 1;
	    else 
			Robp(j) = 0;
        end 
        
          
       %% �洢��ͼ���� 
        picturePara(j,1) = c(n); %�ű����
        picturePara(j,2) = rfPreT(n); %rfԤ��λ�ƾ���
        picturePara(j,5) = bpPreT(n); %bpԤ��λ�ƾ���
        picturePara(j,3) = T_test(n); %ԭʼλ�ƾ���
        picturePara(j,4) = i; %������������ 
       
        j = j+1;

	end

end

%% ����ģ���ƻ�����
% �������ɭ�ֱ���ϵ��
Prf_m = mean (Rorf) % ����ʧЧ����
Prf_stand = sqrt(Prf_m*(1 - Prf_m)./size(Rorf,2)); %��ƫ��׼��
Yiburf = Prf_stand/ Prf_m %����ģ�ͱ���ϵ��

% ����bp���������ϵ��
Pbp_m = mean (Robp) % ����ʧЧ����
Pbp_stand = sqrt(Pbp_m*(1 - Pbp_m)./size(Robp,2)); %��ƫ��׼��
Yibubp = Pbp_stand/ Pbp_m %����ģ�ͱ���ϵ��

%% -------------��ͼ----------------------%
% ��������洢�űꡢԤ��λ�ơ�ԭʼλ�ƺͳ������� 

Index = picturePara(:,1); %�ű����
rfPredictDis = picturePara(:,2); %rfԤ��λ��
bpPredictDis = picturePara(:,5); %bpԤ��λ��
OriginDis = picturePara(:,3); %ԭʼλ��
SampleSeries = picturePara(:,4); %��������
DrawOriginDis = Trail(:,10); %ԭʼ����

rfError = rfPredictDis - OriginDis;


%% ---������ά��ͼ����---

x1 = Index; y1 = SampleSeries; z1 = rfError;
% ��ϡ
x = x1(1:3000); y = y1(1:3000); z =z1(1:3000);

[X, Y] = meshgrid(min(x):0.5:max(x), min(y):0.5:max(y));
Z = griddata(x,y,z,X,Y,'v4');
figure(1);
surf(X,Y,Z)
shading interp;
colormap(jet);

x3d = X(:); y3d = Y(:); z3d = Z(:); 

%�ֲ��Ŵ�ͼ
SelectIndex = 114:125;
LogitPartIndex = ismember(Index,SelectIndex);
PartIndex = Index(LogitPartIndex);
PartRfPre = rfPredictDis(LogitPartIndex);
PartRfPre121 = rfPredictDis(Index ==121);

%% �ֲ�ָ�����
PartRfPre14 = rfPredictDis(1:14);
PartOrPre14 = OriginDis(1:14);

Rmse14 = sqrt(mse(PartRfPre14, PartOrPre14));
R2_14 = 1 - Rmse14/var(PartOrPre14); 

%ȫ��ָ��
RmseBP = sqrt(mse(bpPredictDis,OriginDis));
RmseRF = sqrt(mse(rfPredictDis, OriginDis));
RFR2 = 1 - RmseRF/var(OriginDis);
BPR2 = 1 - RmseBP/var(OriginDis);

MaxPreRF = zeros(125,1);
MinPreRF = zeros(125,1);
MaxPreBP = zeros(125,1);
MinPreBP = zeros(125,1);
for num = 1:max(Index)
    MaxPreRF(num) = max(rfPredictDis(Index == num));
    MinPreRF(num) = min(rfPredictDis(Index == num));
    MaxPreBP(num) = max(bpPredictDis(Index == num));
    MinPreBP(num) = min(bpPredictDis(Index == num));
end
