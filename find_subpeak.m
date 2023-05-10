%% 找到最大值的亚像素坐标
%v,h代表矩阵的列、行
function [vert_delta, horiz_delta] = find_subpeak(response)
    % 极大值
%     response = [4,3,2,2,3;2.50000000000000,2,3,1,2;2,1,0,0,1;1,0,0,0,0;1,0,0,0,0;2,1,0,0,1;2.50000000000000,2,1,1,2];
    response_orig = circshift(response,floor(size(response)/ 2));    
    [max_h, max_v] = find(response_orig == max(response_orig(:)), 1);
    
    % 极大值亚像素
    if max_v == floor(size(response_orig,2)/ 2)+1
        % 防止静止震荡
        vert_delta = 1;
        % 中心也计算亚像素
%         neighboor_idx = (max_v-1):(max_v+1);
%         neighboor_v = response_orig(max_h,(max_v-1):(max_v+1));
%         vert_delta = sub_peak(neighboor_v,neighboor_idx) - floor(size(response_orig,2)/ 2);
    elseif (max_v == size(response_orig,2)) || (max_v == 1)
        disp(['max at edge']);
        vert_delta = max_v - floor(size(response_orig,2)/ 2) + 1;
    else
        neighboor_idx = (max_v-1):(max_v+1);
        neighboor_v = response_orig(max_h,(max_v-1):(max_v+1));
        vert_delta = sub_peak(neighboor_v,neighboor_idx) - floor(size(response_orig,2)/ 2);
    end
    
    if max_h == floor(size(response_orig,1)/ 2)+1
        % 防止静止震荡
        horiz_delta = 1;
        % 中心也计算亚像素
%         neighboor_idx = (max_h-1):(max_h+1);
%         neighboor_h = response_orig((max_h-1):(max_h+1),max_v);
%         horiz_delta = sub_peak(neighboor_h,neighboor_idx) - floor(size(response_orig,1)/ 2);
    elseif (max_h == size(response_orig,1)) || (max_h == 1)
        disp(['max at edge']);
        horiz_delta = max_h - floor(size(response_orig,1)/ 2) + 1;
    else
        neighboor_idx = (max_h-1):(max_h+1);
        neighboor_h = response_orig((max_h-1):(max_h+1),max_v);
        horiz_delta = sub_peak(neighboor_h,neighboor_idx) - floor(size(response_orig,1)/ 2);
    end   
end

% sub_peak(y,x)
function subpos = sub_peak(neighboor,neighboor_idx)
    method = 'linear';
    % 多项式
    if strcmpi('poly', method)
        params=polyfit(neighboor_idx,neighboor,2);
        subpos = -params(2)/(2*params(1));
    % 线性
    elseif strcmpi('linear', method)
        left = neighboor(2)-neighboor(1);
        right = neighboor(2)-neighboor(3);
        if left>right
            subpos = neighboor_idx(2) + (0.5 - right/left);
        elseif left<right
            subpos = neighboor_idx(2) - (0.5- left/right);
        end
            
    end
end