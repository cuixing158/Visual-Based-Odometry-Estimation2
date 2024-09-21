%% 用于测试utils/文件夹中writeStructBin、readStructBin、readStructBin2函数的正确性和一致性+benchmark测试
% 结论：2023.4.20验证全部通过！以下测试用例全部通过，但readStructBin函数还未能支持C/C++代码生成，readStructBin2函数为其针对特定类型的替代，支持C/C++代码生成

%% 测试用例1
configFileName = "./data.cfg";
binaryFileName = "./data.stdata";
a = struct("a",1,"b",1:5,"c",struct("A",rand(3),"B","cuixing"),"d","name");
b = struct("a",2,"b",rand(3,5),"c",struct("A",rand(3),"B","xiaoming"),"d","xxxx");

myst = [a,b];
writeStructBin(myst,configFileName,binaryFileName);
myst = readStructBin(configFileName,binaryFileName);

%% 测试用例2
configFileName = "./data.cfg";
binaryFileName = "./data.stdata";
S1 = struct("a",1,"b",rand(1,3),"c",struct("A",[1,2],"B",'cuixing',"C",rand(5,2)),"d",uint8([15,123]));
S2 = struct("a",10,"b",rand(3,3),"c",struct("A",[5,6],"B",'matlab',"C",rand(10,2)),"d",uint8([10,200;50,32]));
S = [S1,S2];
writeStructBin(S,configFileName,binaryFileName);
M = readStructBin(configFileName,binaryFileName);% M与S验证结果一致

%% 测试用例3
% 以下测试针对readStructBin2函数
% step1: 任意读取一张uint8单通道图像，不限定大小
srcImg = im2gray(imread("peppers.png"));
ref = imref2d(size(srcImg));

% step2: 人工定义需要保存/加载的类似结构体inputOutputStruct
ref = struct("XWorldLimits",ref.XWorldLimits,...
    "YWorldLimits",ref.YWorldLimits,...
    "ImageSize",ref.ImageSize);% h*w
inputOutputStruct = struct("HDmap",struct("bigImg",srcImg,"ref",ref),...
    "vehiclePoses",zeros(0,3,"double"),... % 输入输出初始化定义
    "cumDist",0.0,...
    "pixelExtentInWorldXY",0.03,...% 0.03 m/pixel
    "isBuildMap",false,...
    "buildMapStopFrame",1198,...
    "isBuildMapOver",false,...% 是否建图完毕
    "isLocSuccess",false,...
    "locVehiclePose",[0,0,0]);
inputOutputStruct.vehiclePoses = rand(4,3);

% step3: 测试在运行时刻的读写情况
% inputOutputStruct，inputOutputStruct2，inputOutputStruct3三者结果一致!
writeStructBin(inputOutputStruct,"data.cfg","data.stdata") % 此函数支持任意结构体保存
inputOutputStruct2 = readStructBin2("data.cfg","data.stdata");% 只能在特定人工设计的结构体上读取
% inputOutputStruct3 = readStructBin2_mex("data.cfg","data.stdata");

%%  benchMark测试
addpath("./codegen_custom_cpp")
load('./data/preSavedData/imageViewSt.mat')

configFileName = "./data.cfg";
binaryFileName = "./data.stdata";
ymlFileName = "./data.yml.gz";

f1 = @()benchmarkTimeSave(aaa,configFileName,binaryFileName);% 自己实现的函数
f2 = @()benchmarkTimeLoad(configFileName,binaryFileName);% 自己实现的函数
% f3 = @()load('./data/preSavedData/imageViewSt.mat');% matlab内置mat
% f4 = @()save("temp.mat","aaa"); % error???, matlab内置mat
% t = tic;
% writeImageViewSt_opencv(aaa,ymlFileName); % opencv yml.gz序列化
% t_write = toc(t);
% t= tic;
% st = readImageViewSt_opencv(ymlFileName);% opencv yml.gz反序列化
% t_read = toc(t);

fprintf("writeStructBin elapsed seconds:%.2f,readStructBin: %.2f\n",timeit(f1),timeit(f2,1))
% fprintf("load elapsed seconds:%.2f,save: %.2f\n",timeit(f3),timeit(f4))

%% save or load,use tic,toc
t1 = tic;
aaa = load("temp.mat");
t2 = toc(t1);
fprintf("load: %.2f\n",t2)

function benchmarkTimeSave(st,configFileName,binaryFileName)
% 仅用于测试时间，自己实现的函数
writeStructBin(st,configFileName,binaryFileName);
end

function st = benchmarkTimeLoad(configFileName,binaryFileName)
% 仅用于测试时间，自己实现的函数
st = readStructBin(configFileName,binaryFileName);
end