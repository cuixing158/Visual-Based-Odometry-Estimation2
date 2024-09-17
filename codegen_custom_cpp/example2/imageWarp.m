function outImg = imageWarp(inImg, tformA,outputView)%#codegen
% Brief: 用于测试在生成的C++代码中直接使用自定义的C++函数文件或者Opencv函数.
% Details:
%    imwarp内建函数的opencv包装器。验证通过，最好使用MSVC环境编译mex，不容易崩溃，如mex有错误直接输出到命令行窗口
% 
% Syntax:  
%     outImg = imageWarp_mex(inImg, tformA,outputView)
% 
% Inputs:
%    inImg - 见arguments
%    tformA - 见arguments
%    outputView - 见arguments
% 
% Outputs:
%    outImg - [m,n] size,[double] type,Description
% 
% codegen command:
%    inImg = imread("peppers.png");
%    tform = rigidtform2d(30,[100,200]);
%    tformA = tform.A;
%    outV = imref2d(size(inImg));
%    outputView = struct("XWorldLimits",outV.XWorldLimits,...
%                        "YWorldLimits",outV.YWorldLimits,...
%                        "ImageSize",outV.ImageSize);
%    in1 = coder.typeof(ones(1000,1000,3,"uint8"),[],1);% :1000×:1000×:3 uint8
%    in2 = coder.typeof(ones(1000,1000,"logical"),[],1);% :1000×:1000 logical
%    codegen -config:mex imageWarp -args {in1,tformA,outputView} -args {in2,tformA,outputView} -launchreport -lang:c++
% 
% Example:
%     outImg = imageWarp_mex(inImg, tformA,outputView);
%
% See also: None

% Author:                          cuixingxing
% Email:                           cuixingxing150@gmail.com
% Created:                         21-Feb-2023 11:10:15
% Version history revision notes:
%                                  None
% Implementation In Matlab R2022b
% Copyright © 2023 TheMatrix.All Rights Reserved.
%

arguments
    inImg {mustBeA(inImg,{'uint8','logical'})}% 只能为uint8或者logical类型
    tformA (3,3) double % 类型{"rigidtform2d","affinetform2d","projtform2d"}之一的齐次转换矩阵A
    outputView (1,1) struct = struct('XWorldLimits',double([1,size(inImg,2)]),...
        'YWorldLimits',double([1,size(inImg,1)]),...
        'ImageSize',double(size(inImg,[1,2])))
end

assert(isa(inImg,"uint8")||isa(inImg,"logical"));

[imgRows,imgCols,imgChannels] = size(inImg);
outImg = zeros(outputView.ImageSize(1),outputView.ImageSize(2),imgChannels,"like",inImg);

if coder.target('MATLAB')
    % running in MATLAB, use built-in addition
    if abs(tformA(3,1))>10*eps||abs(tformA(3,2))>10*eps
        tform = projtform2d(tformA);
    else
        tform = rigidtform2d(tformA);
    end
    outputView = imref2d(outputView.ImageSize,outputView.XWorldLimits,outputView.YWorldLimits);
    outImg = imwarp(inImg,tform,'OutputView',outputView);
else
    % OpenCV include files
    OPENCV_DIR = "/home/matlab/opencv_4_6_0";
    includeFilePath1 = OPENCV_DIR+"/include/opencv4";
    coder.updateBuildInfo('addIncludePaths',includeFilePath1);

    % link opencv lib
    libPriority = '';
    libPreCompiled = true;
    libLinkOnly = true;
    libName = 'libopencv_world.so.406';%'libopencv_world440.dll.a';
    libPath = OPENCV_DIR+"/lib"; % "x64/mingw/lib"
    coder.updateBuildInfo('addLinkObjects', libName, libPath, ...
        libPriority, libPreCompiled, libLinkOnly);
%     coder.updateBuildInfo('addLinkFlags',options)

    % include external C++ functions 
    externCppFolder = "./";% 自己写的入口C++函数
    coder.updateBuildInfo('addIncludePaths',externCppFolder);
    coder.updateBuildInfo('addSourcePaths',externCppFolder)
    coder.updateBuildInfo('addSourceFiles', 'opencvAPI.cpp');
    
    % Add the required include statements to the generated function code
    coder.cinclude('opencvAPI.h');

    % 调用OpenCV C++代码包装器
    s  = struct('XWorldLimits',outputView.XWorldLimits,...
        'YWorldLimits',outputView.YWorldLimits,...
        'ImageSize',outputView.ImageSize);
    coder.cstructname(s,'imref2d','extern','HeaderFile','opencvAPI.h');
    coder.ceval('imwarp2', coder.rref(inImg),int32(imgRows),...% coder.rref对应C语言的const reference
        int32(imgCols),int32(imgChannels),...
        coder.ref(tformA),coder.ref(s),coder.wref(outImg));
end
end