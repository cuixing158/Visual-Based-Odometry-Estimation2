function outImg = imwarp_opencv(inImg,tformA,outputView)%#codegen
% Brief: Write a function imwarp_opencv that calls the external library function.
% Details:
%    inImg为[0,255]范围uint8类型或者logical图像数组,单通道或者3通道均支持
%
% Syntax:
%     outImg = imwarp_opencv_mex(inImg,tformA,outputview)
%
% Inputs:
%    inImg - [m,n] size,[uint8] type,Description
%    tformA - [3,3] size,[double] type,Description
%    outputview - [1,1] size,[struct] type,Description
%
% Outputs:
%    outImg - [M,N] size,[double] type,Description
%    imageRef - [1,1] size,[struct] type,与outputview域一致,此处参数已去掉
%
% codegen command:
%    inImg1 = imread("peppers.png");
%    tform = rigidtform2d(30,[100,200]);
%    tformA = tform.A;
%    outV = imref2d(size(inImg1));
%    outputView = struct("XWorldLimits",outV.XWorldLimits,...
%                        "YWorldLimits",outV.YWorldLimits,...
%                        "ImageSize",outV.ImageSize);
%    in1 = coder.typeof(ones(1000,1000,3,"uint8"),[],1);% :1000×:1000×:3 uint8
%    in2 = coder.typeof(ones(1000,1000,"logical"),[],1);% :1000×:1000 logical
%    codegen -config:mex imwarp_opencv -args {in1,tformA,outputView} -args {in2,tformA,outputView} -lang:c++ -launchreport
%
% Useage Example:
%    outImg = imwarp_opencv_mex(inImg,tformA,outputView);
% See also: None

% Author:                          cuixingxing
% Email:                           cuixingxing150@gmail.com
% Created:                         20-Feb-2023 17:00:20
% Version history revision notes:
%                                  None
% Implementation In Matlab R2022b
% Copyright © 2023 TheMatrix.All Rights Reserved.
%

arguments
    inImg {mustBeA(inImg,{'uint8','logical'})} % 只能为uint8或者logical类型
    tformA (3,3) double
    outputView (1,1) struct = struct('XWorldLimits',double([1,size(inImg,2)]),...
        'YWorldLimits',double([1,size(inImg,1)]),...
        'ImageSize',double(size(inImg,[1,2])))
end

outImg = OpenCV_API.imageWarp(inImg,tformA,outputView);
end