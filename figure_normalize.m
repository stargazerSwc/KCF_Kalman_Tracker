function Out_image = figure_normalize(In_image)
%   归一化至0-1
o_max_image = max(max(In_image));
o_min_image = min(min(In_image));
Out_image = double(In_image - o_min_image)/double(o_max_image - o_min_image);
end