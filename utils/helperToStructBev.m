function bevStruct = helperToStructBev(bevObj)
% This function converts birdsEyeView input object to structure format.
% Copyright 2021 MathWorks, Inc.

    bevStruct.OutputView = bevObj.OutputView;
    bevStruct.ImageSize = bevObj.ImageSize;
    bevStruct.Sensor.Intrinsics.FocalLength = bevObj.Sensor.Intrinsics.FocalLength;
    bevStruct.Sensor.Intrinsics.PrincipalPoint = bevObj.Sensor.Intrinsics.PrincipalPoint;
    bevStruct.Sensor.Intrinsics.ImageSize = bevObj.Sensor.Intrinsics.ImageSize;
    bevStruct.Sensor.Intrinsics.RadialDistortion = bevObj.Sensor.Intrinsics.RadialDistortion;
    bevStruct.Sensor.Intrinsics.TangentialDistortion = bevObj.Sensor.Intrinsics.TangentialDistortion;
    bevStruct.Sensor.Intrinsics.Skew = bevObj.Sensor.Intrinsics.Skew;
    bevStruct.Sensor.Height = bevObj.Sensor.Height;
    bevStruct.Sensor.Pitch = bevObj.Sensor.Pitch;
    bevStruct.Sensor.Yaw = bevObj.Sensor.Yaw;
    bevStruct.Sensor.Roll = bevObj.Sensor.Roll;
    bevStruct.Sensor.SensorLocation = bevObj.Sensor.SensorLocation;
    bevStruct.Sensor.WorldUnits = bevObj.Sensor.WorldUnits;
end