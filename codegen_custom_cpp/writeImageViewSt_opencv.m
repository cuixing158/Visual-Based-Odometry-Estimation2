function  writeImageViewSt_opencv(imageViewStArray,filename)%#codegen
% Brief: 在MATLAB中直接存储imageViewSt保存的图像特征和关键点集合
% Details:
%    None
%
% Syntax:
%      y = writeImageViewSt_opencv(imageViewStArray,filename)%#codegen
%
% Inputs:
%    imageViewStArray - [1,1] size,[struct] type,Description
%    filename - [1,1] size,[string] type,Description
%
% Outputs:
%    None
%
% codegen command:
%    imageViewStArray.Features = coder.typeof(uint8(0),[inf,32]);
%    imageViewStArray.Points = coder.typeof(double(0),[inf,2]);
%    imageViewStArray = coder.typeof(imageViewStArray,[1,inf]);
%
%    temp = "../data/preSavedData/imageViewSt.yml.gz";
%    filename = coder.typeof(temp);
%    filename.StringLength=255;
%    filename.VariableStringLength=true;
%    codegen -config:mex writeImageViewSt_opencv -args {imageViewStArray,filename} -lang:c++ -report
%
%   % SIL vertifaction，可以和vscode一起调试
%   cfg = coder.config("lib");
%   cfg.VerificationMode = "SIL";
%   cfg.BuildConfiguration = "Debug";
%   cfg.SILPILDebugging = 1; 
%   codegen -config cfg writeImageViewSt_opencv -args {imageViewStArray,filename} -lang:c++ -launchreport
%
% Usage Example:
%    为imageViewStArray数组保存在在当前目录下，如下程序所示
%    imageViewStArray = struct("Features",uint8(255*rand(10,32)),"Points",rand(10,2));
%    imageViewStArray(end+1) = imageViewStArray;
%    filename = "./myImgVst.yml";
%    writeImageViewSt_opencv(imageViewStArray,filename);
%
%
% See also: None

% Author:                          cuixingxing
% Email:                           cuixingxing150@gmail.com
% Created:                         07-Apr-2023 09:29:29
% Version history revision notes:
%                                  None
% Implementation In Matlab R2023a
% Copyright © 2023 TheMatrix.All Rights Reserved.
%

arguments
    imageViewStArray (1,:) struct% 必须含有"Features"和"Points"两个域名的数组,Features为:infx32 uint8，Points为：infx2 double
    filename (1,1) string = "./data/preSaveData/imageViewSt.yml.gz"
end
OpenCV_API.writeImageViewSt(imageViewStArray,filename);
end