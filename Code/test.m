clear all
close all

%------------------------------------------------------------%
% Load simulation data
%------------------------------------------------------------%
img = load('rand.mat');
img = img.finalimg;
img180 = load('randC.mat');
img180 = img180.finalimg180;
original = load('randO.mat');
original = original.original;
imgDH = load('randDH.mat');
imgDH = imgDH.finalimgDH;
NOISE = 0.0006;
sigmaRange = 5:10;

figure; imshow(img, [])
% figure; imshow(imgDH, [])
%------------------------------------------------------------%
% TO DO:
% 1. Locate CKM reconstructed points by correlating with a
% Gaussian?
% 2. What about deconvolving with PSF and looking when the
% disparity is minimized by using some bijection method
% for the defocus value.
%------------------------------------------------------------%

%------------------------------------------------------------%
% Parameters of the image/camera and initial defocus values 
% to be used for map generation.
%------------------------------------------------------------%
% Defocus
W20 = 0:0.5:3; 
maxDefocus = size(W20, 2);
NoPts = 870;
XYrange = 0.05;
R = 0.02;

%------------------------------------------------------------%
% Generates depth maps for CKM and DH-PSF.
%------------------------------------------------------------%
% [PSFs, angles, W20fit] = DHPSFmap(NoPts, XYrange, R, W20);
angles = load('./DHPSFdata/angles.mat'); angles = angles.angles;
PSFs = load('./DHPSFdata/templates.mat'); PSFs = PSFs.PSFs;
W20fit = load('./DHPSFdata/ang2defocus.mat'); angle2defocus = W20fit.W20fit;

% [dist, defoc] = CKMmap(img, img180, original, W20, NoPts, XYrange,...
%                         R, sigmaRange, NOISE);
CKMfit = load('../CKM/CKMdata/CKMfit.mat'); CKMfit = CKMfit.CKMfit;
         
%------------------------------------------------------------%
% DH-PSF localisation.
%------------------------------------------------------------%
% Load up the reference vector according to which the angles were
% measured. This vector corresponds to the angle at 0 defocus and is a
% unit vetor.
% [DHPSF2D, depthDHPSF, Xdhpsf Ydhpsf] = ...
%                     DHPSF(imgDH, angles, PSFs, angle2defocus);

%------------------------------------------------------------%
% CKM localisation.
%------------------------------------------------------------%
% depthCKM = correlationDepthCKM(img, img180, W20, NoPts, XYrange, R, 10)
% [imgCKM, mapCKM] = CKM(img, img180, original, depthCKM, NoPts, XYrange,...
%                        R, sigmaRange, NOISE);
% [CKM3D, CKM2D, depthCKM, Xckm, Yckm] = localCKM(mapCKM, imgCKM, depthCKM);
% figure; imshow(imgCKM, [])

[imgCKM, mapCKM] = CKM(img, img180, original, W20, NoPts, XYrange,...
                       R, sigmaRange, NOISE);
deconvDepthCKM(img, img180, mapCKM, imgCKM);
%------------------------------------------------------------%
% Visualize
%------------------------------------------------------------%
originalBW = imregionalmax(original); [row, col] = find(originalBW);
figure; imshow(original, [])
        hold on; plot(col, row, '.r')
        hold on; plot(Xckm, Yckm, '.b')
        hold on; plot(Xdhpsf, Ydhpsf, '.g')

%------------------------------------------------------------%
% Display depth values to check 3D localisation
%------------------------------------------------------------%
depthCKM
depthDHPSF