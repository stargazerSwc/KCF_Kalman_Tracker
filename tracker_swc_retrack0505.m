%%%更新使用Kalman滤波对目标位置进行预测


function [positions, time] = tracker_swc_retrack0505(video_path, img_files, pos, target_sz, ...
	padding, kernel, lambda, output_sigma_factor, interp_factor, cell_size, ...
	features, show_visualization)
%TRACKER Kernelized/Dual Correlation Filter (KCF/DCF) tracking.
%   This function implements the pipeline for tracking with the KCF (by
%   choosing a non-linear kernel) and DCF (by choosing a linear kernel).
%
%   It is meant to be called by the interface function RUN_TRACKER, which
%   sets up the parameters and loads the video information.
%
%   Parameters:
%     VIDEO_PATH is the location of the image files (must end with a slash
%      '/' or '\').
%     IMG_FILES is a cell array of image file names.
%     POS and TARGET_SZ are the initial position and size of the target
%      (both in format [rows, columns]).
%     PADDING is the additional tracked region, for context, relative to 
%      the target size.
%     KERNEL is a struct describing the kernel. The field TYPE must be one
%      of 'gaussian', 'polynomial' or 'linear'. The optional fields SIGMA,
%      POLY_A and POLY_B are the parameters for the Gaussian and Polynomial
%      kernels.
%     OUTPUT_SIGMA_FACTOR is the spatial bandwidth of the regression
%      target, relative to the target size.
%     INTERP_FACTOR is the adaptation rate of the tracker.
%     CELL_SIZE is the number of pixels per cell (must be 1 if using raw
%      pixels).
%     FEATURES is a struct describing the used features (see GET_FEATURES).
%     SHOW_VISUALIZATION will show an interactive video if set to true.
%
%   Outputs:
%    POSITIONS is an Nx2 matrix of target positions over time (in the
%     format [rows, columns]).
%    TIME is the tracker execution time, without video loading/rendering.
%
%   Joao F. Henriques, 2014

    f_im = figure('Name','Frame');
	%% if the target is large, lower the resolution, we don't need that much
	%detail
	resize_image = (sqrt(prod(target_sz)) >= 100);  %diagonal size >= threshold
	if resize_image,
		pos = floor(pos / 2);
		target_sz = floor(target_sz / 2);
	end


	%% window size, taking padding into account
%     window_sz = floor(target_sz * (1 + padding));
    %swc-cell奇数倍
	search_sz = target_sz * (1 + padding);
    % 特征图尺寸限制
    min_feature_size = features.size_lim_min; %特尔图最小尺寸
    max_feature_size = features.size_lim_max; %特尔图最大尺寸
    
    % 如果限制特征图尺寸
    if features.size_lim
        %如果特征图太大
        if min(search_sz)/cell_size>max_feature_size
            cell_size = min(8, floor(min(search_sz)/max_feature_size/2)*2);
        end
        % 如果特征图太小
        if min(search_sz)/cell_size<min_feature_size
            cell_size = max(1, floor(min(search_sz)/min_feature_size/2)*2);
        end
    end
    
    % 奇数windowsz
%     window_sz = (floor(floor(search_sz/cell_size)/2)*2+1)*cell_size;
    % 偶数windowsz
	window_sz = (floor(floor(search_sz/cell_size)/2)*2)*cell_size;
    
    %% 如果限制特征图为指定4挡
    if features.size_level == 1
        cell_size = 1;
        window_sz = [16,32];
        target_sz = window_sz/(1 + padding);
    elseif features.size_level == 2
        cell_size = 2;
        window_sz = [32,64];
        target_sz = window_sz/(1 + padding);
    elseif features.size_level == 3
        cell_size = 4;
        window_sz = [64,128];
        target_sz = window_sz/(1 + padding);
    elseif features.size_level == 4    
        cell_size = 8;
        window_sz = [128,256];
        target_sz = window_sz/(1 + padding);
    end
% 	%we could choose a size that is a power of two, for better FFT
% 	%performance. in practice it is slower, due to the larger window size.
% 	window_sz = 2 .^ nextpow2(window_sz);
	
	%% 构造拟合标签
    %% create regression labels, gaussian shaped, with a bandwidth
	%proportional to target size
	output_sigma = sqrt(prod(target_sz)) * output_sigma_factor / cell_size;
	yf = fft2(gaussian_shaped_labels(output_sigma, floor(window_sz / cell_size)));

	%store pre-computed cosine window
	cos_window = hann(size(yf,1)) * hann(size(yf,2))';
%     cos_window = ones(size(yf,1),size(yf,2));
	
	%% 是否显示
	if show_visualization,  %create video interface
		update_visualization = show_video(img_files, video_path, resize_image);
	end
	
	
	%note: variables ending with 'f' are in the Fourier domain.

	time = 0;  %to calculate FPS
	positions = zeros(numel(img_files), 2);  %to calculate precision

    %% %%%%%%%%%%%%%%SWC START
    %% 记录response、是否开启卡尔曼滤波
    %%% 统计跟踪响应
    max_response_his = [];
    N= 5;
    response_his = zeros(1,N);
    %%% 记录原始跟踪器
    tracker_fail = false; 
    kalman_flag = true; %kalman开关
    kalman_status = false; %kalman状态
    kalman_use_flag = true; %是否使用kalman滤波结果
    speed = [0, 0];
    pixel_diff = [0, 0];
    window_sz_orig = window_sz;
    %%%%%%%%%%%%%%%%SWC END
    %% 初始化卡尔曼滤波参数
    %%%%%%%%%%%SWC START%%%%%%%%%%%%%%%
    % 加入卡尔曼滤波预测框位置
    pos_pred=[];
    P = 1e4*eye(4); %初始状态协方差矩阵
    delta_t = 1;
    A = [1, 0, delta_t, 0;
         0, 1, 0, delta_t;
         0, 0, 1, 0;
         0, 0, 0, 1];  % 状态转移矩阵
    % Q = diag([1e-4,1e-4,1e-4,1e-4]);  % 将Q的方差设置的很小,就代表了过程噪声很小,对计算出来的估计值比较相信
    Q = diag([1e-6,1e-6,1e-6,1e-6]);  % 将Q的方差设置的很小,就代表了过程噪声很小,对计算出来的估计值比较相信
    H = diag([1,1,0,0]);  % 这个为什么是1和0解释过了
    % R = diag([1e-4,1e-4,1e-4,1e-4]);  % 这是观察噪声的协方差矩阵,因为观察噪声基本不会改变,所以设置为一个常数就行
    R = diag([1e-1,1e-1,1e-1,1e-1]);
    % 初始化记录
    max_response_hist = [];
    psr_hist = [];
    apce_hist = [];
    % 记录帧数
    response_hist_dur = 30;
    %% CN特征预加载
    temp = load('w2crs.mat');
    w2c = temp.w2crs;
    %%%%%%%%%%%SWC END%%%%%%%%%%%%%%%
    
    %% 保存视频    
    writerObj =VideoWriter('myVideo.avi');   
    open(writerObj);
    %%  开始跟踪
    on_tracking = false;
    init_tracking = true;
%     for frame = 1:150
    for frame = 1:numel(img_files)
		%load image
		im = imread([video_path img_files{frame}]);
		if size(im,3) > 1
% 			im = rgb2gray(im);
		end
		if resize_image
			im = imresize(im, 0.5);
        end
		tic()
        %% 初始化tracker
        if frame == 1
            name = 'tracker1';
            tracker = init_tracker(im, pos, window_sz, target_sz, features, cell_size, cos_window, w2c, kernel, lambda, yf, interp_factor, response_hist_dur, name);
            %初始化状态
            init_tracking = tracker.init_tracking;
            tracker_fail = tracker.tracker_fail;
            tracked_frame = tracker.tracked_frame;
            re_tracking = tracker.re_tracking;
            retrack_frame = tracker.retrack_frame;
            on_tracking = tracker.on_tracking;
            continue
        end
        %% 跟踪更新tracker
		if frame > 1
            if tracker.init_tracking
               tracker = ...,
                   init_tracker(im, tracker.pos, tracker.window_sz, tracker.target_sz, tracker.features, tracker.cell_size, tracker.cos_window, w2c, tracker.kernel, tracker.lambda, tracker.yf, tracker.interp_factor, tracker.response_hist_dur, tracker.name);
                continue 
            end
           %% 控制卡尔曼滤波开启时机
            if tracker.tracked_frame >= 3 && kalman_flag
                kalman_status = true; %true
            end
           %% 始终开启卡尔曼滤波，只是在跟踪失败时使用预测值
            %%%进行卡尔曼滤波
            if kalman_status
                tracker = kalman_tracker(tracker, kalman_use_flag);
                disp([tracker.speed_pred]);
            end        
            %% 如果上一帧没有失败，计算新的跟踪位置，如果上一帧失败，重捕获
            if ~tracker.tracker_fail
                tracker = update_tracker(tracker, im, w2c, frame, f_im);
                last_frame = frame;
            elseif tracker.re_tracking 
                tracker = re_track(tracker, im, w2c, frame, f_im);
                if ~tracker.re_tracking 
                    tracker.speed = (tracker.pos - tracker.last_pos)/(frame - last_frame);
%                      tracker = ...,
%                          init_tracker(im, tracker.pos, tracker.window_sz, tracker.target_sz, tracker.features, tracker.cell_size, tracker.cos_window, w2c, tracker.kernel, tracker.lambda, tracker.yf, tracker.interp_factor, tracker.response_hist_dur, tracker.name);
                end
            end
        end
        %% 统计时间
		time = time + toc();
		%visualization
            
            % save video
%             result_im = getframe(gcf);
%             writeVideo(writerObj, result_im);
    end  
    close(writerObj);
    disp('finish');
	if resize_image,
		positions = positions * 2;
    end
end

