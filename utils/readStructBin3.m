function imageViewSt = readStructBin3(configFileName,binaryFileName)%#codegen
% Brief: 对二进制文件反序列化(读取)为结构体/数组S,弥补readStructBin函数不支持C/C++代码生成
% Details:
%    注意，本函数只针对本项目中特定的结构体域名（configFileName名字和顺序）做反序列化才有效！！！
%
% Syntax:
%     imageViewSt = readStructBin3(configFileName,binaryFileName)
%
% Inputs:
%    configFileName - [m,n] size,[double] type,Description
%    binaryFileName - [m,n] size,[double] type,Description
%
% Outputs:
%    imageViewSt - [m,n] size,[double] type,Description
%
% Example:
%    None
%
% See also: None

% Author:                          cuixingxing
% Email:                           cuixingxing150@gmail.com
% Created:                         24-Apr-2023 01:27:42
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
firstLine = fgetl(configFid);
pat1 = '=';
pat2 = '*';
pat3 = ',';
idxEqual = strfind(firstLine,pat1);
idxMultiply = strfind(firstLine,pat2);
idxComma =strfind(firstLine,pat3);
assert(numel(idxEqual)==1&&numel(idxMultiply)==2&&numel(idxComma)==1);
idxEqual = idxEqual(1);
idxComma = idxComma(1);

% iterVarName = tline(1:idxEqual-1);
hStr = firstLine(idxEqual+1:idxMultiply(1)-1);
wStr = firstLine(idxMultiply(1)+1:idxMultiply(2)-1);
cStr = firstLine(idxMultiply(2)+1:idxComma-1);
iterVarSize = [real(str2double(hStr)),real(str2double(wStr)),real(str2double(cStr))];% note:str2double,Generated code always returns a complex result.
iterVarType = firstLine(idxComma+1:end);

assert((iterVarSize(1) ==1)&&(iterVarSize(3)==1));
assert(strcmp(iterVarType,'struct'));

numsSt = iterVarSize(2);
item = struct("Features",zeros(1,32,"uint8"),...
    "Points",zeros(1,2,"double"));
coder.varsize("imageViewSt.Features",[inf,32]);
coder.varsize("imageViewSt.Points",[inf,2]);
imageViewSt = coder.nullcopy(repmat(item,[1,numsSt]));

num = 0;
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
        if matches(iterVarType,'uint8')
            temp = fread(dataFid,numsEle,'uint8=>uint8');
            imageViewSt(num).Features = reshape(temp,iterVarSize(1),32);% iterVarSize 
        elseif matches(iterVarType,'double')
            temp = fread(dataFid,numsEle,'double=>double');
            imageViewSt(num).Points = reshape(temp,iterVarSize(1),2);
        end
    elseif matches(iterVarType,'struct')
        num = num+1;
    end
end
end

%% support functions
function safeFclose(fid)
coder.inline('always')
if fid ~=-1
    fclose(fid);
end
end