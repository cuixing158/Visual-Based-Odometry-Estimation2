%================================================================
% This class abstracts the API to an external OpenCV library.
% It implements static methods for updating the build information
% at compile time and build time.
% 生成的C/C++代码中直接调用OpenCV库函数，也支持mex生成,目的用于使用性能较好的库函
% 数和外部第三方C++代码（DBOW3）集成。
%
% 2023.2.23 验证全部通过！
% reference:
% [1] coder.ExternalDependency class
% [2] Integrate External/Custom Code
% [3] Develop Interface for External C/C++ Code
% [4] coder.BuildConfig class
% [5] https://www.mathworks.com/matlabcentral/answers/1844993-matlab-coder-generating-c-code-for-general-functions-is-a-big-performance-problem
% [6] https://www.mathworks.com/matlabcentral/answers/1917410-matlab-coder-generating-c-code-for-scalar-string-results-in-a-garbled-last-character
% [7] [C语言类型与MATLAB类型对应关系](https://www.mathworks.com/help/matlab/matlab_external/passing-arguments-to-shared-library-functions.html)
%================================================================

classdef OpenCV_API < coder.ExternalDependency
    %#codegen

    methods (Static)

        function bName = getDescriptiveName(~)
            bName = 'OpenCV_API';
        end

        function tf = isSupportedContext(buildContext)
            myTarget = {'mex','rtw'};% 验证代码生成目标为mex或者dll,lib,exe
            if  buildContext.isCodeGenTarget(myTarget)
                tf = true;
            else
                error('OpenCV_API only supported for mex, lib, exe, dll');
            end

            %             hw = buildContext.getHardwareImplementation();

        end

        function updateBuildInfo(buildInfo, buildContext)
            % 输入buildInfo请参考：RTW.BuildInfo
            % 输入buildContext请参考：coder.BuildConfig class
            %
            % Get file extensions for the current platform
            %             [~, linkLibExt, execLibExt, ~] = buildContext.getStdLibInfo();

            if isunix% Code to run on Linux platform
                isDockerContainer = false;
                if isDockerContainer
                    OPENCV_DIR = "/usr/local/include/opencv4";
                    projectDIR = "/home/matlab/matlab_works/buildMapping";
                    includeFilePath = OPENCV_DIR;
                    libPath = "/usr/local/lib";
                else
                    OPENCV_DIR = "/opt_disk2/rd22946/opencv4_6_0";
                    projectDIR = "/opt_disk2/rd22946/matlab_works/buildMapping";
                    includeFilePath = fullfile(OPENCV_DIR,"include","opencv4");
                    libPath = fullfile(OPENCV_DIR,"lib/");
                end
                buildInfo.addIncludePaths(includeFilePath);

                % Link files
                linkFiles = "libopencv_world.so";
                linkPath = libPath;
                linkPriority = "";
                linkPrecompiled = true;
                linkLinkOnly = true;
                group = '';
                buildInfo.addLinkObjects(linkFiles, linkPath, ...
                    linkPriority, linkPrecompiled, linkLinkOnly, group);

                % DBOW3 include files
                DBOW3_DIR = fullfile(projectDIR,"DBOW3/");
                includeFilePath1 = fullfile(DBOW3_DIR,"src");% 第三方库函数
                includeFilePath2 = fullfile(DBOW3_DIR,"c_file");% 自己写的入口函数文件夹
                buildInfo.addIncludePaths([includeFilePath1,includeFilePath2]);
                buildInfo.addSourcePaths([includeFilePath1,includeFilePath2]);

                % DBOW3 source files
                dbowSrc = ["BowVector.cpp","Database.cpp","DescManip.cpp","FeatureVector.cpp",...
                    "QueryResults.cpp","quicklz.c","ScoringObject.cpp","Vocabulary.cpp"];
                buildInfo.addSourceFiles(dbowSrc);

            elseif ispc % Code to run on Windows platform
                % OpenCV include files
                useMINGW = true;% mex -setup C++ 选择对应的编译器
                if useMINGW
                    OPENCV_DIR = "E:/opencv4_4_0/opencv/MinGW64_v8_OpenCV4_4_Contrib_install";%; % note: use msvc complier library,generated mex file can print error,which can be debug!
                    libPath = fullfile(OPENCV_DIR,"x64\mingw\lib");
                    linkFiles = "libopencv_world440.dll.a";
                else
                    OPENCV_DIR = "D:/opencv_4_4_0/opencv/build"; % note: use msvc complier library,generated mex file can print error,which can be debug!
                    libPath = fullfile(OPENCV_DIR,"x64/vc15/lib");
                    linkFiles = "opencv_world440.lib";
                end
                includeFilePath1 = fullfile(OPENCV_DIR,"include");
                includeFilePath2 = fullfile(OPENCV_DIR,"include/opencv2");
                buildInfo.addIncludePaths([includeFilePath1,includeFilePath2]);

                % Link OpenCV files
                linkPath = libPath;
                linkPriority = "";
                linkPrecompiled = true;
                linkLinkOnly = true;
                group = '';
                buildInfo.addLinkObjects(linkFiles, linkPath, ...
                    linkPriority, linkPrecompiled, linkLinkOnly, group);

                % DBOW3 include files
                DBOW3_DIR = fullfile(pwd,"../DBOW3");
                includeFilePath1 = fullfile(DBOW3_DIR,"src");% 第三方库函数
                includeFilePath2 = fullfile(DBOW3_DIR,"c_file");% 自己写的入口函数文件夹
                buildInfo.addIncludePaths([includeFilePath1,includeFilePath2]);
                buildInfo.addSourcePaths([includeFilePath1,includeFilePath2]);

                % DBOW3 source files
                dbowSrc = ["BowVector.cpp","Database.cpp","DescManip.cpp","FeatureVector.cpp",...
                    "QueryResults.cpp","quicklz.c","ScoringObject.cpp","Vocabulary.cpp"];
                buildInfo.addSourceFiles(dbowSrc);


            else
                disp('Platform not supported')
            end

        end

        %API for library function 'imwarp'
        function outImg= imageWarp(inImg, tformA,outputView)%#codegen
            % inImg为[0,255]范围uint8类型或者logical图像数组,单通道或者3通道均支持
            % tformA为rigidtform2d或者affinetform2d或者projtform2d对象
            % outputView为imref2d对象
            arguments
                inImg {mustBeA(inImg,{'uint8','logical'})}% 只能为uint8或者logical类型
                tformA (3,3) double % 类型{"rigidtform2d","affinetform2d","projtform2d"}之一的齐次转换矩阵A
                outputView (1,1) struct = struct('XWorldLimits',double([1,size(inImg,2)]),...
                    'YWorldLimits',double([1,size(inImg,1)]),...
                    'ImageSize',double(size(inImg,[1,2])))
            end


            [imgRows,imgCols,imgChannels] = size(inImg);
            outImg = coder.nullcopy(zeros(outputView.ImageSize(1),outputView.ImageSize(2),imgChannels,"like",inImg));
            % outImg = zeros(outputView.ImageSize(1),outputView.ImageSize(2),imgChannels,"like",inImg);
            if coder.target('MATLAB')
                %                 % running in MATLAB, use built-in addition
                %                 if abs(tformA(3,1))>10*eps||abs(tformA(3,2))>10*eps
                %                     tform = projtform2d(tformA);
                %                 else
                %                     tform = rigidtform2d(tformA);
                %                 end
                %                 outputView = imref2d(outputView.ImageSize,outputView.XWorldLimits,outputView.YWorldLimits);
                %                 outImg = imwarp(inImg,tform,'OutputView',outputView);
                outImg= imwarp_opencv_mex(inImg,tformA,outputView);
            else
                % Add the required include statements to the generated function code
                coder.cinclude('opencvAPI.h');
                % include external C++ functions
                coder.updateBuildInfo('addSourceFiles', "opencvAPI.cpp");

                % 调用OpenCV C++代码包装器
                s_in  = struct('XWorldLimits',outputView.XWorldLimits,...
                    'YWorldLimits',outputView.YWorldLimits,...
                    'ImageSize',outputView.ImageSize);

                coder.cstructname(s_in,'imref2d_','extern','HeaderFile','opencvAPI.h');
                coder.ceval('imwarp2', coder.rref(inImg),int32(imgRows),...
                    int32(imgCols),int32(imgChannels),...
                    coder.ref(tformA),coder.ref(s_in),coder.wref(outImg));
            end
        end

        %API for library function 'imread'
        function grayImg = imread(imagePath)
            arguments
                imagePath (1,1) string
            end

            grayImg = coder.nullcopy(zeros(480,640,"uint8"));
            if coder.target('MATLAB')
                % running in MATLAB, use built-in addition
                grayImg = imread_opencv_mex(imagePath);
            else
                % Add the required include statements to the generated function code
                coder.cinclude('opencvAPI.h');
                % include external C++ functions
                coder.updateBuildInfo('addSourceFiles', "opencvAPI.cpp");

                % 调用OpenCV C++代码包装器
                imgPath = [char(imagePath),0];
                coder.ceval('imreadOpenCV', coder.rref(imgPath),coder.wref(grayImg));
            end
        end

        %API for library function 'loopDatabase_x86_64',use c++ DBOW3 directly
        function result = loopDatabase_x86_64(dbFilePath,addImage,addFeatures,initImagesList,initFeaturesCell,flag)%#codegen
            % 功能：用于在x86_64/arm平台上生成C++代码直接使用外部库
            % flag: "initImagesList"时候,只使用initImagesList，其余参数一律跳过，其为图像绝对路径列表文件，无返回值；
            % flag: "initFeatures"时候,只使用initFeaturesCell，其余参数一律跳过，其为:infx1的cell array，每个cell中保存Mix32大小的特征，无返回值；
            %
            % flag: "load"时候,只使用dbFilePath字典.yml.gz文件,其余参数一律跳过,无返回值；
            %
            % flag: "addImage"时候,只使用addImage，其余参数一律跳过,其为图像数组，无返回值；
            % flag: "addFeatures"时候,只使用addFeatures,其余参数一律跳过,其为该图像特征数组,无返回值；
            %
            % flag: "query"时候,只使用addImage，其余参数一律跳过,其为图像数组，返回为n*2 double类型数组，第一列为queryID,第二列为score
            %
            % 注意：在实际使用中，flag中"<init_or_add>Image"和"<init_or_add>Features"只使用其中一组对应的匹配，功能一样
            %
            arguments
                dbFilePath (1,1) string %  "../data/preSavedData/database.yml.gz";
                addImage (480,640) uint8 % 为480*640的uint8图像
                addFeatures (:,32) uint8 % M*32的uint8特征
                initImagesList (1,1) string % "../data/preSavedData/imagePathList.txt";
                initFeaturesCell  (1,:) cell % N个M*32的uint8特征的cell array
                flag (1,1) string {mustBeMember(flag,{'initImagesList','initFeatures','load','addImage','addFeatures','queryImage','queryFeatures'})}
            end

            coder.reservedName('cv');% 避免matlab coder生成的C/C++代码中使用cv这个变量，以防止与opencv的作用符cv冲突！！！
            result = coder.nullcopy(zeros(10,2));% top 10
            if coder.target('MATLAB')
                % running in MATLAB, use built-in or custom mex function
                if ~startsWith(flag,"query")
                    loopDatabase_opencv_mex(dbFilePath,addImage,addFeatures,initImagesList,initFeaturesCell,flag);
                else
                    result = loopDatabase_opencv_mex(dbFilePath,addImage,addFeatures,initImagesList,initFeaturesCell,flag);
                end
            else
                % Add the required include statements to the generated function code
                coder.cinclude('loopDatabase_x86_64.h');
                coder.updateBuildInfo('addSourceFiles', "loopDatabase_x86_64.cpp");
                if flag =="initImagesList"
                    filePathChar = [char(initImagesList),0];% https://www.mathworks.com/matlabcentral/answers/1917410-matlab-coder-generating-c-code-for-scalar-string-results-in-a-garbled-last-character
                    saveYMLGZfile = [char(dbFilePath),0];
                    coder.ceval("loopDatabase_x86_64_init_images",coder.rref(filePathChar),coder.rref(saveYMLGZfile)); % database.yml.gz
                elseif flag == "initFeatures"
                    assert(isa(initFeaturesCell,"cell"));
                    saveYMLGZfile = [char(dbFilePath),0];
                    numImages = numel(initFeaturesCell);
                    for num = 1:numImages
                        currImgFeatures = initFeaturesCell{num};
                        [h,w] = size(currImgFeatures);
                        coder.ceval("loopDatabase_x86_64_init_features",coder.rref(currImgFeatures),int32(h),int32(w),false,coder.rref(saveYMLGZfile));
                    end
                    currImgFeatures = initFeaturesCell{1};
                    [h,w] = size(currImgFeatures);
                    coder.ceval("loopDatabase_x86_64_init_features",coder.rref(currImgFeatures),int32(h),int32(w),true,coder.rref(saveYMLGZfile));
                elseif flag =="load"
                    assert(isstring(dbFilePath));
                    assert(numel(dbFilePath)==1);

                    filePathChar = [char(dbFilePath),0];
                    coder.ceval("loopDatabase_x86_64_load",coder.rref(filePathChar));
                elseif flag =="addImage"
                    assert(isa(addImage,"uint8"));
                    [M,N,C] = size(addImage);
                    assert(C==1);

                    coder.ceval("loopDatabase_x86_64_add_image",coder.rref(addImage),int32(M),int32(N));
                elseif flag =="addFeatures"
                    assert(isa(addFeatures,"uint8"));% addFeatures为uint8类型M*N大小特征数组,M为特征数量个数,N为特征维度

                    [M,N,C] = size(addFeatures);
                    assert(C==1);
                    coder.ceval("loopDatabase_x86_64_add_features",coder.rref(addFeatures),int32(M),int32(N));
                elseif flag =="queryImage"
                    assert(isa(addImage,"uint8"));
                    [M,N,C] = size(addImage);
                    assert(C==1);

                    coder.ceval("loopDatabase_x86_64_query_image",coder.rref(addImage),int32(M),int32(N),coder.wref(result));
                elseif flag == "queryFeatures"
                    assert(isa(addFeatures,"uint8"));
                    [M,N,C] = size(addFeatures);
                    assert(C==1);

                    coder.ceval("loopDatabase_x86_64_query_features",coder.rref(addFeatures),int32(M),int32(N),coder.wref(result));
                else
                    error("this flag doesn't support!");
                end
            end
        end

        function  writeImageViewSt(imageViewStArray,filename)%#codegen
            arguments
                imageViewStArray (1,:) struct% 必须含有"Features"和"Points"两个域名的数组,Features为:infx32 uint8，Points为：infx2 double
                filename (1,1) string = "./imageViewSt.yml.gz"
            end

            if coder.target('MATLAB')
                writeImageViewSt_opencv_mex(imageViewStArray,filename);
            else
                coder.cinclude('loopDatabase_x86_64.h');
                coder.updateBuildInfo('addSourceFiles', "loopDatabase_x86_64.cpp");
                coder.updateBuildInfo('addSourceFiles', "opencvAPI.cpp");% 有依赖到opencvAPI.cpp的实现
                nums = numel(imageViewStArray);
                isOver = false;
                saveFileName = [char(filename),0];
                for i = 1:nums
                    singleImageFeatures = imageViewStArray(i).Features;
                    singleImagePointsX = imageViewStArray(i).Points(:,1);
                    singleImagePointsY = imageViewStArray(i).Points(:,2);
                    [rows,cols] = size(singleImageFeatures);
                    % 调用OpenCV C++代码包装器
                    coder.ceval('loopDatabase_writeStep_imst', coder.rref(singleImageFeatures),int32(rows),int32(cols),coder.rref(singleImagePointsX),...
                        coder.rref(singleImagePointsY),isOver,coder.rref(saveFileName));
                    if i ==nums
                        isOver = true;
                        coder.ceval('loopDatabase_writeStep_imst', coder.rref(singleImageFeatures),int32(rows),int32(cols),coder.rref(singleImagePointsX),...
                            coder.rref(singleImagePointsY),isOver,coder.rref(saveFileName));
                    end
                end
            end
        end

        function numEles = readImageViewStMetaNum(filename)
            arguments
                filename (1,:) char = "./imageViewSt.yml.gz"
            end
            numEles = int32(0);
            coder.cinclude('loopDatabase_x86_64.h');
            coder.updateBuildInfo('addSourceFiles', "loopDatabase_x86_64.cpp");
            coder.updateBuildInfo('addSourceFiles',"opencvAPI.cpp");

            % 调用OpenCV C++代码包装器
            c_filename = [char(filename),0];
            coder.ceval('loopDatabase_read_imst_numEles', coder.rref(c_filename),coder.wref(numEles));
        end

        function  [rows,cols] = readImageViewStMeta(idx)%#codegen
            % 本函数必须要与readImageViewSt函数一起连续使用！
            arguments
                idx (1,1) int32
            end
            rows = int32(0);
            cols = int32(0);

            coder.cinclude('loopDatabase_x86_64.h');
            coder.updateBuildInfo('addSourceFiles', "loopDatabase_x86_64.cpp");
            coder.updateBuildInfo('addSourceFiles',"opencvAPI.cpp");

            % 调用OpenCV C++代码包装器
            coder.ceval('loopDatabase_readStep_imst_meta', idx,coder.wref(rows),coder.wref(cols));
        end

        function  [singleImageFeatures,keyPoints] = readImageViewSt(idx,rows,cols)%#codegen
            % 本函数必须要与readImageViewStMeta函数一起连续使用！
            arguments
                idx (1,1) int32
                rows (1,1)
                cols (1,1)
            end

            singleImageFeatures = zeros(rows,cols,"uint8");
            keyPoints = zeros(rows,2,"double");
            
            coder.cinclude('loopDatabase_x86_64.h');
            coder.updateBuildInfo('addSourceFiles',"opencvAPI.cpp");
            coder.updateBuildInfo('addSourceFiles', "loopDatabase_x86_64.cpp");
            

            % 调用OpenCV C++代码包装器
            coder.ceval('loopDatabase_readStep_imst', idx,coder.wref(singleImageFeatures),coder.wref(keyPoints));
        end

        function blendImg = alphaBlend(downImg,topImg,maskimage,int32_x,int32_y)%#codegen
            % brief: replace matlab-build-in function alphaBlend
            arguments
                downImg uint8
                topImg uint8
                maskimage logical
                int32_x (1,1) int32
                int32_y (1,1) int32
            end

            [h1,w1,c1] = size(downImg);
            [h2,w2,c2] = size(topImg);
            [h3,w3,c3] = size(maskimage);
            % assert(isequal(c1,c2,c3,1),"input image must one dims");
            assert(isequal(h2,h3));
            assert(isequal(w2,w3));

            assert(isa(downImg,"uint8"));
            assert(isa(topImg,"uint8"));
            assert(isa(maskimage,"logical"));
            assert(isa(int32_x,"int32"));
            assert(isa(int32_y,"int32"));
            maskimage = logical(maskimage);

            blendImg = coder.nullcopy(zeros(size(downImg),"uint8"));
            if coder.target('MATLAB')
                % running in MATLAB
                blendImg = alphablend_opencv_mex(downImg,topImg,maskimage,int32_x,int32_y);
            else
                % Add the required include statements to the generated function code
                coder.cinclude('opencvAPI.h');
                % include external C++ functions
                coder.updateBuildInfo('addSourceFiles', "opencvAPI.cpp");

                % 调用OpenCV C++代码包装器
                coder.ceval('alphaBlendOpenCV', coder.rref(downImg),int32(h1),int32(w1),int32(c1),coder.rref(topImg),...
                    coder.rref(maskimage),int32(h2),int32(w2),int32(c2),int32_x,int32_y,coder.wref(blendImg));
            end
        end
    end
end