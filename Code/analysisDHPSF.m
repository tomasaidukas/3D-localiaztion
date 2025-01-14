function [X, Y, defocus] = analysisDHPSF(img, psf, ... 
                                         angle2defocus)
%------------------------------------------------------------%
% DHPSF method as developed by Standford university people.
% Locate peaks using correlation -> segment them out ->
% -> fit a 2D double Gaussian -> measure angle and distance
% between the peaks -> use a map to get defocus and point position.
%------------------------------------------------------------%

%------------------------------------------------------------%
% Find the point using cross-correlation
%------------------------------------------------------------%
% Find the Fourier transform of both images
FTpsf = fftshift(fft2(psf));
FTimg = fftshift(fft2(img));
% Power spectrum
CC = double(FTimg .* conj(FTpsf));% .* H);
% Cross-Correlation
cc = abs(ifftshift(ifft2(CC)));
[ROW, COL] = find(max(cc(:)) == cc);
C = [COL, ROW];


K = 25; NoPts = size(img, 2); samp = 1;
% Extract the region
box = img(C(2)-K:C(2)+K, C(1)-K:C(1)+K);
box = imresize(box, samp);
% Least square fitting routine for a double Gaussian
% Arrays used for result storage
peakCoords = [];
boxC = size(box, 1);

%------------------------------------------------------------%
% Initial guess for the centre locations using Hough circle
% detector
%------------------------------------------------------------%
[centers, radii] = imfindcircles(box, [1 10],'Sensitivity', 1);
% Take non-overlaping circles
temp1 = centers(1, :); temp2 = centers(2, :);
xc1 = temp1(1); yc1 = temp1(2); xc2 = temp2(1); yc2 = temp2(2);

for k = 2 : size(radii, 1)
    temp1 = centers(1, :); temp2 = centers(k, :);
    xc1 = temp1(1); yc1 = temp1(2); xc2 = temp2(1); yc2 = temp2(2);
    vect1 = xc1 - xc2; vect2 = yc1 - yc2;

    if sqrt(vect1^2 + vect2^2) >= (radii(1) + radii(k))
        xc1 = temp1(1); yc1 = temp1(2);
        xc2 = temp2(1); yc2 = temp2(2);
        break
    end
end

%------------------------------------------------------------%
% Initial guess for the peak heights using the peak values at the
% centroid positions. Fit the Gaussian.
%------------------------------------------------------------%
[n, m] = size(box); [X, Y] = meshgrid(1:n, 1:m);
options = optimset('TolX', 1e-20, 'Display', 'off'); 
boxC = size(box, 1);

% guess [normalization, xc, yc, sigma,
%        normalization, xc, yc, sigma]
guess = [max(box(:)), xc1, yc1, 1*samp, ...
         max(box(:)), xc2, yc2, 1*samp];
LB = [max(box(:))/4, 1, 1, 0, ...
      max(box(:))/4, 1, 1, 0];
UB = [max(box(:)), n, n, 5 * samp, ...
      max(box(:)), n, n, 5 * samp];

% least square fit
params = lsqnonlin(@(P) objfun(P, X, Y, box), guess, LB, UB, options);

% Shift the absolute co-ordinates
coords1 = [C(1) + (boxC / 2 - params(2)) ./ samp, ...
           C(2) + (boxC / 2 - params(3)) ./ samp];
coords2 = [C(1) + (boxC / 2 - params(6)) ./ samp, ...
           C(2) + (boxC / 2 - params(7)) ./ samp] ;       
%        
% midpt = [params(2) + params(6), params(3) + params(7)] ./ 2;
% figure; imshow(box, [])
% hold on; plot(params(2), params(3), '*')
% hold on; plot(params(6), params(7), '*')
% viscircles([centers(1,:); centers(k,:)], ...
%            [radii(1); radii(k)], 'EdgeColor','b');    
% hold on; plot(midpt(1), midpt(2), '*')
% hold on; plot([midpt(1), params(2)], [midpt(2), params(3)])
% hold on; plot([midpt(1), params(2)], [midpt(2), midpt(2)])

%------------------------------------------------------------%
% Take each peak pair and find the distance between them as well as
% the angle they make with the horizontal axis to determine the
% depth. The midpoint will be the localized co-ordinate in 2D.
%------------------------------------------------------------%
par1 = (params(2) - params(6)) ./ samp; par2 = (params(3) - params(7)) ./ samp;

ang = atand(par2 / par1);

% 
% figure; imshow(img, [])
% hold on
% plot(midpt(1), midpt(2), '*')
%------------------------------------------------------------%
% Use the created map to map angle -> defocus.
%------------------------------------------------------------%
defocus = feval(angle2defocus, ang);

midpt = [coords1(1) + coords2(1), coords1(2) + coords2(2)] ./ 2;

X = midpt(2); Y = midpt(1);
end

