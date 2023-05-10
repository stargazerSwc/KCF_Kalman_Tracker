%%%%%%%%%%%%%%%%%%%%%% CN模型初始化 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 加载标准化颜色名称矩阵
temp = load('w2crs');
w2c = temp.w2crs;
use_dimensionality_reduction = ~isempty(CN_compressed_features);
% 填充后的窗口大小
CN_sz = floor(target_sz * (1 + CN_padding));
% 期望输出（高斯形状），带宽与目标尺寸成比例
CN_output_sigma = sqrt(prod(target_sz)) * CN_output_sigma_factor;
CN_yf = single(fft2(gaussian_shaped_labels(CN_output_sigma, CN_sz)));
% 存储预计算余弦窗口
CN_cos_window = single(hann(CN_sz(1)) * hann(CN_sz(2))');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[xo_npca, xo_pca] = get_subwindow_CN(im, pos, CN_sz, CN_non_compressed_features, CN_compressed_features, w2c);

if frame == 1
    % 初始化外观
    z_npca = xo_npca;
    z_pca = xo_pca;
    % 如果太多，则将压缩维数设置为最大值
    CN_num_compressed_dim = min(CN_num_compressed_dim, size(xo_pca, 2));
    %-------------------------------------------------------------
    h_num_pca = xl_pca;
    h_num_npca = xl_npca;
    num_compressed_dim = min(num_compressed_dim, size(xl_pca, 2));
end


% CN特征
[xo_npca, xo_pca] = get_subwindow_CN(im, pos, CN_sz, CN_non_compressed_features, CN_compressed_features, w2c);
%Compute coefficients for the tranlsation filter计算平移滤波器的系数

if frame == 1
    % 初始化外观
    z_npca = xo_npca;
    z_pca = xo_pca;
    % 如果太多，则将压缩维数设置为最大值
    CN_num_compressed_dim = min(CN_num_compressed_dim, size(xo_pca, 2));
    %-------------------------------------------------------------
    h_num_pca = xl_pca;
    h_num_npca = xl_npca;
    num_compressed_dim = min(num_compressed_dim, size(xl_pca, 2));
else
    % 更新外观
    z_npca = (1 - CN_learning_rate) * z_npca + CN_learning_rate * xo_npca;
    z_pca = (1 - CN_learning_rate) * z_pca + CN_learning_rate * xo_pca;
    %--------------------------------------------------------------
    h_num_pca = (1 - interp_factor) * h_num_pca + interp_factor * xl_pca;
    h_num_npca = (1 - interp_factor) * h_num_npca + interp_factor * xl_npca;
end

% 如果使用降维：更新投影矩阵
% PCA维度姜维：CN：10->CN_num_compressed_dim
if use_dimensionality_reduction
    % 计算平均外观
    data_mean = mean(z_pca, 1);

    % 从外观中减去平均值得到数据矩阵
    data_matrix = bsxfun(@minus, z_pca, data_mean);

    % 计算协方差矩阵
    cov_matrix = 1 / (prod(CN_sz) - 1) * (data_matrix' * data_matrix);

    % 计算主成分（pca_basis）和相应的方差
    if frame == 1
        [CN_pca_basis, CN_pca_variances, ~] = svd(cov_matrix);
    else
        [CN_pca_basis, CN_pca_variances, ~] = svd((1 - CN_compression_learning_rate) * CN_old_cov_matrix + CN_compression_learning_rate * cov_matrix);
    end

    % 计算投影矩阵作为第一主成分，并提取其对应的方差
    CN_projection_matrix = CN_pca_basis(:, 1:CN_num_compressed_dim);
    CN_projection_variances = CN_pca_variances(1:CN_num_compressed_dim, 1:CN_num_compressed_dim);

    if frame == 1
        % 使用计算的投影矩阵和方差初始化旧的协方差矩阵
        CN_old_cov_matrix = CN_projection_matrix * CN_projection_variances * CN_projection_matrix';
    else
        % 使用计算的投影矩阵和方差更新旧的协方差矩阵
        CN_old_cov_matrix = (1 - CN_compression_learning_rate) * CN_old_cov_matrix + CN_compression_learning_rate * (CN_projection_matrix * CN_projection_variances * CN_projection_matrix');
    end

end
% 使用新的投影矩阵投影新外观示例的特征
% 形成的为CN降维为2维的特征+灰度特征
x = feature_projection_CN(xo_npca, xo_pca, CN_projection_matrix, CN_cos_window);
% 计算新的分类器系数
kf = fft2(dense_gauss_kernel(CN_sigma, x));
new_alphaf_num = CN_yf .* kf;
new_alphaf_den = kf .* (kf + CN_lambda);