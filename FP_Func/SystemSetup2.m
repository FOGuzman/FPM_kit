% function [ varargout ] = SystemSetup( varargin )
%SYSTEMSETUP initilize general system parameters for LED array microscope

% Last modofied on 4/22/2014 
% Lei Tian (lei_tian@berkeley.edu)

F = @(x) fftshift(fft2(x));
Ft = @(x) ifft2(ifftshift(x));
row = @(x) x(:).';

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% wavelength of illumination, assume monochromatic
% R: 624.4nm +- 50nm
% G: 518.0nm +- 50nm
% B: 476.4nm +- 50nm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lambda = 0.6292;
lambda = lamb(mmm);
if strcmp(settings.color_mode,'r')
lambda = lamb(1);;    
end
if strcmp(settings.color_mode,'g')
lambda = lamb(2);;    
end
if strcmp(settings.color_mode,'b')
lambda = lamb(3);;    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% numerical aperture of the objective
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NA = 0.1;
% maximum spatial frequency set by NA
um_m = NA/lambda;
% system resolution based on the NA
dx0 = 1/um_m/2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% magnification of the system,
% need to calibrate with calibration slides
% on 2x objective, front port with an extra 2x
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dpix_c = 1.12; %6.5um pixel size on the sensor plane
% dpix_c = 6;
% effective image pixel size on the object plane
dpix_m = dpix_c/mag; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% # of pixels at the output image patch
% each patch will assign a single k-vector, the image patch size cannot be
% too large to keep the single-k assumption holds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Np = 100;

% FoV in the object space
FoV = Np*dpix_m;
% sampling size at Fourier plane set by the image size (FoV)
% sampling size at Fourier plane is always = 1/FoV
if mod(Np,2) == 1
    du = 1/dpix_m/(Np-1);
else
    du = 1/FoV;
end

% low-pass filter diameter set by the NA = bandwidth of a single measurment
% in index
% N_NA = round(2*um_m/du_m);
% generate cutoff window by NA
m = 1:Np;
[mm,nn] = meshgrid(m-round((Np+1)/2));
ridx = sqrt(mm.^2+nn.^2);
um_idx = um_m/du;
% assume a circular pupil function, lpf due to finite NA
w_NA = double(ridx<um_idx);
% h = fspecial('gaussian',10,5);
% w_NA = imfilter(w_NA,h);

% support of OTF is 2x of ATF(NA)
Ps_otf = double(ridx<2*um_idx);

phC = ones(Np);
aberration = ones(Np);
pupil = w_NA.*phC.*aberration;

clear m mm nn

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up image corrdinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% original image size: 2160x2560
% can calibrate the center of the illumination with respect to the image by
% looking at the data from the dark/bright field image transitions

% start pixel of the image patch
% nstart = [981,1181];
% center, start & end of the image patch
img_ncent = nstart-ncent+Np/2;
img_center = (nstart-ncent+Np/2)*dpix_m;
img_start = nstart*dpix_m;
img_end = (nstart+Np)*dpix_m;

%% LED array geometries and derived quantities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% spacing between neighboring LEDs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% distance from the LED to the object
% experientally determined by placing a grating object
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% z_led = 80e3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% diameter of # of LEDs used in the experiment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dia_led = 7;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up LED coordinates
% h: horizontal, v: vertical
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if sqrt(length(orden)/rgb) == 2
lit_cenv = 1;
lit_cenh = 1;
vled = [0 1]-lit_cenv;
hled = [0 1]-lit_cenh;
end


if sqrt(length(orden)/rgb) == 3
lit_cenv = 1;
lit_cenh = 1;
vled = [0 1 2]-lit_cenv;
hled = [0 1 2]-lit_cenh;
end

if sqrt(length(orden)/rgb) == 5
lit_cenv = 2;
lit_cenh = 2;
vled = [0 1 2 3 4]-lit_cenv;
hled = [0 1 2 3 4]-lit_cenh;
end

if length(orden)/rgb == 37
lit_cenv = 3;
lit_cenh = 3;
vled = [0 1 2 3 4 5 6]-lit_cenv;
hled = [0 1 2 3 4 5 6]-lit_cenh;
end

[hhled,vvled] = meshgrid(hled,vled);
rrled = sqrt(hhled.^2+vvled.^2);
LitCoord = rrled<dia_led/2;
% total number of LEDs used in the experiment
Nled = sum(LitCoord(:));
% index of LEDs used in the experiment
Litidx = find(LitCoord);

% corresponding angles for each LEDs
dd = sqrt((-hhled*ds_led-img_center(1)).^2+(-vvled*ds_led-img_center(2)).^2+z_led.^2);

%Led points
x_points = -hhled*ds_led;
y_points = -vvled*ds_led;

%  x_points = OUT_X*1e3;
%  y_points = OUT_Y*1e3;

X = x_points/1e3;
Y = y_points/1e3;

% figure,
% plot(x_points,y_points,'.','MarkerEdgeColor','k'),grid on,axis image,xlim([-16 16]),ylim([-16 16]) 
% title('Led matrix (mm)')
% pause(0.6)
% clear x_points y_points 



sin_thetav = (x_points-img_center(1))./dd;
sin_thetah = (y_points-img_center(2))./dd;

illumination_na = sqrt(sin_thetav.^2+sin_thetah.^2);
% corresponding spatial freq for each LEDs
%
vled = sin_thetav/lambda;
uled = sin_thetah/lambda;
% spatial freq index for each plane wave relative to the center
idx_u = round(uled/du);
idx_v = round(vled/du);

illumination_na_used = illumination_na(LitCoord);

% number of brightfield image
NBF = sum(illumination_na_used<NA);


% maxium spatial frequency achievable based on the maximum illumination
% angle from the LED array and NA of the objective
um_p = max(illumination_na_used)/lambda+um_m;
% resolution achieved after freq post-processing
dx0_p = 1/um_p/2;

%disp(['synthetic NA is ',num2str(um_p*lambda)]);

% assume the max spatial freq of the original object
% um_obj>um_p
% assume the # of pixels of the original object
N_obj = round(2*um_p/du)*2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% need to enforce N_obj/Np = integer to ensure no FT artifacts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
N_obj = ceil(N_obj/Np)*Np;
% max spatial freq of the original object
um_obj = du*N_obj/2;

% sampling size of the object (=pixel size of the test image)
dx_obj = 1/um_obj/2;


% end
[xp,yp] = meshgrid([-Np/2:Np/2-1]*dpix_m);

x0 = [-N_obj/2:N_obj/2/2-1]*dx_obj;
[xx0,yy0] = meshgrid(x0);

%% define propagation transfer function
[u,v] = meshgrid(-um_obj:du:um_obj-du);

% Fresnel
% object defocus distance
z0=0;
H0 = exp(1i*2*pi/lambda*z0)*exp(-1i*pi*lambda*z0*(u.^2+v.^2));
% OR angular spectrum
% H0 = exp(1i*2*pi*sqrt((1/lambda^2-u.^2-v.^2).*double(sqrt(u.^2+v.^2)<1/lambda))*dz);


%% setting central LED & Intensity compensation
if sqrt(length(orden)/rgb) == 2
   led_central = 1; 
end

if sqrt(length(orden)/rgb) == 3
   led_central = 5; 
   Int_scale = [3 2 3 ...
                2 1 2 ...
                3 2 3];   
end

if sqrt(length(orden)/rgb) == 5
   led_central = 13;
   Int_scale = [05 05 05 05 05 ...
                05 03 02 03 05 ...
                05 02 01 02 05 ...
                05 03 03 03 05 ...
                05 05 05 05 05];
end

if length(orden)/rgb == 37
   led_central = 19; 
   Int_scale = [05 05 05 ...
             05 05 05 05 05 ...
          05 05 12 03 12 05 05 ...
          05 05 03 01 03 05 01 ...
          05 05 12 03 12 05 05 ...
             05 05 05 05 05 ...
                05 05 05];   
   
end