function bevObj = helperToObjectBev(bevStruct)
% This function converts input birdsEyeView object in structure format back to object.
% Copyright 2021 MathWorks, Inc.

% #codegen
%% Step 1: Convert monoCamera struct to Object

% Create cameraIntrinsics object to struct
cameraIntrinsicsObject = cameraIntrinsics(bevStruct.Sensor.Intrinsics.FocalLength,bevStruct.Sensor.Intrinsics.PrincipalPoint,...
    bevStruct.Sensor.Intrinsics.ImageSize,'RadialDistortion',bevStruct.Sensor.Intrinsics.RadialDistortion,...
    'TangentialDistortion',bevStruct.Sensor.Intrinsics.TangentialDistortion,'Skew',bevStruct.Sensor.Intrinsics.Skew);

% Create monocamera object
monoCameraObject = monoCamera(cameraIntrinsicsObject,bevStruct.Sensor.Height,'Pitch',bevStruct.Sensor.Pitch,...
    'Yaw',bevStruct.Sensor.Yaw,'Roll',bevStruct.Sensor.Roll,'SensorLocation',bevStruct.Sensor.SensorLocation,...
    'WorldUnits',bevStruct.Sensor.WorldUnits);

%% Step 2: Create Birds eye view object

bevObj = birdsEyeView(monoCameraObject,bevStruct.OutputView,bevStruct.ImageSize);

end