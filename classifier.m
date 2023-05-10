sample_data = load('fail_sucess_sum.mat');
fail_data = sample_data.fail_sum;
sucess_data = sample_data.sucess_sum;
fail_X_data = fail_data(:,1:end-1);
fail_Y_data = fail_data(:,end);
sucess_X_data = sucess_data(:,1:end-1);
sucess_Y_data = sucess_data(:,end);

% 计算统计时间、样本数量
dur_time = (size(fail_data,2)-1)/3;
N_fail = size(fail_data,1);
N_sucess = size(sucess_data,1);
%简化二分类
fail_Y_label = zeros(length(fail_Y_data),1);
sucess_Y_label = sucess_Y_data;

%% 处理特征
fail_psr = fail_X_data(:,1:30);
fail_apce = fail_X_data(:,31:60);
fail_max_response = fail_X_data(:,61:90);
sucess_psr = sucess_X_data(:,1:30);
sucess_apce = sucess_X_data(:,31:60);
sucess_max_response = sucess_X_data(:,61:90);

% 3d特征，每个通道代表一种特征
fail_data_3d(:,:,1) = fail_psr;
fail_data_3d(:,:,2) = fail_apce;
fail_data_3d(:,:,3) = fail_max_response;
sucess_data_3d(:,:,1) = sucess_psr;
sucess_data_3d(:,:,2) = sucess_apce;
sucess_data_3d(:,:,3) = sucess_max_response;

% 减均值除以方差归一化
for k =1:3
    fail_data_3d_mean(:,:,k) = sum(fail_data_3d(:,1:end-3,k),2)/(dur_time-3);
    fail_data_3d_std(:,:,k) = std(fail_data_3d(:,1:end-3,k),0,2);
    fail_data_3d_norm(:,:,k) = (fail_data_3d(:,:,k) - fail_data_3d_mean(:,:,k))./fail_data_3d_std(:,:,k);
    fail_entropy_mat(:,:,k) = -abs(fail_data_3d_norm(:,:,k))*log(abs(fail_data_3d_norm(:,:,k)))';
    fail_entropy_v(:,:,k) = diag(fail_entropy_mat(:,:,k));
    
    sucess_data_3d_mean(:,:,k) = sum(sucess_data_3d(:,1:end-3,k),2)/(dur_time-3);
    sucess_data_3d_std(:,:,k) = std(sucess_data_3d(:,1:end-3,k),0,2);
    sucess_data_3d_norm(:,:,k) = (sucess_data_3d(:,:,k) - sucess_data_3d_mean(:,:,k))./sucess_data_3d_std(:,:,k);
    sucess_entropy_mat(:,:,k) = -abs(sucess_data_3d_norm(:,:,k))*log(abs(sucess_data_3d_norm(:,:,k)))';
    sucess_entropy_v(:,:,k) = diag(sucess_entropy_mat(:,:,k));
end

%% 计算归一化下降率
for k = 1:3
    for j = 2:30
        fail_norm_descend_rate(:,j,k) = fail_data_3d_norm(:,j,k)-fail_data_3d_norm(:,j-1,k);
        sucess_norm_descend_rate(:,j,k) = sucess_data_3d_norm(:,j,k)-sucess_data_3d_norm(:,j-1,k);
    end
end

% 计算变化量
fail_psr_ascend_rate = zeros(size(fail_psr));
fail_apce_ascend_rate = zeros(size(fail_apce));
fail_max_response_ascend_rate = zeros(size(fail_max_response));
sucess_psr_ascend_rate = zeros(size(sucess_psr));
sucess_apce_ascend_rate = zeros(size(sucess_apce));
sucess_max_response_ascend_rate = zeros(size(sucess_max_response));

for i = 2:30
    fail_psr_ascend_rate(:,i) = (fail_psr(:,i) - fail_psr(:,i-1))./fail_psr(:,i-1);
    fail_apce_ascend_rate(:,i) = (fail_apce(:,i) - fail_apce(:,i-1))./fail_apce(:,i-1);
    fail_max_response_ascend_rate(:,i) = (fail_max_response(:,i) - fail_max_response(:,i-1))./fail_max_response(:,i-1);
    sucess_psr_ascend_rate(:,i) = (sucess_psr(:,i) - sucess_psr(:,i-1))./sucess_psr(:,i-1);
    sucess_apce_ascend_rate(:,i) = (sucess_apce(:,i) - sucess_apce(:,i-1))./sucess_apce(:,i-1);
    sucess_max_response_ascend_rate(:,i) = (sucess_max_response(:,i) - sucess_max_response(:,i-1))./sucess_max_response(:,i-1);
end


% 计算上升与下降次数
Ascend_flag = true;
if Ascend_flag
    fail_psr_flag = zeros(size(fail_psr));
    fail_apce_flag = zeros(size(fail_apce));
    fail_max_response_flag = zeros(size(fail_max_response));
    sucess_psr_flag = zeros(size(sucess_psr));
    sucess_apce_flag = zeros(size(sucess_apce));
    sucess_max_response_flag = zeros(size(sucess_max_response));
    % 统计上升下降次数
    for i = 2:30
        fail_psr_flag(:,i) = (fail_psr(:,i) - fail_psr(:,i-1))>0;
        fail_apce_flag(:,i) = (fail_apce(:,i) - fail_apce(:,i-1))>0;
        fail_max_response_flag(:,i) = (fail_max_response(:,i) - fail_max_response(:,i-1))>0;
        sucess_psr_flag(:,i) = (sucess_psr(:,i) - sucess_psr(:,i-1))>0;
        sucess_apce_flag(:,i) = (sucess_apce(:,i) - sucess_apce(:,i-1))>0;
        sucess_max_response_flag(:,i) = (sucess_max_response(:,i) - sucess_max_response(:,i-1))>0;
    end
    % 统计上升率与下降比率
    fail_psr_ascend_ratio = sum(fail_psr_flag,2)/dur_time;
    fail_apce_ascend_ratio = sum(fail_apce_flag,2)/dur_time;
    fail_max_response_ascend_ratio = sum(fail_max_response_flag,2)/dur_time;
    sucess_psr_ascend_ratio = sum(sucess_psr_flag,2)/dur_time;
    sucess_apce_ascend_ratio = sum(sucess_apce_flag,2)/dur_time;
    sucess_max_response_ascend_ratio = sum(sucess_max_response_flag,2)/dur_time;
    % 最后last帧上升状态
    last_N = 2;
    fail_psr_ascend_last = fail_psr_flag(:,end-last_N:end);
    fail_apce_ascend_last = fail_apce_flag(:,end-last_N:end);
    fail_max_response_ascend_last = fail_max_response_flag(:,end-last_N:end);
    sucess_psr_ascend_last = sucess_psr_flag(:,end-last_N:end);
    sucess_apce_ascend_last = sucess_apce_flag(:,end-last_N:end);
    sucess_max_response_ascend_last = sucess_max_response_flag(:,end-last_N:end);
end

%% 组合特征
% 归一化数据、上升比率、最后状态
% fail_X_psr_train = [fail_psr_ascend_rate fail_psr_ascend_ratio fail_psr_ascend_last];
% fail_X_apce_train = [fail_apce_ascend_rate fail_apce_ascend_ratio fail_apce_ascend_last];
% fail_X_max_response_train = [fail_max_response_ascend_rate fail_max_response_ascend_ratio fail_max_response_ascend_last];
% sucess_X_psr_train = [sucess_psr_ascend_rate sucess_psr_ascend_ratio sucess_psr_ascend_last];
% sucess_X_apce_train = [sucess_apce_ascend_rate sucess_apce_ascend_ratio sucess_apce_ascend_last];
% sucess_X_max_response_train = [sucess_max_response_ascend_rate sucess_max_response_ascend_ratio sucess_max_response_ascend_last];

% 最后3帧归一化值+序列内上升状态
fail_X_psr_train = [fail_data_3d_norm(:,end-2:end,1) fail_psr_ascend_ratio fail_entropy_v(:,:,1)];
fail_X_apce_train = [fail_data_3d_norm(:,end-2:end,2) fail_apce_ascend_ratio fail_entropy_v(:,:,2)];
fail_X_max_response_train = [fail_data_3d_norm(:,end-2:end,3) fail_max_response_ascend_ratio fail_entropy_v(:,:,3)];
sucess_X_psr_train = [sucess_data_3d_norm(:,end-2:end,1) sucess_psr_ascend_ratio sucess_entropy_v(:,:,1)];
sucess_X_apce_train = [sucess_data_3d_norm(:,end-2:end,2) sucess_apce_ascend_ratio sucess_entropy_v(:,:,2)];
sucess_X_max_response_train = [sucess_data_3d_norm(:,end-2:end,3) sucess_max_response_ascend_ratio sucess_entropy_v(:,:,3)];



fail_X = [fail_X_psr_train fail_X_apce_train];
sucess_X = [sucess_X_psr_train sucess_X_apce_train];
X_train = [fail_X;sucess_X];

% 98.5%
sum(fail_data_3d_norm(:,end-2:end,1),2);%最后3帧psr和
fail_data_3d_norm(:,end,1);%最后一帧psr
mean(abs(fail_norm_descend_rate(:,1:end-3,1)),2);%前27帧变化率绝对值均值
fail_X = [sum(fail_data_3d_norm(:,end-2:end,1),2) fail_data_3d_norm(:,end,1) mean(abs(fail_norm_descend_rate(:,1:end-3,1)),2)];
sum(sucess_data_3d_norm(:,end-2:end,1),2);%最后3帧psr和
sucess_data_3d_norm(:,end,1);%最后一帧psr
mean(abs(sucess_norm_descend_rate(:,1:end-3,1)),2);%最后3帧变化率和
sucess_X = [sum(sucess_data_3d_norm(:,end-2:end,1),2) sucess_data_3d_norm(:,end,1) mean(abs(sucess_norm_descend_rate(:,1:end-3,1)),2);];
X_train = [fail_X;sucess_X];


Y_train = [fail_Y_label;sucess_Y_label];


y_pred = trainedModel.predictFcn(X_train);


%%%%%%LDA
% 0:跟踪失败 1：跟踪成功
model = fitcdiscr(X_train, Y_train);
coeffs = model.Coeffs(1,2);
% 边界方程：Const+Linear*x=0
Const = coeffs.Const;
Linear = coeffs.Linear;
y_pred2 = (Const+X_train*Linear)<0;%小于0成功，大于0失败
