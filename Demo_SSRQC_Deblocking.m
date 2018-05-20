%   These MATLAB programs implement the image deblocking algorithm as described in paper:
%   
%     Title: Reducing Image Compression Artifacts by Structural Sparse Representation and Quantization Constraint Prior
%     Author: Chen Zhao, Jian Zhang, Siwei Ma, et.al.
%   
% 
% -------------------------------------------------------------------------------------------------------
% The software implemented by MatLab 7.10.0(2010a) are included in this package.
%
% ------------------------------------------------------------------
% Requirements
% ------------------------------------------------------------------
% *) Matlab 7.10.0(2010a) or later with installed:
% ------------------------------------------------------------------
% Version 2.0
% Author: Chen Zhao
% Email:  zhaochen@pku.edu.cn
% Last modified by C. Zhao, June 2016

clc;
clear;
cur = cd;
addpath(genpath(cur));

par = Set_parameters();                       % Set parameters

for JPEG_Quality = [5,10,15,25,40,50,70]        

    if JPEG_Quality >=40
        lambda = 0.7;
    else
        lambda = 0.5;
    end
       
    for ImgNo = 1 : par.AllImgNum        
        switch ImgNo
            case 1
                fn = 'Barbara256.tif';
            case 2
                fn = 'Vessels96.tif';
            case 3
                fn = 'Boat256.tif';
            case 4
                fn = 'butterfly256.tif';
            case 5
                fn = 'cameraman.tif';
        end
        
        %% Prepare noisy image       
        par.I = double(imread(fn));                                % original image
        [W, H] = size(par.I);
        JPEG_Name = 'My_test.jpg';
        randn('seed',0);
        
        imwrite(uint8(par.I),JPEG_Name,'Quality',JPEG_Quality);    % generate JPEG image
        par.nim = double(imread(JPEG_Name));                       % load the JPEG noisy image y
        JPEG_info = imfinfo(JPEG_Name);                            % get the JPEG image information
        bpp = JPEG_info.FileSize*8/(W*H);
        
        JPEG_Name_Com = strcat(fn,'_Quality_',num2str(JPEG_Quality),'_0_JPEG_PSNR_',num2str(csnr( par.nim ,par.I,0,0)),'dB.tif');
        imwrite(uint8(par.nim ),strcat('Results\',JPEG_Name_Com)); % store the JPEG image
        
        %% Set parameters
        JPEG_header_info = jpeg_read(JPEG_Name);         % get the JPEG header information
        par.QTable = JPEG_header_info.quant_tables{1};   % quantization table for 8*8 block
        par.C_q  = blkproc(par.nim , [8, 8], 'dct2');    % apply DCT to each block of y      
        meanQuant=mean(mean(par.QTable(1:3,1:3)));
        par.nSig = sqrt(0.69*meanQuant^1.3);             % Gaussian variance for the quantization noise model        
        par.lambda = lambda;                             % set lambda        
             
        %% Start the denoising algorithm
        disp('SSRQC Algorithm for Deblocking');      
        tic;
        [d_im, All_PSNR]  =  SSRQC_Solver_Deblocking_Iter_SBI(par.nim, par);
        run_time = toc;
        
        % Log information
        PSNR = csnr(d_im, par.I, 0, 0 );
        SSIM = cal_ssim(d_im, par.I, 0, 0);     
        Final_Name = strcat(fn,'_Quality_',num2str(JPEG_Quality),'_SSRQC_','Time_',num2str(run_time),...
            '_SSIM_',num2str(SSIM),'_PSNR_',num2str(PSNR),'dB.png');
        imwrite(uint8(d_im),strcat('Results\',Final_Name));       
        
    end
end





