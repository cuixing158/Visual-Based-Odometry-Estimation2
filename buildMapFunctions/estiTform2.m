function [tform,inlierIdx,validInd1,validInd2,isOneSide,status,noRigidInd1,noRigidInd2] = estiTform2(prePoints,currPoints,vehicleROI)%#codegen

assert(size(prePoints,1)==size(currPoints,1));

% 排除ego本身的匹配，即车身周围矩形范围的点不应该考虑
in1 = inpolygon(prePoints(:,1),prePoints(:,2),vehicleROI(:,1),vehicleROI(:,2));
in2 = inpolygon(currPoints(:,1),currPoints(:,2),vehicleROI(:,1),vehicleROI(:,2));

index1 = 1:size(prePoints,1);
index2 = 1:size(currPoints,1);

coInlierIdx = (~in1)&(~in2);
prePoints = prePoints(coInlierIdx,:);
currPoints = currPoints(coInlierIdx,:);

noRigidInd1 = index1(coInlierIdx);
noRigidInd2 = index2(coInlierIdx);

[tform,inlierIdx,status] = estgeotform2d(prePoints,currPoints,"rigid");
validInd1 = noRigidInd1(inlierIdx);
validInd2 = noRigidInd2(inlierIdx);


preTformPoints = prePoints(inlierIdx,:);
currTformPoints = currPoints(inlierIdx,:);
isOneSide = true;
if ~isempty(currTformPoints)
    A = (vehicleROI(1,:)+vehicleROI(end,:))/2;
    B = (vehicleROI(2,:)+vehicleROI(3,:))/2;
    a = A(2)-B(2);
    b = B(1)-A(1);
    c = A(1)*B(2)-A(2)*B(1);
    % ax+by+c==0
    isOneSide = all(a*currTformPoints(:,1)+b*currTformPoints(:,2)+c>0)||...
        all(a*currTformPoints(:,1)+b*currTformPoints(:,2)+c<0);

    % too close should exclude
    thresholdRadius = 20;% 像素半径
    xRange1 = max(preTformPoints(:,1))-min(preTformPoints(:,1));
    yRange1 = max(preTformPoints(:,2))-min(preTformPoints(:,2));
    xRange2 = max(currTformPoints(:,1))-min(currTformPoints(:,1));
    yRange2 = max(currTformPoints(:,2))-min(currTformPoints(:,2));
    radius1 = sqrt(xRange1.^2+yRange1.^2);
    radius2 = sqrt(xRange2.^2+yRange2.^2);
    if radius1<thresholdRadius||radius2<thresholdRadius
        status = int32(3);
    end
end
end
