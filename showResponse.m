function showResponse(response,N)
    if nargin<=1
        figure(5);
        imshow(floor(response*255));
    else
        show_response = findMaxN(response,N);
        figure(5);
        imshow(floor(show_response*255));
    end
end

function show_response = findMaxN(response,N)
    vec = reshape(response,[],1);
    sort_vec = sort(vec,'descend');
    maxN = sort_vec(1:N);
    show_pos = response>=min(maxN);
    show_response = show_pos.*response;
end