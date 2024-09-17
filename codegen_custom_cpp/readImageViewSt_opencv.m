function imageViewStArray = readImageViewSt_opencv(filename)%# codegen
% Brief: 在MATLAB中直接读取imageViewSt保存的图像特征和关键点集合
% Details:
%    None
%
% Syntax:
%     imageViewStArray = readImageViewSt_opencv(filename)
%
% Inputs:
%    filename - [m,n] size,[double] type,Description
%
% Outputs:
%    imageViewStArray - [m,n] size,[double] type,Description
%
% codegen command:
%    temp = '../data/preSavedData/imageViewSt.yml.gz';
%    filename = coder.typeof(temp,[1,inf]);
%    codegen -config:mex readImageViewSt_opencv -args filename -lang:c++  
%
%   % SIL vertifaction，可以和vscode一起调试
%   cfg = coder.config("lib");
%   cfg.VerificationMode = "SIL";
%   cfg.BuildConfiguration = "Debug";
%   cfg.SILPILDebugging = 1; 
%   codegen -config cfg readImageViewSt_opencv -args filename -lang:c++ -launchreport
%
%
% Usage Example:
%    读取当前目录下的filename的文件，如下程序所示
%    filename = './imageViewSt.yml';
%    imageViewStArray = readImageViewSt_opencv(filename);
%
% See also: None

% Author:                          cuixingxing
% Email:                           cuixingxing150@gmail.com
% Created:                         07-Apr-2023 09:07:01
% Version history revision notes:
%                                  None
% Implementation In Matlab R2023a
% Copyright © 2023 TheMatrix.All Rights Reserved.
%

arguments
    filename (1,:) char = './imageViewSt.yml'
end

if coder.target("MATLAB")
    imageViewStArray = readImageViewSt_opencv_mex(filename);% or readImageViewSt_opencv_sil debug
else
    imageViewStArray = struct("Features",zeros(0,32,"uint8"),...
        "Points",zeros(0,2,"double"));

    coder.varsize("imageViewStArray.Features",[inf,32]);
    coder.varsize("imageViewStArray.Points",[inf,2]);
    coder.varsize("imageViewStArray",[1,inf]);

    numEles = OpenCV_API.readImageViewStMetaNum(filename);
    imageViewStArray = repmat(imageViewStArray,1,numEles);
    for num = int32(1):numEles
        [rows,cols] = OpenCV_API.readImageViewStMeta(num);
        [singleImageFeatures,keyPoints] = OpenCV_API.readImageViewSt(num,rows,cols);
        imageViewStArray(num) = struct("Features",singleImageFeatures,...
            "Points",keyPoints);
    end
end
end