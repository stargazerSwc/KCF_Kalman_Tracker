function tracker = kalman_tracker(tracker, kalman_use_flag)
    disp(['kalman filttering tracker ' tracker.name]);
    %% %%%%%%%%%SWC START%%%%%%%%%%%%%
    %计算下次卡尔曼滤波的输入速度
    % pos:观测值
    % speed:观测速度
    % pos_last_kalman:上次卡尔曼滤波输出的观测值
    % speed_last_kalman:上次卡尔曼滤波输出的速度
    % 开启卡尔曼滤波，更新P与pos_out
    %% 将KCF结果输入kalman作为观测
    tracker.pos_K = tracker.pos;
    tracker.speed_K = tracker.pixel_diff;
    %% 将上一帧的预测输入kalman作为历史值
    tracker.pos_last_kalman = tracker.pos_pred;
    tracker.speed_last_kalman = tracker.speed_pred;
    tracker.P = tracker.P_pred;
    
    if tracker.tracker_fail %%% 如果上一帧失败
        % 更新KCF观测量为卡尔曼滤波输出值，进行外推
        tracker.pos_K = tracker.pos_pred;
        tracker.speed_K = tracker.speed_pred;
    end
    [tracker.P_pred,tracker.pos_pred,tracker.speed_pred] = ...,
        kalman_swc_func(tracker.pos_K,tracker.speed_K,tracker.pos_last_kalman,tracker.speed_last_kalman,tracker.P,tracker.A,tracker.Q,tracker.H,tracker.R);
    %% 如果使用kalman的值，将本帧预测位置更新为kalman预测位置,否则使用之前的KCF结果
    if kalman_use_flag
        tracker.pos_patch = tracker.pos_pred;
    else
        tracker.pos_patch = tracker.pos;
    end
%% function end
end