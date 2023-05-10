function tracker = update_tracker(tracker, im, w2c, frame, f_im)
    % 取图    
    patch = get_subwindow(im, tracker.pos_patch, tracker.window_sz);
    %% 余弦窗提取当前patch的feature
    % update试试
    addpath('./swc_seg');
    patch = get_subwindow(im, tracker.pos, tracker.window_sz);
    attention_mat = patch_attention_swc(patch);
    attention_mat_resize = imresize(attention_mat,1/tracker.cell_size);
    new_window = (attention_mat_resize+tracker.cos_window)/2;
    % 图像特征
%     zf = fft2(get_features(patch, tracker.features, tracker.cell_size, new_window, w2c));
    zf = fft2(get_features(patch, tracker.features, tracker.cell_size, tracker.cos_window, w2c));
    %calculate response of the classifier at all shifts
    %% 如果上一帧没有失败，计算新的跟踪位置
    if ~tracker.tracker_fail
        disp([tracker.name ' on_tracking']);
        status = 'on_tracking';
       %% 计算滤波器在当前patch的响应
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
       %% 判断本次跟踪，跟踪器是否跟踪失败
        [tracker.tracker_fail,tracker.psr_hist,tracker.psr_hist_norm,tracker.apce_hist,tracker.max_response_hist] = ...,
            tracker_fail_detection(tracker.response,tracker.psr_hist,tracker.apce_hist,tracker.max_response_hist,tracker.response_hist_dur,tracker.tracked_frame);
        %% 失败/成功策略
%         tracker.tracker_fail  = false;
        if tracker.tracker_fail        %% 本次失败则更新为之前保存的最佳模型
            %如果本次跟踪失败，使用最佳模型
            disp('track fail');
            tracker.model_alphaf = tracker.best_model_alphaf;
            tracker.model_xf = tracker.best_model_xf;
            tracker.tracked_frame = 0;
            tracker.re_tracking = true;
            % 记录失败
            tracker.positions(frame,:) = tracker.pos; 
            tracker.psr_hist = [];
            tracker.psr_hist_norm = [];
            tracker.apce_hist = [];
            tracker.max_response_hist = [];
            tracker.last_pos = tracker.pos;
            
        else           %% 本次成功则更新模型
       %% 亚像素计算peak位置
            [sub_horiz_delta,sub_vert_delta] = find_subpeak(tracker.response);
            % disp([sub_horiz_delta,sub_vert_delta]);

            tracker.pixel_diff = round(tracker.cell_size * [sub_vert_delta-1, sub_horiz_delta-1]);

            tracker.pos = tracker.pos_patch + round(tracker.cell_size * [sub_vert_delta-1, sub_horiz_delta-1]);    
            %记录位置
            %save position and timing
            tracker.positions(frame,:) = tracker.pos; 
            %% 记录最佳model (最大值，或者每隔一段时间更新)
            if tracker.psr_hist(end)>=max(tracker.psr_hist)
                tracker.best_model_alphaf = tracker.model_alphaf;
                tracker.best_model_xf = tracker.model_xf;
                tracker.best_psr = tracker.psr_hist(end);
                tracker.best_target_img = get_subwindow(im, tracker.pos, tracker.target_sz);
                tracker.best_max_response = tracker.max_response_hist(end);
            elseif mod(tracker.tracked_frame, tracker.response_hist_dur) == 0
                tracker.best_model_alphaf = tracker.model_alphaf;
                tracker.best_model_xf = tracker.model_xf;
                tracker.best_psr = tracker.psr_hist(end);
                tracker.best_target_img = get_subwindow(im,tracker.pos, tracker.target_sz);
                tracker.best_max_response = tracker.max_response_hist(end);
            end
            %% 在新的跟踪位置计算模板，更新模型
            [alphaf, xf] = cal_model(im, tracker.pos, tracker.window_sz, tracker.features, tracker.cell_size, tracker.cos_window, w2c, tracker.kernel, tracker.lambda, tracker.yf);
             tracker.model_alphaf = (1 - tracker.interp_factor) * tracker.model_alphaf + tracker.interp_factor * alphaf;
             tracker.model_xf = (1 - tracker.interp_factor) * tracker.model_xf + tracker.interp_factor * xf;
             disp('tracker updated');
             % 记录跟踪帧数
             tracker.tracked_frame = tracker.tracked_frame+1;
             tracker.search_scale = 2;
             showframe(im,f_im,status,tracker.pos,tracker.target_sz,tracker.pos_patch,tracker.window_sz,tracker.search_scale);
        end
    end
        
%% function end
end