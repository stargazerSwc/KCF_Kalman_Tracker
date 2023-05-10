function tracker = init_tracker(im, pos, window_sz, target_sz, features, cell_size, cos_window, w2c, kernel, lambda, yf, interp_factor, response_hist_dur, name)
    disp('init_tracking');
    % 记录tracker初始化外部参数
    tracker.name = name;
    tracker.pos = pos;
    tracker.pos_patch = pos;
    tracker.window_sz = window_sz;
    tracker.target_sz = target_sz;
    tracker.cell_size = cell_size;
    tracker.cos_window = cos_window;
    tracker.kernel = kernel;
    tracker.lambda = lambda;
    tracker.features = features;
    tracker.interp_factor = interp_factor;
    tracker.response_hist_dur = response_hist_dur;
    tracker.search_scale = 2;
    tracker.yf = yf;
    
    % attention 修正cos_window
    addpath('./swc_seg');
    patch = get_subwindow(im, tracker.pos, tracker.window_sz);
    attention_mat = patch_attention_swc(patch);
    attention_mat_resize = imresize(attention_mat,1/cell_size);
    new_window = (attention_mat_resize+tracker.cos_window)/2;
    figure(2);
    imshow(attention_mat_resize);
    % 初始化模型
%     [tracker.model_alphaf, tracker.model_xf] = cal_model(im, tracker.pos, tracker.window_sz, tracker.features, tracker.cell_size, new_window, w2c, tracker.kernel, tracker.lambda, tracker.yf);
    [tracker.model_alphaf, tracker.model_xf] = cal_model(im, tracker.pos, tracker.window_sz, tracker.features, tracker.cell_size, tracker.cos_window, w2c, tracker.kernel, tracker.lambda, tracker.yf);
   
    %记录初始模型
    tracker.init_model_alphaf = tracker.model_alphaf;
    tracker.init_model_xf = tracker.model_xf;
    tracker.init_target_img = get_subwindow(im, pos, target_sz);
    %记录最佳模型
    tracker.best_model_alphaf = tracker.init_model_alphaf;
    tracker.best_model_xf = tracker.init_model_xf;
    tracker.best_target_img = get_subwindow(im, pos, target_sz);
    %初始化指标历史记录
    tracker.max_response_hist = [];
    tracker.psr_hist = [];
    tracker.apce_hist = [];
    tracker.positions = [pos(1),pos(2)];
    %初始化tracker状态
    tracker.init_tracking = false;
    tracker.tracker_fail = false;
    tracker.tracked_frame = 0;
    tracker.re_tracking = false;
    tracker.retrack_frame = 0;
    tracker.on_tracking = true;
    
    %初始化卡尔曼滤波参数
    tracker.pos_pred = pos;
    tracker.speed_pred = [0,0];
    tracker.pixel_diff = [0,0];
    tracker.P = 1e4*eye(4); %初始状态协方差矩阵
    tracker.P_pred = tracker.P;
    tracker.dt = 1;
    tracker.A = [1, 0, tracker.dt, 0;
                 0, 1, 0, tracker.dt;
                 0, 0, 1, 0;
                 0, 0, 0, 1];  % 状态转移矩阵
    % Q = diag([1e-4,1e-4,1e-4,1e-4]);  % 将Q的方差设置的很小,就代表了过程噪声很小,对计算出来的估计值比较相信
    tracker.Q = diag([1e-6,1e-6,1e-6,1e-6]);  % 将Q的方差设置的很小,就代表了过程噪声很小,对计算出来的估计值比较相信
    tracker.H = diag([1,1,0,0]);  % 这个为什么是1和0解释过了
    % R = diag([1e-4,1e-4,1e-4,1e-4]);  % 这是观察噪声的协方差矩阵,因为观察噪声基本不会改变,所以设置为一个常数就行
    tracker.R = diag([1e-1,1e-1,1e-1,1e-1]);
end