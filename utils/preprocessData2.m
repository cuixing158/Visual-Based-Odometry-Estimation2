%% 预处理数据，用于对原始960*1280畸变图进行去畸变矫正
% 本次使用2022年11月份估计的opencv四个系数进行去畸变，主要测试116/新图像数据集是否会影响拼接的"锯齿"效应？
%
% 结论：2023.7.24记录，
% 使用2022年11月份的调整的系数依旧会出现车道线"锯齿"效应，而且效果比2023年6月份调整的图像明显较差，故应当使用最新的去畸变模型参数(./undistortFisheyeFromSingleView/demo_geoImageWarp.m输出到mapX,mapY)
%
% 在当前文件夹目录下执行此脚本处理

%% preprocess data
% 此数据来源于本项目中./fisheyeOpenCVAndMatlab/demo_dynamicDistortCoff.mlx输出到mapX,mapY
load ../data/preSavedData/bev2D_mapX_mapY_opencv.mat 
imds = imageDatastore("/opt_disk2/rd22946/AllDataAndModels/from_tongwenchao/116");


tformIds = transform(imds,@(x)preprocess(x,mapX,mapY));
writeall(tformIds,"/opt_disk2/rd22946/AllDataAndModels/from_tongwenchao/116_resize",OutputFormat="jpg");


function outImg = preprocess(I,mapX,mapY)
% 确保处理后的图像大小保持[480,640]，并且有效视野尽可能广，x,y各方向缩放保持同尺度
outImg = images.internal.interp2d(I,mapX,mapY,"linear",0, false);
outImg = imresize(outImg,0.5);
end
