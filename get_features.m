function x = get_features(im, features, cell_size, cos_window, w2c)
%GET_FEATURES
%   Extracts dense features from image.
%
%   X = GET_FEATURES(IM, FEATURES, CELL_SIZE)
%   Extracts features specified in struct FEATURES, from image IM. The
%   features should be densely sampled, in cells or intervals of CELL_SIZE.
%   The output has size [height in cells, width in cells, features].
%
%   To specify HOG features, set field 'hog' to true, and
%   'hog_orientations' to the number of bins.
%
%   To experiment with other features simply add them to this function
%   and include any needed parameters in the FEATURES struct. To allow
%   combinations of features, stack them with x = cat(3, x, new_feat).
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/


	if features.hog,
		%HOG features, from Piotr's Toolbox
		x = double(fhog(single(im) / 255, cell_size, features.hog_orientations));
		x(:,:,end) = [];  %remove all-zeros channel ("truncation feature")
	end
	
	if features.gray,
		%gray-level (scalar feature)
		x = double(im) / 255;
		
		x = x - mean(x(:));
    end
	
    if features.pca,
        pca_dim = features.pca_dim;
        x = pca_features(x,pca_dim);
    end
    
    %% 拼接特征
    if features.cat_feature
%         gray = double(imresize(im, [size(x,1),size(x,2)]))/ 255;
%         gray = gray - mean(gray(:));
        cn_patch = imresize(im, [size(x,1),size(x,2)]);
        [gray, cn] = get_subwindow_CN(cn_patch, w2c);
        cn_feature = reshape(cn,[size(cn_patch,1),size(cn_patch,2),size(cn,2)]);
        %灰度
        if strcmpi('gray', features.cat_feature_type)
            cat_feature = gray;
        % CN
        elseif strcmpi('cn', features.cat_feature_type)
            % PCA CN特征
            if features.cat_feature_pca
                cat_feature = pca_features(cn_feature,features.cat_feature_pca_dim);
            else
                cat_feature = cn_feature;
            end
        end
        x = cat(3,x,cat_feature);
    end
%     
%     if features.cat_feature
%         if features.cat_feature_type == 'gray'
%             compile = double(imresize(im, [size(x,1),size(x,2)]))/ 255;
%             compile = compile - mean(compile(:));
%             x = cat(3,x,compile);% add gray
%         end
%     end

    %% 加余弦窗    
	%process with cosine window if needed
	if ~isempty(cos_window),
		x = bsxfun(@times, x, cos_window);
    end
	
    %% cricleshift
    x = circshift(x, -floor(x(1:2) / 2) + 1);
end
