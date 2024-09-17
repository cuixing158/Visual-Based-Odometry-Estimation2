function helperVisualizeScene2(images, labels)
% The helperVisualizeScene function displays the images arranged by their camera positions 
% relative to the vehicle on a 3-by-3 tiled chart layout and optionally shows the title text 
% for each of the tiles. 
% 
% 修改为展示我们场景下四副鱼眼图像
    
arguments
    images (1,5) cell
    labels (1,5) string = ["front","left","back","right","Ego Vehicle"]
end
  numImages = numel(images);    
  titleText = labels;
 
    
    % Define index locations to simulate the camera positions relative to the vehicle.
    cameraPosInFigureWindow = [2,4,8,6,5];
%     egoVehiclePosInFigureWindow = 5;
    
    figure
    t = tiledlayout(3, 3, "TileSpacing", "compact", "Padding", "compact");    
    for i = 1:numImages
        nexttile(cameraPosInFigureWindow(i)) 
        imshow(images{i})
        title(titleText(i))
    end
    title(t, "Pattern positions");
    
end