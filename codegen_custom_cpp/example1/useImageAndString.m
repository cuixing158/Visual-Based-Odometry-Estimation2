function out = useImageAndString(imagePathList,image1)%#codegen
% Brief: 用于测试在生成的C++代码中直接使用自定义的C++函数文件，主要查看输入输出参数如何定义传值.
% Details:
%    假设对imagePathList文件每行进行读入，最终转换为std::vector<string>保存每一行文件路径，image用于对图像像素+2操作
% 
% Syntax:  
%     out = useImageAndString_mex(imagePathList,image1)
% 
% Inputs:
%    imagePathList - [1,1] size,[string]
%    type,文本文件相对路径，文本中每行存储一副图像绝对路径，但该文本文件必须使用相对路径！
%    image1 - [100,200] size,[uint8] type,单通道灰度图像
% 
% Outputs:
%    out - [100,200] size,[uint8] type,单通道灰度图像
% 
% 结论：2023.2.17 验证通过，达到预期
%
% reference:
%  [1] coder.ceval
%  [2] coder.opaque
%  [3] https://www.mathworks.com/help/coder/ug/call-cc-code-from-matlab-code.html
%  [4] https://www.mathworks.com/matlabcentral/answers/1914150-bug-use-of-integrated-external-c-c-code-in-matlab-coder-does-not-work-for-coder-varsize
%  [5] https://www.mathworks.com/matlabcentral/answers/1917410-matlab-coder-generating-c-code-for-scalar-string-results-in-a-garbled-last-character
%  [6] https://blog.csdn.net/sunnzhongg/article/details/53264175
% 
% codegen command:
% s = "input.txt";
% t = coder.typeof(s);
% t.StringLength = 255;
% t.VariableStringLength = true;
% codegen -config:mex useImageAndString -args {t,ones(100,200,"uint8")} -launchreport -lang:c++
%
% Example:
% image = uint8(randi(255,100,200));
% out = useImageAndString_mex("./imageList.txt",image);
%
% See also: None

% Author:                          cuixingxing
% Email:                           cuixingxing150@gmail.com
% Created:                         17-Feb-2023 14:52:20
% Version history revision notes:
%                                  None
% Implementation In Matlab R2022b
% Copyright © 2023 TheMatrix.All Rights Reserved.
%


arguments
    imagePathList (1,1) string = "./input.txt" 
    image1 (100,200) uint8 = zeros(100,200,'uint8')
end

% https://www.mathworks.com/help/coder/ug/define-input-properties-programmatically-in-the-matlab-file.html
assert(isstring(imagePathList));
assert(numel(imagePathList)==1);

assert(isa(image1,"uint8"));
assert(all(size(image1)==[100,200]));

if coder.target("MATLAB")
    myname = imagePathList+"111";
    len = numel(myname)+2;

    out = image1+len;
else
   

    out = zeros(size(image1),"uint8");

    % include external C++ functions 
    coder.cinclude('test1.h');
    coder.updateBuildInfo('addSourceFiles', 'test1.cpp');

     % call C++ function 1
    returnVal = coder.opaque('std::vector<string>');
    imgPath = [char(imagePathList),0];% https://www.mathworks.com/matlabcentral/answers/1917410-matlab-coder-generating-c-code-for-scalar-string-results-in-a-garbled-last-character
    returnVal = coder.ceval('getImageNames',coder.rref(imgPath));

    % call C++ function 2
    coder.ceval('getImage', ...
        coder.rref(image1),coder.wref(out));
end
end