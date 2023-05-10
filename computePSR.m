function psr = computePSR(response_orig)
    %%%%%% 计算高斯在中心时，最大值位置
%     side_width = min([5;
%         vert_delta+floor(size(response,1)/2);-vert_delta+floor(size(response,1)/2);
%         horiz_delta+floor(size(response,2)/2);-horiz_delta+floor(size(response,2)/2)]);
%     peak_pos = [vert_delta, horiz_delta]+ floor(size(response)/2) + 1;  
    [peak_pos_w,peak_pos_h] = find(response_orig == max(response_orig(:)), 1);
    side_width = min([5;
         peak_pos_w-1;-peak_pos_w+size(response_orig,1);
         peak_pos_h-1;-peak_pos_h+size(response_orig,2)]);
    
    WL = peak_pos_w-side_width;
    WR = peak_pos_w+side_width;
    HU = peak_pos_h-side_width;
    HD = peak_pos_h+side_width;
     
    region = response_orig(peak_pos_w-side_width:peak_pos_w+side_width,peak_pos_h-side_width:peak_pos_h+side_width);
    region_vec = sort(reshape(region,[1,size(region,1)*size(region,2)]),'descend');
    peak_val = region_vec(1);
    side_vec = region_vec(2:end);
    side_std = std(side_vec);
    side_mean = mean(side_vec);
    psr = (peak_val - side_mean)/side_std;
end