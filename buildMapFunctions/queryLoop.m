function [isLocationSuccess,locationPose,HDmap,vehiclePoses] = queryLoop(queryFeatures,queryPointsLoc,options)%#codegen
% Brief: slam 仅定位使用
% Details:
%    None
% 
% Syntax:  
%     [isLocationSuccess,locationPose,HDmap,vehiclePoses] = queryLoop(queryFeatures,queryPointsLoc,dbFilePath,imageViewStFile,vehicleROI)%#codegen
% 
% Inputs:
%    queryFeatures - [m,n] size,[double] type,Description
%    queryPointsLoc - [m,n] size,[double] type,Description
%    options - [m,n] size,[struct] type,Description
% 
% Outputs:
%    isLocationSuccess - [m,n] size,[double] type,Description
%    locationPose - [m,n] size,[double] type,Description
%    HDmap - [m,n] size,[double] type,Description
%    vehiclePoses - [m,n] size,[double] type,Description
% 
% Example: 
%    None
% 
% See also: None

% Author:                          cuixingxing
% Email:                           cuixingxing150@gmail.com
% Created:                         12-Apr-2023 16:54:17
% Version history revision notes:
%                                  None
% Implementation In Matlab R2023a
% Copyright © 2023 TheMatrix.All Rights Reserved.
%
persistent isLoad initFeaturesCell featuresPoints hdmap vposes
isLocationSuccess = false;
dbFilePath = options.placeRecDatabase;
vehicleROI = options.vehiclePolygon;% orb检测图大小上的像素点坐标

%% load data
unuseImage = coder.nullcopy(zeros(480,640,"uint8"));
unuseFeatures = coder.nullcopy(zeros(1,32,"uint8"));
unuseImagesList = "undefined";
if isempty(isLoad)
    % imageViewSt = readImageViewSt_opencv(imageViewStFile);
    imageViewSt = readStructBin3(options.imageViewStConfigFile,options.imageViewStDataFile);
    numFrames = numel(imageViewSt);

    initFeaturesCell = cell(1,numFrames);
    featuresPoints = cell(1,numFrames);

    if coder.target("MATLAB_DEBUG")
        initFeaturesCell = {imageViewSt.Features};
        featuresPoints = {imageViewSt.Points};
    else
        for idx = 1:numFrames
            initFeaturesCell{idx} = imageViewSt(idx).Features;
            featuresPoints{idx} = imageViewSt(idx).Points;
        end
    end

    inputOutputStruct = readStructBin2(options.hdMapConfigFile,options.hdMapDataFile);
    hdmap = inputOutputStruct.HDmap;
    vposes = inputOutputStruct.vehiclePoses;

    % create vocabulary and add image index
    loopDatabase_opencv(dbFilePath,unuseImage,unuseFeatures,unuseImagesList,{zeros(1,32,"uint8")},"load");

    fprintf("%s\n","Location,create vocabulary successful,now add index,please wait ...");

    for idx = 1:numFrames
        loopDatabase_opencv(dbFilePath,unuseImage,initFeaturesCell{idx},unuseImagesList,initFeaturesCell,"addFeatures");% 记录了每次currFrameIdx
    end
    fprintf("%s\n","Done.");
    isLoad = 1;
end
HDmap = hdmap;
vehiclePoses = reshape(vposes,size(vposes,1),3);

%% query loop
queryFeatures_uint8 = queryFeatures.Features;
result = loopDatabase_opencv(dbFilePath,unuseImage,queryFeatures_uint8,unuseImagesList,initFeaturesCell,"queryFeatures");
imageIDs = result(:,1);
scores = result(:,2);

minScore = min(scores(:));
bestScore = scores(2);
ratio = 0.6;% 根据实际图像调整此值
validIdxs = scores> max([bestScore*ratio, minScore,0.2]); % 0.2根据数据集经验取得,见doc/loopClosureDetect.md
loopKeyFrameIds = imageIDs(validIdxs);
locationPose = [0,0,0];
if numel(loopKeyFrameIds)>2
    groups = nchoosek(loopKeyFrameIds, 2);
    consecutiveGroups = groups(max(groups,[],2) - min(groups,[],2) <= 3, :);% 乱序的groups序号获得是否连续不大于3帧的序号
    if ~isempty(consecutiveGroups) % Consecutive candidates are found
        loopKeyFrameIds = consecutiveGroups(1,:);
        loopCandidate = loopKeyFrameIds(1);

        % match again
        preFeatures = binaryFeatures(initFeaturesCell{loopCandidate});
        prePointsLoc = featuresPoints{loopCandidate};
        currFeatures = queryFeatures;
        currPointsLoc = queryPointsLoc;
        [tform,~,~,~,~,status] = estiTform(preFeatures,prePointsLoc,currFeatures,currPointsLoc,vehicleROI);
        if status==0
            basePose = vehiclePoses(loopCandidate,:);
            basePoseA = [cos(basePose(3)),-sin(basePose(3)),basePose(1);
                sin(basePose(3)),cos(basePose(3)),basePose(2);
                0,0,1];
            vehicleCenterInBig = options.scalarHDmap.*mean(options.vehiclePolygon);
            initViclePtPose = rigidtform2d(0,[vehicleCenterInBig(1),vehicleCenterInBig(2)]);
            tempPose = invert(initViclePtPose);
            baseImagePose = tempPose.A*basePoseA;
            currImagePose = tform.A*baseImagePose;
            locationPose = rigidtform2d(initViclePtPose.A*currImagePose);
            locationPose = [locationPose.Translation,deg2rad(locationPose.RotationAngle)];
            isLocationSuccess = true;
        end
    else
        isLocationSuccess = false;
    end
end


