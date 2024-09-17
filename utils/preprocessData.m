%% 预处理数据，用于对原始960*1280畸变图进行去畸变矫正
% 确保处理后的图像大小保持[480,640]，并且有效视野尽可能广，x,y各方向缩放需保持同尺度
%
% 在当前文件夹目录下执行此脚本处理

%% preprocess data
% 此数据来源于本项目中./undistortFisheyeFromSingleView/demo_geoImageWarp.m输出到mapX,mapY
load ../data/preSavedData/bev2D_mapX_mapY.mat 
imds = imageDatastore("/opt_disk2/rd22946/AllDataAndModels/from_tongwenchao/116");

% 确定各向同性(isotropic)缩放比例因子，使得尽可能目的图像达到[480,640]
[h,w] = size(mapX);
espectHW = [480,640];
if h/w<=espectHW(1)/espectHW(2)
    ratio = espectHW(1)/h;
    clipWidth = true;
else
    ratio = espectHW(2)/w;
    clipWidth = false;
end

tformIds = transform(imds,@(x)preprocess(x,mapX,mapY,ratio,clipWidth,espectHW));
writeall(tformIds,"/opt_disk2/rd22946/AllDataAndModels/from_tongwenchao/116_new_undistort",OutputFormat="jpg");


function outImg = preprocess(I,mapX,mapY,ratio,clipWidth,espectHW)
% 确保处理后的图像大小保持[480,640]，并且有效视野尽可能广，x,y各方向缩放保持同尺度
outImg = images.internal.interp2d(I,mapX,mapY,"linear",0, false);
outImg = imresize(outImg,ratio);
[h,w,~] = size(outImg);
if clipWidth
    x = round(w/2-espectHW(2)/2);
    cropROI = [x,1,espectHW(2)-1,espectHW(1)-1];
else
    y = round(h/2-espectHW(1)/2);
    cropROI = [1,y,espectHW(2)-1,espectHW(1)-1];
end
outImg = imcrop(outImg,cropROI);
end
