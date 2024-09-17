function result = loopDatabase_opencv(dbFilePath,addImage,addFeatures,initImagesList,initFeaturesCell,flag)%#codegen
% Brief: 用于在x86_64平台/arm上生成C++代码直接使用外部库(DBOW3)
% Details:
%    本函数适用于x86-64平台使用DBOW3外部C++库
%
% Syntax:
%     result = loopDatabase_opencv(filePath,addImage,addFeatures,initImage,initFeaturesCell,flag)
%
% Inputs:
% flag: "initImagesList"时候,只使用initImagesList，其余参数一律跳过，其为图像绝对路径列表文件，无返回值；
% flag: "initFeatures"时候,只使用initFeaturesCell，其余参数一律跳过，其为:infx1的cell array，每个cell中保存Mix32大小的特征，无返回值；
%
% flag: "load"时候,只使用dbFilePath字典.yml.gz文件,其余参数一律跳过,无返回值；
%
% flag: "addImage"时候,只使用addImage，其余参数一律跳过,其为图像数组，无返回值；
% flag: "addFeatures"时候,只使用addFeatures,其余参数一律跳过,其为该图像特征数组,无返回值；
%
% flag: "query"时候,只使用addImage，其余参数一律跳过,其为图像数组，返回为n*2 double类型数组，第一列为queryID,第二列为score
%
% 注意：在实际使用中，flag中"<init_or_add>Image"(opencv提取特征)和"<init_or_add>Features"(matlab提取特征)只使用其中一组对应的匹配，功能一样
%
% Outputs:
%    result - 见arguments说明
%
% codegen command:
%    temp = "../data/preSavedData/database.yml.gz";
%    filePath = coder.typeof(temp);
%    filePath.StringLength=255;
%    filePath.VariableStringLength=true;
%    addImage = coder.typeof(uint8(0),[480,640]);% 480x640 image
%    addFeatures = coder.typeof(uint8(0),[480*640,32],[1,0]); % Mx32 features
%    initImagesList = filePath;
%    samplesCell = {zeros(480*640,32,"uint8"),zeros(5,32,"uint8")};
%    initFeaturesCell = coder.typeof(samplesCell,[1,inf]); % 1*N cell array, Mix32 features in each cell
%    flag = filePath;
%    codegen -config:mex loopDatabase_opencv -args {filePath,addImage,addFeatures,initImagesList,initFeaturesCell,flag} -lang:c++ -report
%
%   % SIL vertifaction，可以和vscode一起调试
%   cfg = coder.config("lib");
%   cfg.VerificationMode = "SIL";
%   cfg.BuildConfiguration = "Debug";
%   cfg.SILPILDebugging = 1; 
%   codegen -config cfg loopDatabase_opencv -args {filePath,addImage,addFeatures,initImagesList,initFeaturesCell,flag} -lang:c++ -launchreport
%
% Usage Example:
%    result = loopDatabase_opencv_mex(filePath,inImageOrFeatures,flag)
%
% See also: None
% Reference:
% [Specify Cell Array Inputs at the Command Line](https://www.mathworks.com/help/coder/ug/specify-cell-array-inputs-at-the-command-line.html)
%

% Author:                          cuixingxing
% Email:                           cuixingxing150@gmail.com
% Created:                         22-Feb-2023 14:00:19
% Version history revision notes:
%                                  2023.3.27修改输入参数，为避免C++代码生成引起歧义类型错误，每个参数根据flag参数只代表一种特定类型含义!
% Implementation In Matlab R2022b
% Copyright © 2023 TheMatrix.All Rights Reserved.
%

arguments
    dbFilePath (1,1) string %  "../data/preSavedData/database.yml.gz";
    addImage (480,640) uint8 % 为480*640的uint8图像
    addFeatures (:,32) uint8 % M*32的uint8特征
    initImagesList (1,1) string % "../data/preSavedData/imagePathList.txt";
    initFeaturesCell  (1,:) cell % N个M*32的uint8特征的cell array
    flag (1,1) string {mustBeMember(flag,{'initImagesList','initFeatures','load','addImage','addFeatures','queryImage','queryFeatures'})}
end

result = OpenCV_API.loopDatabase_x86_64(dbFilePath,addImage,addFeatures,initImagesList,initFeaturesCell,flag);
end