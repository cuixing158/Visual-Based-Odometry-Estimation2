function grayImg = imread_opencv(imagePath)%#codegen
% Brief: Write a function imreadOpencv that calls the external library function.
% Details:
%    读取480*640, uint8灰度图像
%
% Syntax:
%     grayImg = imread_opencv(imagePath)
%
% Inputs:
%    imagePath - [m,n] size,[double] type,Description
%
% Outputs:
%    grayImg - [m,n] size,[double] type,Description
%
% codegen command:
%    imagePath = "/opt/matlab/R2022b/toolbox/matlab/imagesci/peppers.png";
%    input1 = coder.typeof(imagePath);
%    input1.StringLength=inf;
%
%    codegen -config:mex imread_opencv -args {input1}  -lang:c++ -launchreport
%
% Usage Example:
%    result = imread_opencv(imagePath);
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
    imagePath (1,1) string
end
grayImg = OpenCV_API.imread(imagePath);
end