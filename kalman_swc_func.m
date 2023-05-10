function [P_pred,pos_pred,speed_pred] = kalman_swc_func(pos,speed,pos_last,speed_last,P,A,Q,H,R)

    Z = [pos(1),pos(2),speed(1),speed(2)]';%观测值（跟踪结果）
    X = [pos_last(1),pos_last(2),speed_last(1),speed(2)]';%预测值（上一次）

    %卡尔曼滤波迭代
    X_ = A*X;
    P_ = A*P*A' + Q;
    K = P_*H'/(H*P_*H'+R);
    X_pred = X_+K*(Z-H*X_);
    P_pred = (eye(4)-K*H)*P_;
    %输出
    pos_pred = X_pred(1:2)';
    speed_pred = X_pred(3:4)';
end



% Z = (1:100);  % 设置一个观察值,表示小车的运动距离从1-100
% noise = randn(1, 100);
% Z = Z + noise;  % 加入一些噪声,
% 
% X = [0; 0];  % 设置系统状态的初始值
% P = [1 0; 0 1];  % 设置状态转移矩阵的初值
% A = [1 1; 0 1];  % t为采样频率,设置为1,表示每秒采样一次
% Q = [0.0001 0; 0 0.0001];  % 将Q的方差设置的很小,就代表了过程噪声很小,对计算出来的估计值比较相信
% H = [1 0];  % 这个为什么是1和0解释过了
% R = 1;  % 这是观察噪声的协方差矩阵,因为观察噪声基本不会改变,所以设置为一个常数就行
% figure;
% hold on;
% for i = 1:100  % 迭代100次
%     X_ = A*X;  % 没有B和ut-1 暂时不考虑小车的加速度情况
%     P_ = A*P*A' + Q;
%     K = P_*H'/(H*P_*H'+R);
%     X = X_+K*(Z(i)-H*X_);
%     P = (eye(2)-K*H)*P_;
%     plot(X(1), X(2), 'r.'); % 画出小车运动的两个状态,估计出小车的最优真实估计状态解
%     plot(X_(1), X_(2), 'b.'); % 画出小车运动的两个状态,估计出小车的最优预测状态解
%     hold on;
% end