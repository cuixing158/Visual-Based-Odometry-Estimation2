function inputOutputStruct = constructWorldMap(inputArgs,inputOutputStruct,options)%#codegen
% Brief: 用于C++代码生成的入口函数，输入使用分辨率为640*480灰度BEV图像作为输入
% Details:
%    None
%
% Syntax:
%     inputOutputStruct = constructWorldMap(inputOutputStruct,inputArgs,birdsEye360)%#codegen
%
% Inputs:
%    inputArgs - [1,1] size,[struct] type,Description
%    options - [1,1] size,[struct] type,Description
%
% Outputs:
%    inputOutputStruct - [1,1] size,[struct] type,Description
%
% Example:
%    None
%
% See also: None

% Author:                          cuixingxing
% Email:                           cuixingxing150@gmail.com
% Created:                         25-Oct-2022 15:49:42
% Version history revision notes:
%                                  2023.2.14 改为直接使用俯视拼接后图像作为输入
%                                  2023.2.28 全部支持c/c++代码生成并成功验证
%                                  2023.4.4 修改为多个loop检测和定位入口
% Implementation In  R2023a
% Copyright © 2023 TheMatrix.All Rights Reserved.
%

arguments
    inputArgs (1,1) struct = struct("undistortImage",zeros(480,640,'uint8'),...
        "currFrontBasePose",zeros(1,3,'double'),...
        "isuseGT",false);% 是否使用第三方的SLAM里程计数据

    inputOutputStruct (1,1) struct = struct(...
        "HDmap",struct("bigImg",zeros(1,0,"uint8"),"ref",struct("XWorldLimits",[0.5000 2.500],"YWorldLimits",[0.5000 2.500],"ImageSize",[2,2])),...% 像素地图输出，bigImg是以options.scalarHDmap缩放尺度下的.
        "vehiclePoses",zeros(0,3,"double"),... % vehicle中心点累计姿态,每行形如[x,y,theta],位置为第一张图像并以options.scalarHDmap缩放尺度下为基准的像素坐标，角度单位为弧度
        "cumDist",0.0,...% 累计行驶距离
        "pixelExtentInWorldXY",0.015/0.51227,...% 原始童文超图像[960,1280]给的0.015 m/pixel，0.51227为原始[960,1280]图像缩放因子(utils/preprocessData.m)，在输入图像inputArgs.undistortImage上X,Y方向上每个像素实际距离长度
        "isBuildMap",true,... % 是否为建图模式，否则为定位模式,暴露给用户指定,以下4个为依赖此参数的参数
        "buildMapStopFrame",1118,...% 仅在建图模式下有效(依赖参数),stop的帧必须是之前访问过的场景/地点(不一定是回环)，暴露给用户指定
        "isBuildMapOver",false,...% 仅在建图模式下有效(依赖参数)，是否建图完毕
        "isLocSuccess",false,...% 仅在定位模式下有效(依赖参数)，是否定位成功
        "locVehiclePose",[0,0,0])% 仅在定位模式下有效(依赖参数)，成功模式下返回车辆位姿[xy,theta],位置为第一张图像为基准的像素坐标，角度单位为弧度

    options (1,1) struct = struct("isOutputHDMap",true,... % 代表是否实时输出建图图像，为true时候影响性能；当其为false时，inputOutputStruct.HDmap始终输出为空。
        "localImagePts", [1,480/2;% 左下,输入图像undistortImage中vehicle中上部分像素点
        1,1;% 左上
        640,1;%右上
        640,480/2],...%右下
        "vehiclePolygon",[285,325;% 由于匹配图像中有ego vehicle存在，故车辆范围内的特征点不考虑匹配,左下[x,y]坐标，输入图像undistortImage中vehicle四个角点
        285,156;% 左上
        358,156;%右上
        358,325],...%右下
        "usePoseGraph",true,...% 是否使用poseGraph优化,
        "scalarHDmap",1,...%  must scalar,(0,1]，输出实际像素地图的比例，为1时不缩放，小于1时候图像缩小，有利于程序快速执行
        "placeRecDatabase","./data/preSavedData/database.yml.gz",... % 建图产生/加载的词袋文件,定位必须有
        "imageViewStConfigFile","./data/preSavedData/imageViewSt.cfg",...% 建图产生的用于保存图像特征和关键点文件,定位必须有
        "imageViewStDataFile","./data/preSavedData/imageViewSt.stdata",...% 建图产生的用于保存图像特征和关键点文件,定位必须有
        "hdMapConfigFile","./data/preSavedData/hdMap.cfg",...% 建图产生的用于保存地图的文件,定位必须有
        "hdMapDataFile","./data/preSavedData/hdMap.stdata",...% 建图产生的用于保存地图的文件,定位必须有
        "imageListFile","./data/preSavedData/imagePathList.txt") % 用于最后姿态图优化的图像源，用于显示而已,如果不存在此文件，就不输出整个优化后像素图
end

persistent preFeatures prePoints preRelTform BW previousImgPose vehicleCenterInBig initViclePtPose prePoseNodes pg fg xLimitGlobal yLimitGlobal currFrameIdx pointTracker
persistent isFirst imageViewSt % loopdatabase use
persistent hfeature hfeature2 prevImg ax1 vehicleShowPts% MATLAB use, coder.target("MATLAB")

% Define Input Properties Programmatically in the C File
assert(isstruct(inputOutputStruct));

[h,w,c] = size(inputArgs.undistortImage);
assert(h == 480);
assert(w == 640);
assert(c == 1);

scaleFactor = 1.2;
numLevels = 8;
scaleH = options.scalarHDmap*h;
scaleW = options.scalarHDmap*w;

if isempty(BW)
    updateROIpts = options.scalarHDmap.*[options.localImagePts;
        options.vehiclePolygon(3,1),options.localImagePts(1,2);
        options.vehiclePolygon(3,1),options.vehiclePolygon(3,2);
        options.vehiclePolygon(2,1),options.vehiclePolygon(2,2);
        options.vehiclePolygon(2,1),options.localImagePts(1,2)]; %这里为手写定义需要更新的ROI,注意顺序

    BW = poly2mask(updateROIpts(:,1),updateROIpts(:,2),scaleH,scaleW);%此区域为更新区域

    % 以第一副图像坐标系为基准
    [preFeatures, ~,prePoints] = helperDetectAndExtractFeatures(inputArgs.undistortImage,scaleFactor, numLevels);
    preRelTform = rigidtform2d();
    previousImgPose = rigidtform2d();

    % step2:世界坐标系姿态转换为全局图像坐标姿态/第一副图像坐标系
    vehicleCenterInBig = options.scalarHDmap.*mean(options.vehiclePolygon);
    initViclePtPose = rigidtform2d(0,[vehicleCenterInBig(1),vehicleCenterInBig(2)]);
    prePoseNodes = rigidtform2d(0,[vehicleCenterInBig(1),vehicleCenterInBig(2)]);

    % loopdatabase use
    imageViewSt = coder.nullcopy(struct("Features",zeros(0,32,"uint8"),...% 用于loop创建词袋或者检索图像
        "Points",zeros(0,2,"double")));% 用于检索图像位姿估计
    coder.varsize("imageViewSt.Features",[inf,32]);
    coder.varsize("imageViewSt.Points",[inf,2]);
    coder.varsize("imageViewSt",[1,inf]);
    isFirst = true;

    % pose init
    if options.usePoseGraph
        pg = poseGraph('MaxNumEdges',10000,'MaxNumNodes',5000);
    else
        fg = factorGraph();
    end


    xLimitGlobal = [1,1];
    yLimitGlobal = [1,1];

    if coder.target("MATLAB")
        prevImg = inputArgs.undistortImage; % 仅供MATLAB使用
        figObj = figure(Name="consucrt map");
        ax1 = axes(figObj);
        imshow(imresize(inputArgs.undistortImage,[scaleH,scaleW]),'Parent',ax1);
        vehicleShowPts = [];% 大图上绘图轨迹点
        hfeature = figure(Name="matched features with rigid estimation");
        hfeature2 = figure(Name="matched features with no rigid estimation");
    end
    inputOutputStruct.pixelExtentInWorldXY = inputOutputStruct.pixelExtentInWorldXY./options.scalarHDmap;
    currFrameIdx = 0;

    pointTracker = vision.PointTracker('MaxBidirectionalError',1);
    initialize(pointTracker,prePoints,inputArgs.undistortImage);
end
currFrameIdx = currFrameIdx+1;



% 计算转换姿态，可以从3D SLAM中获取或者通过orb获取，目前从orb获取
[currFeatures, ~,currPoints] = helperDetectAndExtractFeatures(inputArgs.undistortImage,scaleFactor, numLevels);
[relTform,inliers,validInd1,validInd2,isOneSide,status,noRigidInd1,noRigidInd2] =...
    estiTform(preFeatures,prePoints,currFeatures,currPoints,options.vehiclePolygon);
relTform.A(1:2,3) = options.scalarHDmap.*relTform.A(1:2,3);

% KLT跟踪，对应opencv示例https://docs.opencv.org/3.4/d4/dee/tutorial_optical_flow.html
[trackPoints,point_validity] = pointTracker(inputArgs.undistortImage);
validPoints = trackPoints(point_validity, :);

cond =  status>0 || (sum(inliers,"all")<=3);
ratio = sum(inliers)/numel(inliers);
rigidTformType = 0;
if cond
    prePoints = prePoints(point_validity,:);
    % [currFeatures,currPoints] = extractFeatures(inputArgs.undistortImage,ORBPoints(validPoints));
    % currPoints = double(currPoints.Location);
    [relTform,inliers,validInd1,validInd2,isOneSide,status,noRigidInd1,noRigidInd2] = estiTform2(prePoints,validPoints,options.vehiclePolygon);
    relTform.A(1:2,3) = options.scalarHDmap.*relTform.A(1:2,3);

    cond =  status>0 || (sum(inliers,"all")<=3);
    if cond
        rigidTformType = 2;
        relTform = preRelTform;
    else
        rigidTformType = 1;
    end
end
setPoints(pointTracker,currPoints);


if coder.target("MATLAB")
    % ego估计不准姿态时候（1、阈值过大，可能跟丢，应多方面考虑，车速、车辆颠簸等；2、特征点过于集中）可视化显示
    % if cond || ratio<0.4||isOneSide
    if rigidTformType>0
        currShowPts = validPoints;
    else
        currShowPts = currPoints;
    end
    axRigid = gca(hfeature);axRigid.InnerPosition=[0,0,1,1];
    showMatchedFeatures(prevImg, inputArgs.undistortImage, prePoints(validInd1,:), ...
        currShowPts(validInd2,:), 'montage', 'Parent', axRigid);
    title(axRigid,"with rigid estimation,rigidTformType:"+string(rigidTformType))

    axNoRigid = gca(hfeature2);axNoRigid.InnerPosition=[0,0,1,1];
    showMatchedFeatures(prevImg, inputArgs.undistortImage, prePoints(noRigidInd1,:), ...
        currShowPts(noRigidInd2,:), 'montage', 'Parent',axNoRigid);
    title(axNoRigid,"with no rigid estimation,rigidTformType:"+string(rigidTformType))
    fprintf("current num:%04d,rigid tform: ratio:%03d/%03d=%.2f,isOneSide:%d,status:%d,rigidTformType:%d\n",...
        currFrameIdx,sum(inliers),numel(inliers),ratio,isOneSide,status,rigidTformType);
    % disp(relTform.A)
    % end
end
preRelTform = relTform;

% mapping
if inputOutputStruct.isBuildMap && currFrameIdx<=inputOutputStruct.buildMapStopFrame
    currImgPose = rigidtform2d(relTform.A*previousImgPose.A);
    % inv_R = currImgPose.R';
    % inv_T = -inv_R*currImgPose.Translation(:);
    % tform = rigidtform2d(inv_R,inv_T);% 避免求逆，可以提高速度？ tform =
    % invert(currImgPose);% occur some compile undefined error
    tform = invert(currImgPose);
    currVehiclePtPose = rigidtform2d(tform.A*initViclePtPose.A);
    inputOutputStruct.vehiclePoses = [inputOutputStruct.vehiclePoses;currVehiclePtPose.A(1,3),currVehiclePtPose.A(2,3),deg2rad(currVehiclePtPose.RotationAngle)];

    imageViewSt(end+1) = struct("Features",currFeatures.Features,...
        "Points",currPoints);
    if isFirst
        imageViewSt(1) = [];
        isFirst = false;
    end
    if currFrameIdx == inputOutputStruct.buildMapStopFrame % 开始poseGraph优化建图
        numFrames = numel(imageViewSt);
        assert(numFrames==currFrameIdx,"numFrames must equal to currFrameIdx");
        if coder.target("MATLAB")
            initFeaturesCell = {imageViewSt.Features};
            featuresPoints = {imageViewSt.Points};
        else
            initFeaturesCell = cell(1,numFrames);
            featuresPoints = cell(1,numFrames);
            for idx = 1:numFrames
                initFeaturesCell{idx} = imageViewSt(idx).Features;
                featuresPoints{idx} = imageViewSt(idx).Points;
            end
        end

        dbFilePath = options.placeRecDatabase;
        buildMapStopFrame = inputOutputStruct.buildMapStopFrame;
        pg = detectLoopAndAddGraph(pg,options.usePoseGraph,dbFilePath,...
            initFeaturesCell,featuresPoints,buildMapStopFrame,options.vehiclePolygon,options.scalarHDmap);

        if coder.target("MATLAB")&&options.usePoseGraph
            figure;pg.show("IDs","loopclosures");
        end

        % optimize pose
        updateNodeVehiclePtPoses = zeros(currFrameIdx,3);
        if options.usePoseGraph
            updatePg = optimizePoseGraph(pg);
            updateNodeVehiclePtPoses = nodeEstimates(updatePg)+[initViclePtPose.Translation,0];
            updateNodeVehiclePtPoses = updateNodeVehiclePtPoses(1:currFrameIdx,:);
        else
            fixNode(fg,1) % fix the start point.
            optns = factorGraphSolverOptions();
            optimize(fg,optns);
            for i = 1:currFrameIdx
                updateNodeVehiclePtPoses(i,:) = fg.nodeState(i);
            end
        end

        % 加入所有图像调整
        tempVar = (diff(updateNodeVehiclePtPoses(:,1:2)).*inputOutputStruct.pixelExtentInWorldXY).^2;
        inputOutputStruct.cumDist = sum(sqrt(sum(tempVar,2)));
        inputOutputStruct.vehiclePoses = updateNodeVehiclePtPoses;
        if options.isOutputHDMap % 是否以像素大地图展示建图结果
            if isfile(options.imageListFile)
                imageNames = coder.nullcopy(cell(currFrameIdx,1));
                fileID = fopen(options.imageListFile);
                for updateIdx = 1:currFrameIdx
                    imageNames{updateIdx} = fgetl(fileID);
                end
                fclose(fileID);
                fprintf("%s\n","The pose map optimization has been completed and is being stitched together to complete the larger image, please wait...");
                inputOutputStruct.HDmap = fuseOptimizeHDMap(imageNames,updateNodeVehiclePtPoses(1:currFrameIdx,:),initViclePtPose,BW);
            end
            
            if coder.target("MATLAB")&&isfile(options.imageListFile)
                imref = imref2d([inputOutputStruct.HDmap.ref.ImageSize],inputOutputStruct.HDmap.ref.XWorldLimits,inputOutputStruct.HDmap.ref.YWorldLimits);
                figure;imshow(inputOutputStruct.HDmap.bigImg,imref)
                title("init HD map,cumulative drive distance:"+string(inputOutputStruct.cumDist)+" m")
            end
        end

        inputOutputStruct.isBuildMapOver = true;% 建图完毕
        % writeImageViewSt_opencv(imageViewSt,options.imageViewStFile);%以opencv中yml.gz格式进行序列化保存，效率低，占用体积大，已放弃，改为下面方式
        writeStructBin(imageViewSt,options.imageViewStConfigFile,options.imageViewStDataFile);
        writeStructBin(inputOutputStruct,options.hdMapConfigFile,options.hdMapDataFile);
        return;
    end

    % 姿态图处理
    relR = prePoseNodes.R'*currVehiclePtPose.R;
    relT = prePoseNodes.R'*(currVehiclePtPose.Translation'-prePoseNodes.Translation');
    relPose = rigidtform2d(relR,relT);
    measurement = [relT(1),relT(2),deg2rad(relPose.RotationAngle)];% Relative measurement pose, [x,y,theta] format，theta is in radians.
    nodeID = [currFrameIdx,currFrameIdx+1];
    if options.usePoseGraph
        addRelativePose(pg,measurement,[],nodeID(1),nodeID(2));
    else
        f = factorTwoPoseSE2(nodeID,Measurement=measurement);% odometry
        addFactor(fg,f);
        nodeState(fg,currFrameIdx,[currVehiclePtPose.Translation,deg2rad(currVehiclePtPose.RotationAngle)]);% guess value
    end

    inputOutputStruct.cumDist = inputOutputStruct.cumDist+ sqrt((relT(1)*inputOutputStruct.pixelExtentInWorldXY(1)).^2+(relT(2)*inputOutputStruct.pixelExtentInWorldXY(1)).^2);
    prePoseNodes = currVehiclePtPose;
    previousImgPose = currImgPose;

    preFeatures = currFeatures;
    prePoints = currPoints;

    if options.isOutputHDMap % 是否以像素大地图展示建图结果
        % step3:针对当前4副鸟瞰图做变换到全局图像坐标系
        xLimitsIn = [0.5,scaleW+0.5];
        yLimitsIn = [0.5,scaleH+0.5];
        [xLimitsOut,yLimitsOut] = outputLimits(tform,xLimitsIn,yLimitsIn);

        % Width and height of panorama.
        xLimitInLocal = [min(xLimitsOut(1),xLimitsIn(1)),max(xLimitsIn(2),...
            xLimitsOut(2))];
        yLimitInLocal = [min(yLimitsOut(1),yLimitsIn(1)),max(yLimitsIn(2),...
            yLimitsOut(2))];

        xLimitGlobal = [min(xLimitGlobal(1),xLimitInLocal(1)),...
            max(xLimitGlobal(2),xLimitInLocal(2))];
        yLimitGlobal = [min(yLimitGlobal(1),yLimitInLocal(1)),...
            max(yLimitGlobal(2),yLimitInLocal(2))];

        outputImgWidth  = round(diff(xLimitGlobal));
        outputImgHeight = round(diff(yLimitGlobal));

        Ref = imref2d([outputImgHeight,outputImgWidth],xLimitGlobal,yLimitGlobal);
        outputview = struct('XWorldLimits',Ref.XWorldLimits,...
            'YWorldLimits',Ref.YWorldLimits,...
            'ImageSize',Ref.ImageSize);

        currViewImg = imwarp_opencv(imresize(inputArgs.undistortImage,options.scalarHDmap),tform.A,outputview);
        maskImg = imwarp_opencv(BW,tform.A,outputview);
        currRef = Ref;

        % step4: 融合到大图中去
        inputOutputStruct.HDmap = blendImage(inputOutputStruct.HDmap,currViewImg,currRef,maskImg);

        % step5: 实时显示建图过程
        if coder.target("MATLAB")
            prevImg = inputArgs.undistortImage;

            % step5: 绘图显示效果
            showBigImg = inputOutputStruct.HDmap.bigImg;
            showRef = inputOutputStruct.HDmap.ref;
            showRef = imref2d(showRef.ImageSize,showRef.XWorldLimits,showRef.YWorldLimits);
            imshow(showBigImg,showRef,Parent=ax1);hold(ax1,"on");% imshow大图像瞬时占内存

            % 画车辆行驶轨迹
            vehicleCenterInBig = [currVehiclePtPose.A(1,3),currVehiclePtPose.A(2,3)];
            vehicleShowPts = [vehicleShowPts;[vehicleCenterInBig(1),vehicleCenterInBig(2)]];
            plot(ax1,vehicleShowPts(:,1),vehicleShowPts(:,2),'r.-',LineWidth=2);

            % 画姿态图节点图
            if mod(currFrameIdx,50)==1
                if options.usePoseGraph
                    absolutePoses = nodeEstimates(pg);
                    currentNode = absolutePoses(end,:) + [initViclePtPose.Translation,0];
                else
                    currentNode = fg.nodeState(currFrameIdx);
                end
                plot(ax1,currentNode(1,1),currentNode(1,2),Color="black",LineWidth=1,Marker='.',MarkerSize=10);
            end

            % 画半径
            showRadii = [2;5;8];% 自定义半径，看2m,5m半径区域
            colors = ["red","green","blue"];
            xOrigin = vehicleCenterInBig(1);
            yOrigin = vehicleCenterInBig(2);
            radii = showRadii./inputOutputStruct.pixelExtentInWorldXY;
            for j = 1:length(radii)
                viscircles(ax1,[xOrigin,yOrigin],radii(j),Color=colors(j),LineWidth=1);
                text(ax1,(xOrigin+radii(j)),yOrigin,...
                    string(showRadii(j))+"m",...
                    "FontSize",20,"FontWeight","bold","Color",colors(j));
            end
            title(ax1,"Cumulative Drive Distance:"+string(inputOutputStruct.cumDist)+" m");
            hold off
            axis equal tight
            drawnow limitrate;
        end
    end
else % location
    assert(isfile(options.placeRecDatabase)&&isfile(options.imageViewStConfigFile)&&isfile(options.imageViewStDataFile)...
        &&isfile(options.hdMapConfigFile)&&isfile(options.hdMapDataFile));

    [inputOutputStruct.isLocSuccess,inputOutputStruct.locVehiclePose,...
        inputOutputStruct.HDmap,inputOutputStruct.vehiclePoses] = queryLoop(...
        currFeatures,currPoints,options);

    if coder.target("MATLAB")&& options.isOutputHDMap && inputOutputStruct.isLocSuccess
        imref = imref2d([inputOutputStruct.HDmap.ref.ImageSize],inputOutputStruct.HDmap.ref.XWorldLimits,inputOutputStruct.HDmap.ref.YWorldLimits);
        figure;imshow(inputOutputStruct.HDmap.bigImg,imref)
        locPose = inputOutputStruct.locVehiclePose;
        hold on;plot(locPose(1),locPose(2),'ro');
        title("location HD map,current vehicle pose:"+string(locPose))
    end

end % end of build map
