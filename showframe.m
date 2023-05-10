function showframe(im,f_im,status,pos,target_sz,pos_patch,window_sz,search_scale)
        %% swc show box
        figure(f_im);
        imshow(im);
        if strcmp('on_tracking',status)
            box = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
            EdgeColor = 'g';
            rectangle('Position',box,'EdgeColor',EdgeColor);
        elseif strcmp('re_tracking',status)
            box = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
            search_box = [pos_patch([2,1]) - window_sz([2,1])*search_scale/2, window_sz([2,1])*search_scale];
            EdgeColor = 'b';
            rectangle('Position',box,'EdgeColor',EdgeColor);
            rectangle('Position',search_box,'EdgeColor','y');
        end
end