function tracker = re_track(tracker, im, w2c, frame, f_im)
    disp('re_tracking');
    tracker.retrack_frame = tracker.retrack_frame + 1;
    status = 're_tracking';
    patch = get_subwindow(im, tracker.pos_patch, tracker.window_sz);
    %% 余弦窗提取当前patch的feature
    % 图像特征
    zf = fft2(get_features(patch, tracker.features, tracker.cell_size, tracker.cos_window, w2c));
   %% 计算best滤波器在当前patch的响应
    switch tracker.kernel.type
    case 'gaussian',
        kzf = gaussian_correlation(zf, tracker.model_xf, tracker.kernel.sigma);
    case 'polynomial',
        kzf = polynomial_correlation(zf, tracker.model_xf, tracker.kernel.poly_a, tracker.kernel.poly_b);
    case 'linear',
        kzf = linear_correlation(zf, tracker.model_xf);
    end
    % alpahf:KCF a
    % kzf: KCF K
    tracker.response = real(ifft2(tracker.model_alphaf .* kzf));  %equation for fast detection
   %% 亚像素计算peak位置
    [sub_horiz_delta,sub_vert_delta] = find_subpeak(tracker.response);
%       disp([sub_horiz_delta,sub_vert_delta]);
    % cal sub pos
    tracker.pixel_diff = round(tracker.cell_size * [sub_vert_delta-1, sub_horiz_delta-1]);
%       disp(pixel_diff);
    pos_kcf = tracker.pos_patch + round(tracker.cell_size * [sub_vert_delta-1, sub_horiz_delta-1]);   
    %% 判断本次重捕获是否失败（只用psr）
    % psr判断?maxresponse?
    [~,tracker.psr_hist,tracker.psr_hist_norm,tracker.apce_hist,tracker.max_response_hist] = ...,
        tracker_fail_detection(tracker.response,tracker.psr_hist,tracker.apce_hist,tracker.max_response_hist, tracker.response_hist_dur, tracker.tracked_frame);
    % ncc判断
    tracker.search_scale = 2+log(tracker.retrack_frame+1)/log(30); 
    tracker.background = get_subwindow(im, tracker.pos_patch, tracker.window_sz*tracker.search_scale);
    [pos_temp, max_c] = templateMatching(tracker.best_target_img, tracker.background);
    pos_temp = pos_temp([2,1]) - [tracker.window_sz(1)*tracker.search_scale/2, tracker.window_sz(2)*tracker.search_scale/2] + tracker.pos_patch;
    showframe(im,f_im,status,tracker.pos_patch,tracker.target_sz,tracker.pos_patch,tracker.window_sz,tracker.search_scale);
    pause(0.2);
    %失败并重捕获后后重新初始化
    disp(['psr: ' num2str(tracker.psr_hist(end))]);
    disp(['best_psr: ' num2str(tracker.best_psr)]);
    disp(['max_resp: ' num2str(tracker.max_response_hist(end))]);
    disp(['best_resp: ' num2str(tracker.best_max_response)]);
    disp(['max_c: ' num2str(max_c)]);
    if tracker.psr_hist(end)>tracker.best_psr*0.7
        tracker.kcf_retrack = 1;
    else
        tracker.kcf_retrack = 0;
    end

    if max_c>0.80
        tracker.ncc_retrack = 0;
    else
        tracker.ncc_retrack = 0;
    end

    %%%% ncc的结果有时候有问题，需要排查 20230505
    if tracker.ncc_retrack || tracker.kcf_retrack
        disp([tracker.name ' re_tracked']);
        tracker.retrack_frame = 0;
        if ~tracker.ncc_retrack %kcf成功
            lamda_k = 1;
        elseif ~tracker.kcf_retrack %ncc成功
            lamda_k = 0;
        else
            lamda_k = (tracker.psr_hist(end)/tracker.best_psr)/((tracker.psr_hist(end)/tracker.best_psr) + max_c);
        end
        tracker.pos = pos_kcf*lamda_k + pos_temp*(1-lamda_k);
%         tracker.pos = tracker.pos([2,1]);
        %显示
        %记录位置
        %save position and timing
        tracker.positions(frame,:) = tracker.pos;                    
        %重置状态
        tracker.re_tracking = false;
        tracker.on_tracking = true;
        tracker.init_tracking = false; 
        tracker.tracker_fail = false;
        % 将kalman预测值设置为新的值，防止跳动太大
        tracker.pos_pred = tracker.pos;
        tracker.speed_pred = [0,0]; 
    end

%% function end

end