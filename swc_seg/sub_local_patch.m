function local_patch = sub_local_patch(patch_img)
    center = floor(size(patch_img,[1,2])/2);
    local_size = floor(size(patch_img,[1,2])/10);
    local_patch = patch_img(floor(center(1)-local_size(1)/2):floor(center(1)+local_size(1)/2), ...,
                            floor(center(2)-local_size(2)/2):floor(center(2)+local_size(2)/2));
                        
%     f = figure;
%     imshow(patch_img);
%     local_rect = [floor(center(1)-local_size(1)/2), ...,
%              floor(center(2)-local_size(2)/2), ...,
%              local_size(1), ...,
%              local_size(2)];
%     local_coord = local_rect([2,1,4,3]);
%     % imrect(f,local_rect);
%     rectangle( 'Position', local_coord, 'EdgeColor', 'y')
end
