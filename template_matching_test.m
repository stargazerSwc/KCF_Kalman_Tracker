clear all; close all;

template = rgb2gray(imread('0T.jpg'));
background = rgb2gray(imread('0C.jpg'));

%% calculate padding
bx = size(background, 2); 
by = size(background, 1);
tx = size(template, 2); % used for bbox placement
ty = size(template, 1);

%% fft
%c = real(ifft2(fft2(background) .* fft2(template, by, bx)));

%// Change - Compute the cross power spectrum
Ga = fft2(background);
Gb = fft2(template, by, bx);
c = real(ifft2((Ga.*conj(Gb))./abs(Ga.*conj(Gb))));

%% find peak correlation
[max_c, imax]   = max(abs(c(:)));
[ypeak, xpeak] = find(c == max(c(:)));
figure; surf(c), shading flat; % plot correlation    

%% display best match
hFig = figure;
hAx  = axes;

%// New - no need to offset the coordinates anymore
%// xpeak and ypeak are already the top left corner of the matched window
position = [xpeak(1), ypeak(1), tx, ty];
imshow(background, 'Parent', hAx);
imrect(hAx, position);

