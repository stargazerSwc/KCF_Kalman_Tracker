%%% swc交互分割
function attention_mat = patch_attention_swc(input_im)
    if size(input_im,3)>1
        input_im = rgb2gray(input_im);
    end
    local_patch = sub_local_patch(input_im);
    mean_value = median(median(local_patch));
    
    dist_mat = double(abs(input_im - mean_value));
    max_v = max(max(dist_mat));
    min_v = min(min(dist_mat));
    attention_mat = 1-(dist_mat - min_v)/(max_v-min_v);
    
%     dist_mat = 1./double(abs(input_im - mean_value)+1);
%     outname=[outdir imnames(ii).name(1:end-4) '_our' '.png'];   
%     imwrite(dist_mat,outname)
end


