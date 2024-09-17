function blendImg = alphablend_opencv(downImg,topImg,maskimage,int32_x,int32_y)%#codegen
% Brief: Write a function alphablend_opencv that calls the external library function.
% Details:
%    image stiching，支持单通道图像
%
% Syntax:
%     blendImg = alphablend_opencv(ownImg,topImg,maskimage,int32_x,int32_y)
%
% Inputs:
%    downImg - [m,n] size,[uint8] type,Description
%    topImg - [h,w] size,[uint8] type,Description
%    maskimage - [h,w] size,[logical] type,Description
%    int32_x - [1,1] size,[int32] type
%    int32_y - [1,1] size,[int32] type
%
% Outputs:
%    blendImg - [m,n] size,[uint8] type,Description
%
% codegen command:
%    downImg = coder.typeof(uint8(0),[10000,10000,3],[1,1,1]);
%    topImg = coder.typeof(uint8(0),[10000,10000,3],[1,1,1]);
%    maskimage = coder.typeof(logical(0),[10000,10000],[1,1]);
%    int32_x = int32(1);
%    int32_y = int32(1);
%
%    codegen -config:mex alphablend_opencv -args {downImg,topImg,maskimage,int32_x,int32_y} -lang:c++ -report
%
% Usage Example:
%    blendImg = alphablend_opencv(downImg,topImg,maskimage,int32_x,int32_y);
%
%
% Example:
%    None
%
% See also: None

% Author:                          cuixingxing
% Email:                           cuixingxing150@gmail.com
% Created:                         28-Feb-2023 08:47:41
% Version history revision notes:
%                                  None
% Implementation In Matlab R2022b
% Copyright © 2023 TheMatrix.All Rights Reserved.
%

arguments
    downImg uint8
    topImg uint8   % 大小必须与maskimage一致
    maskimage logical % 大小必须与topImg一致
    int32_x (1,1) int32 = 1; % 默认贴图锚点x坐标，注意MATLAB中索引是从1开始，而C/C++是从0开始，这里默认从点(1,1)开始贴图
    int32_y (1,1) int32 = 1; 
end

blendImg = OpenCV_API.alphaBlend(downImg,topImg,maskimage,int32_x,int32_y);
end