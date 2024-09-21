% function mainCodeGen
% Brief: 使用codegen命令式生成C代码，可定制性较高,在生成之前最好生成mex函数进行验证!!!
%  codegen -config:mex constructWorldMap -args {imagePoseIn,birdsEye360} -report
%
% reference:
% matlab topic
% [1] Specify Configuration Parameters in Command-Line Workflow Interactively
% [2] Generate Custom File and Function Banners for C/C++ Code
% [3] Use C Arrays in the Generated Function Interfaces
% [4] Use Dynamically Allocated C++ Arrays in Generated Function Interfaces
% [5] Develop Interface for External C/C++ Code
% [6] Generate Code That Uses Row-Major Array Layout
% [7] External Code Integration
% [8] Integrate External/Custom Code
% [9] https://www.mathworks.com/help/coder/ug/define-string-scalar-inputs.html
% [10] Define Input Properties Programmatically in the MATLAB File
% [11] [Reuse Large Arrays and Structures](https://www.mathworks.com/help/coder/ug/reuse-large-user-defined-local-variables.html)
% [12] [Use Dynamically Allocated C++ Arrays in Generated Function Interfaces](https://www.mathworks.com/help/coder/ug/use-dynamically-allocated-cpps-arrays-in-generated-function-interfaces.html)
% [13] Build Process Customization
% [14] [Software-in-the-Loop Execution From Command Line](https://www.mathworks.com/help/ecoder/ug/software-in-the-loop-sil-execution-from-the-command-line.html)
% [15] [Unit Test Generated Code with MATLAB Coder](https://www.mathworks.com/help/coder/ug/unit-test-generated-code-with-matlab-coder.html)
% [16] [Optimization Strategies](https://www.mathworks.com/help/coder/ug/optimize-generated-code.html)
% [17] [vscode SIL debug](https://www.mathworks.com/matlabcentral/fileexchange/103555-matlab-coder-interface-for-visual-studio-code-debugging)


genMexfile = false;
% Create configuration object for an embedded target
if genMexfile
    cfg = coder.config('mex');
    cfg.IntegrityChecks = false;% 当生成mex时候，记得关闭integrityCheck，提高执行速度
    cfg.TargetLang = "C++";
    cfg.CppNamespace = "buildMapping";

    % open('cfg') 对话框选择，可直接复制以下命令配置！
    cfg.EnableAutoExtrinsicCalls = false;
    cfg.EnableRuntimeRecursion = false;
    % cfg.FilePartitionMethod = "SingleFile";
    cfg.ResponsivenessChecks = false;
    cfg.GenerateReport = true;
else
    cfg = coder.config('lib','ecoder',true);

    % Specify the custom CGT file
    CGTFile = './codegen_custom_cpp/matlabcoder_long_horn_template.cgt';
    % Use custom template
    cfg.CodeTemplate = coder.MATLABCodeTemplate(CGTFile);
    cfg.CodeTemplate.setTokenValue('myDescription','for path build map algorithms(loop+pose)');
    cfg.CodeTemplate.setTokenValue('myAlgorithmVersion','V0.2.0');
    cfg.GenerateComments = false;
    cfg.HardwareImplementation.ProdHWDeviceType = "Texas Instruments->C6000";
    cfg.Toolchain  = "CMake";% since R2023a，Generate generic CMakeLists.txt file

    % open('cfg') 对话框选择，可直接复制以下命令配置！
    % step1, custom c++ entry-point class
    cfg.TargetLang = "C++";
    cfg.CppNamespace = "buildMapping";
    cfg.CppInterfaceStyle = "Methods";
    cfg.CppInterfaceClassName = "HDMapping";% 类名

    % step2, executation speed
    cfg.PreserveVariableNames = "None"; % resue large arrays and structures
    %cfg.SupportNonFinite = false; %Disable Support for Nonfinite Numbers
    cfg.SaturateOnIntegerOverflow=false; % Disable Support for Integer Overflow
    cfg.EnableOpenMP = true; % gcc4.x start support

    % step3, fewer file and not complie
    cfg.FilePartitionMethod = "SingleFile";
    cfg.GenCodeOnly = true;

    % step4,sil/pil,performance c++ code report,unit test(coder.runTest),后续建议直接在C/C++环境下测试性能,gpertool,gtest,valgrind工具等
%     cfg.VerificationMode="PIL";
%     cfg.CodeExecutionProfiling = false;
%     cfg.CodeProfilingInstrumentation = false;
%     cfg.CodeStackProfiling = false;
%  cfg.BuildConfiguration = "Debug";
%  cfg.SILDebugging = 1; 
end

% 自定义入口函数参数类型、大小，然后生成C代码
in1 = coder.typeof(inputArgs,[1,1],[0,0]); % test_cpp_entry.m 获得

inputOutputStruct.HDmap.bigImg = coder.typeof(uint8(0),[inf,inf]);
inputOutputStruct.vehiclePoses = coder.typeof(zeros(1,3,"double"),[inf,3]);
in2 = coder.typeof(inputOutputStruct,[1,1],[0,0]);

inputsArgs = {'-config','cfg',...
    'constructWorldMap','-args',{in1,in2},...
    '-lang:c++',...
    '-launchreport'};    % '-package','src.zip',...
codegen(inputsArgs{:});
% end