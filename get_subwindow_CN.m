function [out_npca, out_pca] = get_subwindow_CN(im_patch, w2c)
    non_pca_features = {'gray'};
    pca_features = {'cn'};
    % [out_npca, out_pca] = get_subwindow(im, pos, sz, non_pca_features, pca_features, w2c)
    %
    % Extracts the non-PCA and PCA features from image im at position pos and
    % window size sz. The features are given in non_pca_features and
    % pca_features. out_npca is the window of non-PCA features and out_pca is
    % the PCA-features reshaped to [prod(sz) num_pca_feature_dim]. w2c is the
    % Color Names matrix if used.
    

    
    % compute non-pca feature map
    if ~isempty(non_pca_features)
        out_npca = get_feature_map(im_patch, non_pca_features, w2c);
    else
        out_npca = [];
    end
    
    % compute pca feature map
    if ~isempty(pca_features)
        temp_pca = get_feature_map(im_patch, pca_features, w2c);
        out_pca = reshape(temp_pca, [prod([size(im_patch,1), size(im_patch,2)]), size(temp_pca, 3)]);
    else
        out_pca = [];
    end
    end
    
    