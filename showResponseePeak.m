function showResponseePeak(response)
    f5 = figure(5);
    h=surf(response);
    hold on;
%     a=get(h,'x');
%     b=get(h,'y');
%     c=get(h,'value');
    BW = imregionalmax(response);
    %[x,y,z] = findpeaks3(C01,mpd);
    local_max = [];
    sizeBW = size(BW);
    for i = 1:sizeBW(1)
        for j = 1:sizeBW(2)
            if BW(i,j)
                local_max =[local_max;j,i,response(i,j)]; 
            end
        end
    end
    [vert_delta, horiz_delta] = find(response == max(response(:)), 1);
    scatter3(local_max(:,1),local_max(:,2),local_max(:,3),'k');
    pause(0.5);  
%     scatter3(horiz_delta,vert_delta,response(vert_delta,horiz_delta),'r*');
    clf(f5);
end