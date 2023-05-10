%%% swc 对输入特征进行pca降维
% 计算协方差去前n值
function x_pca = pca_features(x,pca_dim)
    [height,width,dim] = size(x);  
    data_matrix = reshape(x, [height*width, dim]);
    [pca_basis, s, ~] = svd(data_matrix' * data_matrix);
    projection_matrix = pca_basis(:, 1:pca_dim);
    x_pca = reshape(data_matrix * projection_matrix, [height, width, pca_dim]);
end