%% test mex files

downImg = im2gray(imread("peppers.png"));
topImg = im2gray(imread("rice.png"));
maskimage = imbinarize(topImg);

int32_x = int32(100);
int32_y = int32(300);
tic
blendImg = alphablend_opencv(downImg,topImg,maskimage,int32_x,int32_y);
toc
figure;
imshow(blendImg)

%%
blender = vision.AlphaBlender('Operation','Binary Mask',...
    'MaskSource','Input port',...
    'LocationSource','Input port');

% big image test performance
matlab_blendTimes = [];
opencv_blendTimes = [];
for image_H_W = 500:50:8000
    H = image_H_W;
    W = image_H_W;

    bottomImg = zeros(H,W,'uint8');

    topImg = uint8(255*rand(H,W));
    maskImg = zeros(H,W,'logical');
    maskImg(1:500,1:500)=1;

%     outImg = blender(bottomImg,topImg,maskImg,[int32_x,int32_y]);
    tt1 = @()blender(bottomImg,topImg,maskImg,[int32_x,int32_y]);
    matlab_blendTimes = [matlab_blendTimes;timeit(tt1)];
%     fprintf('image size:(%d*%d) blender take time: %.3f seconds\n',H,W,timeit(tt1))

%     blendImg = alphablend_opencv(bottomImg,topImg,maskImg,int32_x,int32_y);
    tt2 = @()alphablend_opencv(bottomImg,topImg,maskImg,int32_x,int32_y);
%     fprintf('image size:(%d*%d) alphablend_opencv,take time: %.3f seconds\n',H,W,timeit(tt2))
    opencv_blendTimes = [opencv_blendTimes;timeit(tt2)];
end

figure;
plot(image_H_W,[matlab_blendTimes,opencv_blendTimes],LineWidth=2);
xlabel("image size");ylabel("time(second)")
legend(["matlabBlendTimes" "opencvBlendTimes"])
title("alphaBlend take time with image size")
grid on;