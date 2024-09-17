function bigImgSt = fuseOptimizeHDMap(imageFiles,updateNodeVehiclePtPoses,initViclePtPose,BW)%#codegen
% Brief: One line description of what the function or class performs
% Details:
%    None
%
% Syntax:
%     bigImgSt = fuseOptimizeHDMap(imageFiles,updateNodeVehiclePtPoses,initViclePtPose)%#codegen
%
% Inputs:
%    imageFiles - [m,1] or [1,m]size,[string|cell array] type,image files names
%    updateNodeVehiclePtPoses - [m,3] size,[double] type,ego几何中心点轨迹坐标
%    initViclePtPose - [1,1] size,[rigidtform2d] type,初始图像上ego几何中心点坐标姿态
%    BW - scalarHW*[480,640] size,[logical] type,更新的ego mask
%
% Outputs:
%    bigImgSt - [1,1] size,[struct]
%    type,其定义为struct('bigImg',[],'ref',[])，存储优化后的姿态图输出
%
% Example:
%    None
%
% See also: None

% Author:                          cuixingxing
% Email:                           cuixingxing150@gmail.com
% Created:                         15-Dec-2022 09:22:42
% Version history revision notes:
%                                  None
% Implementation In Matlab R2022b
% Copyright © 2022 TheMatrix.All Rights Reserved.
%
numsImgs = length(imageFiles);
% tforms = repmat(rigidtform2d(),numsImgs,1);% 图像转换姿态
tforms = cell(numsImgs,1);% Code generation does not support rigidtform2d arrays.

% 求当前小图到大图像左上角点的转换，即图像转换矩阵,全局范围，用于定义总体图像大小
[Hc,Wc,Cc] =size(BW);
assert(Cc==1,"BW must be one dims");

xLimitsIn = [0.5,Hc+0.5];
yLimitsIn = [0.5,Wc+0.5];
xLimitsOutWorld = xLimitsIn;
yLimitsOutWorld = yLimitsIn;
for i = 1:numsImgs
    targetPose = rigidtform2d(rad2deg(updateNodeVehiclePtPoses(i,3)),updateNodeVehiclePtPoses(i,1:2));
    relR = eye(2);
    relT = relR'*(0-initViclePtPose.Translation)';
    relTform = rigidtform2d(relR,relT(1:2));
    imageTargetPose = rigidtform2d(targetPose.A*relTform.A);
    tforms{i} = imageTargetPose;

    [xLimitsOut,yLimitsOut] = outputLimits(imageTargetPose,xLimitsIn,yLimitsIn);
    xLimitsOutWorld = [min(xLimitsOutWorld(1),xLimitsOut(1)),max(xLimitsOutWorld(2),xLimitsOut(2))];
    yLimitsOutWorld = [min(yLimitsOutWorld(1),yLimitsOut(1)),max(yLimitsOutWorld(2),yLimitsOut(2))];
end

H = round(diff(yLimitsOutWorld));
W = round(diff(xLimitsOutWorld));
outRef = imref2d([H,W],xLimitsOutWorld,yLimitsOutWorld);
outRefSt = struct('XWorldLimits',outRef.XWorldLimits,...
        'YWorldLimits',outRef.YWorldLimits,...
        'ImageSize',outRef.ImageSize);

% fuse images
% blender = vision.AlphaBlender('Operation','Binary Mask',...
%     'MaskSource','Input port');
bottomImg = zeros(H,W,'uint8');
% outImg = coder.nullcopy(zeros(H,W,'uint8'));
% outBwImg = coder.nullcopy(zeros(H,W,'logical'));
for i = 1:numsImgs
    currImg = imread_opencv(imageFiles{i});
    currImg = imresize(currImg,[Hc,Wc]);
    outImg = imwarp_opencv(currImg,tforms{i}.A,outRefSt);
    outBwImg = imwarp_opencv(BW,tforms{i}.A,outRefSt);
    if i==1
        temp = true(size(BW));
        outBwImg = imwarp_opencv(temp,tforms{i}.A,outRefSt);
    end
    %     coder.varsize("bottomImg","outImg","outBwImg",[6000,6000]);
    %     bottomImg = blender(bottomImg,outImg,outBwImg);
    bottomImg = alphablend_opencv(bottomImg,outImg,outBwImg);
end
imref = struct("XWorldLimits",outRef.XWorldLimits,...
    "YWorldLimits",outRef.YWorldLimits,...
    "ImageSize",outRef.ImageSize);% h*w
bigImgSt = struct('bigImg',bottomImg,'ref',imref);



