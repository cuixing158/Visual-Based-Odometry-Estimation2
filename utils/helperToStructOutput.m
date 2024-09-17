function outputStruct = helperToStructOutput(output)%#codegen
% This function converts contructWorldMap function output object to structure format.

outputStruct.HDmap.bigImg = output.HDmap.bigImg;
outputStruct.HDmap.ref.ImageSize = output.HDmap.ref.ImageSize;
outputStruct.HDmap.ref.XWorldLimits = output.HDmap.ref.XWorldLimits;
outputStruct.HDmap.ref.YWorldLimits = output.HDmap.ref.YWorldLimits;

outputStruct.vehicleTraj = output.vehicleTraj;
end