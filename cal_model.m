%%% 根据pos生成patch，计算当前patch的model
function [alphaf, xf] = cal_model(im, pos, window_sz, features, cell_size, cos_window, w2c, kernel, lambda, yf)
    %obtain a subwindow for training at newly estimated target position
    % 提取patch图像
    addpath('./swc_seg');
    patch = get_subwindow(im, pos, window_sz);
    attention_mat = patch_attention_swc(patch);
    %提取余弦窗特征
    % xf:模板特征，不断更新
    xf = fft2(get_features(patch, features, cell_size, cos_window, w2c));
    %岭回归计算滤波器
    %Kernel Ridge Regression, calculate alphas (in Fourier domain)
    switch kernel.type
    case 'gaussian',
        kf = gaussian_correlation(xf, xf, kernel.sigma);
    case 'polynomial',
        kf = polynomial_correlation(xf, xf, kernel.poly_a, kernel.poly_b);
    case 'linear',
        kf = linear_correlation(xf, xf);
    end
    %kf ：训练时的K矩阵
    alphaf = yf ./ (kf + lambda);   %equation for fast training
end