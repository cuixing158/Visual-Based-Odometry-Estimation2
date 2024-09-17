function pg = detectLoopAndAddGraph(pg,usePoseGraph,dbFilePath,initFeaturesCell,...
    featuresPoints,buildMapStopFrame,vehiclePolygon,scalarHDmap)%#codegen
% Brief: slam建图使用
% Details:
%    None
% 
% Syntax:  
%     [pg,fg] = detectLoopAndAddGraph(pg,fg,usePoseGraph,dbFilePath,initFeaturesCell,featuresPoints,buildMapStopFrame)%#codegen
% 
% Inputs:
%    pg - [m,n] size,[double] type,Description
%    fg - [m,n] size,[double] type,Description
%    usePoseGraph - [m,n] size,[double] type,Description
%    dbFilePath - [m,n] size,[double] type,Description
%    initFeaturesCell - [m,n] size,[double] type,Description
%    featuresPoints - [m,n] size,[double] type,Description
%    buildMapStopFrame - [m,n] size,[double] type,Description
% 
% Outputs:
%    pg - [m,n] size,[double] type,Description
%    fg - [m,n] size,[double] type,Description
% 
% Example: 
%    None
% 
% See also: None

% Author:                          cuixingxing
% Email:                           cuixingxing150@gmail.com
% Created:                         12-Apr-2023 08:55:35
% Version history revision notes:
%                                  None
% Implementation In Matlab R2023a
% Copyright © 2023 TheMatrix.All Rights Reserved.
%

unuseImage = coder.nullcopy(zeros(480,640,"uint8"));
unuseFeatures = coder.nullcopy(zeros(1,32,"uint8"));
unuseImagesList = "undefined";
% create vocabulary and add image index
if isfile(dbFilePath)
    loopDatabase_opencv(dbFilePath,unuseImage,unuseFeatures,unuseImagesList,{zeros(1,32,"uint8")},"load");
else
    loopDatabase_opencv(dbFilePath,unuseImage,unuseFeatures,unuseImagesList,initFeaturesCell,"initFeatures");% 会在dbFilePath路径下产生*.yml.gz文件
end

fprintf("%s\n","create vocabulary successful,now add index,please wait ...");
numFrames = numel(initFeaturesCell);
for idx = 1:numFrames
    loopDatabase_opencv(dbFilePath,unuseImage,initFeaturesCell{idx},unuseImagesList,initFeaturesCell,"addFeatures");% 记录了每次currFrameIdx
end
fprintf("%s\n","Done.");

% multiple loop
startDetectLoopIndex = max(buildMapStopFrame-500,1);
endDetectLoopIndex = buildMapStopFrame;
for idx = startDetectLoopIndex:10:endDetectLoopIndex
    result = loopDatabase_opencv(dbFilePath,unuseImage,initFeaturesCell{idx},unuseImagesList,initFeaturesCell,"queryFeatures");
    imageIDs = result(:,1);
    scores = result(:,2);
    nearestIDs = max(1,idx-100):idx;
    afterIDs = idx:endDetectLoopIndex;
    [loopKeyFrameIds,ia] = setdiff(imageIDs, [nearestIDs,afterIDs], 'stable');

    isDetectedLoop = false;
    loopCandidate = 1;
    if ~isempty(ia)
        minScore = min(scores(:));
        bestScore = scores(ia(1));
        ratio = 0.6;% 根据实际图像调整此值
        validIdxs = scores(ia)> max([bestScore*ratio, minScore,0.2]); % 0.2根据数据集经验取得,见doc/loopClosureDetect.md
        loopKeyFrameIds = loopKeyFrameIds(validIdxs);
        if numel(loopKeyFrameIds)>2
            groups = nchoosek(loopKeyFrameIds, 2);
            consecutiveGroups = groups(max(groups,[],2) - min(groups,[],2) <= 3, :);% 乱序的groups序号获得是否连续不大于3帧的序号
            if ~isempty(consecutiveGroups) % Consecutive candidates are found
                loopKeyFrameIds = consecutiveGroups(1,:);
                loopCandidate = loopKeyFrameIds(1);
                isDetectedLoop = true;
            else
                isDetectedLoop = false;
            end
        end
    end
    if isDetectedLoop
        feats1 = binaryFeatures(initFeaturesCell{loopCandidate});
        feats2 = binaryFeatures(initFeaturesCell{idx});
        pts1 = featuresPoints{loopCandidate};
        pts2 = featuresPoints{idx};

        [relTform,inliers,~,~,~,status] = estiTform(feats1,pts1,feats2,pts2,vehiclePolygon);
        relTform.A(1:2,3) = scalarHDmap.*relTform.A(1:2,3);
        if (status>0)||(sum(inliers,"all")<=3)
            continue;
        end
        measurement = [relTform.Translation,deg2rad(relTform.RotationAngle)];% 注意角度，是相对值,单位为弧度
        nodeID = [idx,loopCandidate];
        % if usePoseGraph
            addRelativePose(pg,measurement,[],nodeID(1),nodeID(2));
        % else
        %     f = factorTwoPoseSE2(nodeID,Measurement=measurement);% odometry
        %     addFactor(fg,f);
        % end
    end
end