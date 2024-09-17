%% 用于测试代码生成的入口函数以及测试demo数据集表现是否正常
%
clear all; % 需要清除持续性变量
addpath("codegen_custom_cpp","buildMapFunctions","utils")
imgsDir = "C:/Users/Administrator/Desktop/birdEyeViewImages_480_640";
% imgNames = imgsDir+"/"+string(0:1452)+".jpg";
imds = imageDatastore(imgsDir);
imgNames = string(imds.Files);
imagePathList = "./data/preSavedData/imagePathList.txt";
writelines(imgNames,imagePathList)

% 输入参数，inputOutputStruct具体参数含义见constructWorldMap.m输入参数说明
ref = struct("XWorldLimits",[0.5000 2.500],...
    "YWorldLimits",[0.5000 2.500],...
    "ImageSize",[2,2]);% h*w
inputOutputStruct = struct("HDmap",struct("bigImg",zeros(0,1,"uint8"),"ref",ref),...
    "vehiclePoses",zeros(0,3,"double"),... % 输入输出初始化定义
    "cumDist",0.0,...
    "pixelExtentInWorldXY",0.015/0.51227,...% unit: m/pixel
    "isBuildMap",true,...
    "buildMapStopFrame",1120,...% 内部循环建图终止次数
    "isBuildMapOver",false,...% 是否建图完毕
    "isLocSuccess",false,...
    "locVehiclePose",[0,0,0]);
inputArgs = struct("undistortImage",zeros(480,640,'uint8'),...
        "currFrontBasePose",zeros(1,3,'double'),...% current unused
        "isuseGT",false);% 是否使用第三方的SLAM里程计数据

%% 主循环
if inputOutputStruct.isBuildMap
    modeFlag ="Mapping";
else
    modeFlag ="Locating";
end
hobj  = figure("Name","debug",Visible="on");
ax = axes(hobj);
for num = 1:1120
    % step1:每次迭代拿到当前图像和传感器数据
    inputArgs.undistortImage = im2gray(imread(imgNames(num)));

    % step2: 实时建图/定位
    t1 = tic;
    inputOutputStruct = constructWorldMap(inputArgs,inputOutputStruct);
    fprintf("Frame:%04d,elapsed seconds %.5f,Mode:%s,Cumulative Drive Distance:%.5f m\n",num,toc(t1),modeFlag,inputOutputStruct.cumDist);

    if inputOutputStruct.isBuildMapOver
        showImg = inputOutputStruct.HDmap.bigImg;
        if isempty(showImg)
            hold(ax,"on");grid(ax,"on");
            plot(ax,inputOutputStruct.vehiclePoses(:,1),inputOutputStruct.vehiclePoses(:,2),LineWidth=2);
        else
            showRef = imref2d(inputOutputStruct.HDmap.ref.ImageSize,...
                inputOutputStruct.HDmap.ref.XWorldLimits,...
                inputOutputStruct.HDmap.ref.YWorldLimits);
            imshow(showImg,showRef,Parent=ax);
        end
        title("mapping,Cumulative Drive Distance:"+string(inputOutputStruct.cumDist)+" m")
        hobj.Visible = "on";
        break;
    end

    if inputOutputStruct.isLocSuccess
        showImg = inputOutputStruct.HDmap.bigImg;
        if isempty(showImg)
            plot(ax,inputOutputStruct.vehiclePoses(:,1),inputOutputStruct.vehiclePoses(:,2),LineWidth=2);
        else
            showRef = imref2d(inputOutputStruct.HDmap.ref.ImageSize,...
                inputOutputStruct.HDmap.ref.XWorldLimits,...
                inputOutputStruct.HDmap.ref.YWorldLimits);
            imshow(showImg,showRef,Parent=ax);
        end
        locPose = inputOutputStruct.locVehiclePose;
        hold(ax,"on");grid(ax,"on");
        plot(locPose(1),locPose(2),Color="red",Marker="pentagram",MarkerSize=20,...
            MarkerEdgeColor="#D95319",MarkerFaceColor="#A2142F");
        vehiclePoses = inputOutputStruct.vehiclePoses;
        plot(ax,vehiclePoses(:,1),vehiclePoses(:,2),"b-",LineWidth=2)
        title("location successful, pose:"+"["+strjoin(string(inputOutputStruct.locVehiclePose),",")+"]")
        hobj.Visible = "on";
        break;
    end
    % drawnow limitrate;
end
