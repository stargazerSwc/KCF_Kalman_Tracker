function [tracker_fail,psr_hist,psr_hist_norm,apce_hist,max_response_hist] = tracker_fail_detection(response,psr_hist,apce_hist,max_response_hist,N,tracked_frame)
       
    %%%
    %response:相应图
    %psr_hist:历史psr
    %max_response_hist:历史max_response
    %N:保留历史长度
    %tracked_frame:本次已跟踪时长
    tracker_fail = false;
    psr_hist_norm = ones(1,N);
    % 计算原始响应图
    response_orig = circshift(response,floor(size(response)/ 2)); 
    %% psr指标计算
    %计算psr    
    psr = computePSR(response_orig);
    % 拼接为历史psr
    n = length(psr_hist);
    if n>=N
        psr_hist = [psr_hist(2:N) psr];
    elseif n == 0
        psr_hist = ones(1,N)*psr;
    else
        psr_hist = [ones(1,N-n-1)*psr_hist(1), psr_hist,psr];
    end
    %% APCE指标计算
    apce = APCE(response_orig);
    n = length(apce_hist);
    if n>=N
        apce_hist = [apce_hist(2:N) apce];
    elseif n == 0
        apce_hist = ones(1,N)*apce;
    else
        apce_hist = [ones(1,N-n-1)*apce_hist(1), apce_hist,apce];
    end
    %% 平均最大响应计算
    %寻找最大响应
    max_response = max(response(:));
    % 拼接为历史max_response
    n = length(max_response_hist);
    if length(max_response_hist)>=N
        max_response_hist = [max_response_hist(2:N) max_response];
    elseif n == 0
        max_response_hist = ones(1,N)*max_response;
    else
        max_response_hist = [ones(1,N-n-1)*max_response_hist(1), max_response_hist,max_response];
    end

    %% 失败判断
    fail_detect_method = 'LDA';% Normal LDA
    if strcmpi('Normal', fail_detect_method)
        %% 普通失败判断
        % 判断是否失败
        psr_fail = false;
        if psr<mean(psr_hist)*0.7
            psr_fail = true;
        end
        max_response_fail = false;
        if max_response < mean(max_response_hist)*0.7
            max_response_fail = true;
        end

        if psr_fail && max_response_fail
            tracker_fail = true;
        else
            tracker_fail = false;
        end

    %% LDA失败判断
    elseif strcmpi('LDA', fail_detect_method)
        %% 指标数据归一化
        % psr
        psr_hist_mean = sum(psr_hist(1:N-3))/(N-3);
        psr_hist_std = std(psr_hist(1:N-3));
        psr_hist_norm = (psr_hist - psr_hist_mean)./psr_hist_std;
        % apce
        apce_hist_mean = sum(apce_hist(1:N-3))/(N-3);
        apce_hist_std = std(apce_hist(1:N-3));
        apce_hist_norm = (apce_hist - apce_hist_mean)./apce_hist_std;   
        %max_response
        % max_response
        mr_hist_mean = sum(max_response_hist(1:N-3))/(N-3);
        mr_hist_std = std(max_response_hist(1:N-3));
        mr_hist_norm = (max_response_hist - mr_hist_mean)./mr_hist_std;
        %% 上升下降率判断
        psr_descend_rate = zeros(1,N);
        apce_descend_rate = zeros(1,N);
        mr_descend_rate = zeros(1,N);
        for i = 2:N
           psr_descend_rate(i) = (psr_hist_norm(i) - psr_hist_norm(i-1));
           apce_descend_rate(i) = (apce_hist_norm(i) - apce_hist_norm(i-1));
           mr_descend_rate(i) = (mr_hist_norm(i) - mr_hist_norm(i-1));
        end
        %% LDA失败判断
        Const = -0.5301;
        Linear = [-0.0007;-2.5039;-8.4460];
        x_fail_feature = [sum(psr_hist_norm(end-2:end)) psr_hist_norm(end) mean(abs(psr_descend_rate(1:end-3)))];
        y_pred = (Const+x_fail_feature*Linear);%小于0成功，大于0失败
        
%         if x_fail_feature(3)<-3
%             tracker_fail = true;
%         else
%             tracker_fail = false;
%         end
        %% 失败判断
         if tracked_frame < N %前N帧判断策略
             if max_response_hist(end)< 0.5*max(max_response_hist)
                 tracker_fail = true;
             end
         else %长时跟踪判断策略
            %% 下降峰值判断
            if psr_hist_norm(end)<-2*max(abs(psr_hist_norm(1:end-3)))
                psr_hist_fail = true;
            else
                psr_hist_fail = false;
            end
            %% 联合判断 下降较多且符合模型
            if (y_pred >=0) || psr_hist_fail
                tracker_fail = true;
            end
         end
    %% 失败判断结束    
    end
end