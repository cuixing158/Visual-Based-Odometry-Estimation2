function inputOutputStruct = readStructBin2(configFileName,binaryFileName)%#codegen
% Brief: 对二进制文件反序列化(读取)为结构体/数组S,弥补readStructBin函数不支持C/C++代码生成
% Details:
%    注意，本函数只针对本项目中特定的结构体域名（configFileName名字和顺序）做反序列化才有效！！！
%
% Syntax:
%     inputOutputStruct = readStructBin2(configFileName,binaryFileName)
%
% Inputs:
%    binaryFileName - [m,n] size,[double] type,Description
%
% Outputs:
%    inputOutputStruct - [m,n] size,[double] type,Description
%
% Example:
%    None
%
% See also: None

% Author:                          cuixingxing
% Email:                           cuixingxing150@gmail.com
% Created:                         20-Apr-2023 10:22:41
% Version history revision notes:
%                                  None
% Implementation In Matlab R2023a
% Copyright © 2023 TheMatrix.All Rights Reserved.
%

arguments
    configFileName (1,:) char
    binaryFileName (1,:) char
end
configFid = fopen(configFileName,"r");
if configFid == -1
    error('Error. \nCan''t open this file: %s.',configFileName)	% fopen failed
end
dataFid = fopen(binaryFileName,"r");
if dataFid == -1
    error('Error. \nCan''t open this file: %s.',binaryFileName)	% fopen failed
end
fileCloserCfg = onCleanup(@()(safeFclose(configFid)));
fileCloserData = onCleanup(@()(safeFclose(dataFid)));

%% read line by line
baseSupportClass =  {'double','single','int8','int16','int32','int64',...
    'uint8','uint16','uint32','uint64','logical', 'char','string'};
stringVar = "";
charVar = '';
doubleVar = 0;
singleVar = 0;
int8Var = int8(0);
int16Var = int16(0);
int32Var = int32(0);
int64Var = int64(0);
uint8Var = uint8(0);
uint16Var = uint16(0);
uint32Var = uint32(0);
uint64Var = uint64(0);
logicalVar = false;

ref = struct("XWorldLimits",[0.5000 2.500],...
    "YWorldLimits",[0.5000 2.500],...
    "ImageSize",[2,2]);% h*w
inputOutputStruct = struct("HDmap",struct("bigImg",zeros(1,0,"uint8"),"ref",ref),...
    "vehiclePoses",zeros(0,3,"double"),... % 输入输出初始化定义
    "cumDist",0.0,...
    "pixelExtentInWorldXY",0.03,...% 0.03 m/pixel
    "isBuildMap",false,...
    "buildMapStopFrame",1198,...
    "isBuildMapOver",false,...% 是否建图完毕
    "isLocSuccess",false,...
    "locVehiclePose",[0,0,0]);
coder.varsize("inputOutputStruct.HDmap.bigImg",[inf,inf]);
coder.varsize("inputOutputStruct.vehiclePoses",[inf,3]);

% Structure fields must be assigned in the same order on all control flow paths.
inputOutputStruct_HDmap = inputOutputStruct.HDmap;
inputOutputStruct_HDmap_bigImg = inputOutputStruct.HDmap.bigImg;
inputOutputStruct_HDmap_ref = inputOutputStruct.HDmap.ref;
inputOutputStruct_HDmap_ref_XWorldLimits = inputOutputStruct.HDmap.ref.XWorldLimits;
inputOutputStruct_HDmap_ref_YWorldLimits = inputOutputStruct.HDmap.ref.YWorldLimits;
inputOutputStruct_HDmap_ref_ImageSize = inputOutputStruct.HDmap.ref.ImageSize;
inputOutputStruct_vehiclePoses = inputOutputStruct.vehiclePoses;
inputOutputStruct_cumDist = inputOutputStruct.cumDist;
inputOutputStruct_pixelExtentInWorldXY = inputOutputStruct.pixelExtentInWorldXY;
inputOutputStruct_isBuildMap = inputOutputStruct.isBuildMap;
inputOutputStruct_buildMapStopFrame = inputOutputStruct.buildMapStopFrame;
inputOutputStruct_isBuildMapOver = inputOutputStruct.isBuildMapOver;
inputOutputStruct_isLocSuccess = inputOutputStruct.isLocSuccess;
inputOutputStruct_locVehiclePose = inputOutputStruct.locVehiclePose;

num = 1;
while ~feof(configFid)
    tline = fgetl(configFid);
    tline = eraseBetween(tline,'(',')','Boundaries','inclusive');

    pat1 = '=';
    pat2 = '*';
    pat3 = ',';
    idxEqual = strfind(tline,pat1);
    idxMultiply = strfind(tline,pat2);
    idxComma =strfind(tline,pat3);
    assert(numel(idxEqual)==1&&numel(idxMultiply)==2&&numel(idxComma)==1);
    idxEqual = idxEqual(1);
    idxComma = idxComma(1);

    % iterVarName = tline(1:idxEqual-1);
    hStr = tline(idxEqual+1:idxMultiply(1)-1);
    wStr = tline(idxMultiply(1)+1:idxMultiply(2)-1);
    cStr = tline(idxMultiply(2)+1:idxComma-1);
    iterVarSize = [real(str2double(hStr)),real(str2double(wStr)),real(str2double(cStr))];% note:str2double,Generated code always returns a complex result.
    iterVarType = tline(idxComma+1:end);

    % read binary
    if matches(iterVarType,baseSupportClass)
        numsEle = prod(iterVarSize,"all");
        if matches(iterVarType,'string')
            temp = fread(dataFid,numsEle,'char=>char');
            stringVar = string(reshape(temp,iterVarSize));
        elseif matches(iterVarType,'logical')
            temp = fread(dataFid,numsEle,'uint8=>uint8');
            temp = logical(temp);
            logicalVar = reshape(temp,iterVarSize);
        elseif matches(iterVarType,'double')
            doubleVar = fread(dataFid,numsEle,'double=>double');
            doubleVar = reshape(doubleVar,iterVarSize);
        elseif matches(iterVarType,'single')
            singleVar = fread(dataFid,numsEle,'single=>single');
            singleVar = reshape(singleVar,iterVarSize);
        elseif matches(iterVarType,'int8')
            int8Var = fread(dataFid,numsEle,'int8=>int8');
            int8Var = reshape(int8Var,iterVarSize);
        elseif matches(iterVarType,'int16')
            int16Var = fread(dataFid,numsEle,'int16=>int16');
            int16Var = reshape(int16Var,iterVarSize);
        elseif matches(iterVarType,'int32')
            int32Var = fread(dataFid,numsEle,'int32=>int32');
            int32Var = reshape(int32Var,iterVarSize);
        % elseif matches(iterVarType,'int64')
        %     int64Var = fread(dataFid,numsEle,'int64=>int64');
        %     int64Var = reshape(int64Var,iterVarSize);
        elseif matches(iterVarType,'uint8')
            uint8Var = fread(dataFid,numsEle,'uint8=>uint8');
            uint8Var = reshape(uint8Var,iterVarSize);
        elseif matches(iterVarType,'uint16')
            uint16Var = fread(dataFid,numsEle,'uint16=>uint16');
            uint16Var = reshape(uint16Var,iterVarSize);
        elseif matches(iterVarType,'uint32')
            uint32Var = fread(dataFid,numsEle,'uint32=>uint32');
            uint32Var = reshape(uint32Var,iterVarSize);
        % elseif matches(iterVarType,'uint64')
        %     uint64Var = fread(dataFid,numsEle,'uint64=>uint64');
        %     uint64Var = reshape(uint64Var,iterVarSize);
        elseif matches(iterVarType,'char')
            charVar = fread(dataFid,numsEle,'char=>char');
            charVar = reshape(charVar,iterVarSize);
        end

        % 以下判断结构体域名必须和configFileName描述一致!!! 手动指定域名
        if num == 2 % 第二行
            inputOutputStruct_HDmap = struct();
        elseif num ==3
            inputOutputStruct_HDmap_bigImg = uint8Var;
        elseif num == 4
            inputOutputStruct_HDmap_ref = struct();
        elseif num==5
            inputOutputStruct_HDmap_ref_XWorldLimits= doubleVar;
        elseif num==6
            inputOutputStruct_HDmap_ref_YWorldLimits= doubleVar;
        elseif num==7
            inputOutputStruct_HDmap_ref_ImageSize= doubleVar;
        elseif num==8
            inputOutputStruct_vehiclePoses= doubleVar;
        elseif num==9
            inputOutputStruct_cumDist= doubleVar;
        elseif num==10
            inputOutputStruct_pixelExtentInWorldXY= doubleVar;
        elseif num==11
            inputOutputStruct_isBuildMap = logicalVar;
        elseif num==12
            inputOutputStruct_buildMapStopFrame= doubleVar;
        elseif num==13
            inputOutputStruct_isBuildMapOver= logicalVar;
        elseif num==14
            inputOutputStruct_isLocSuccess= logicalVar;
        elseif num==15
            inputOutputStruct_locVehiclePose= doubleVar;
        end
    end
    num = num+1;
end

% 重新逐个顺序赋值,只能子级向父级展开赋值，否则会出现"Structure field '子集域名' is undefined on some execution paths."
% inputOutputStruct.HDmap.ref = inputOutputStruct_HDmap_ref;
inputOutputStruct.HDmap.ref.XWorldLimits= inputOutputStruct_HDmap_ref_XWorldLimits(1,1:2,1);
inputOutputStruct.HDmap.ref.YWorldLimits= inputOutputStruct_HDmap_ref_YWorldLimits(1,1:2,1);
inputOutputStruct.HDmap.ref.ImageSize= inputOutputStruct_HDmap_ref_ImageSize(1,1:2,1);

% inputOutputStruct.HDmap = inputOutputStruct_HDmap;
inputOutputStruct.HDmap.bigImg = inputOutputStruct_HDmap_bigImg(:,:,1);

inputOutputStruct.vehiclePoses= inputOutputStruct_vehiclePoses(:,:,1);
inputOutputStruct.cumDist= inputOutputStruct_cumDist(1,1,1);
inputOutputStruct.pixelExtentInWorldXY= inputOutputStruct_pixelExtentInWorldXY(1,1,1);
inputOutputStruct.isBuildMap = inputOutputStruct_isBuildMap(1,1,1);
inputOutputStruct.buildMapStopFrame= inputOutputStruct_buildMapStopFrame(1,1,1);
inputOutputStruct.isBuildMapOver= inputOutputStruct_isBuildMapOver(1,1,1);
inputOutputStruct.isLocSuccess= inputOutputStruct_isLocSuccess(1,1,1);
inputOutputStruct.locVehiclePose= inputOutputStruct_locVehiclePose(1,1:3,1);

end

%% support functions
function safeFclose(fid)
coder.inline('always')
if fid ~=-1
    fclose(fid);
end
end