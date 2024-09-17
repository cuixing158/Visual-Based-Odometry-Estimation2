# 深度自定义C++代码生成

author: 崔星星
first date: [2023-02-23](date:"ymd").
latest modify:[2023-06-21](date:"ymd").

## Overview

本目录存储用于使用matlab coder工具箱高度自定义生成自己的C++代码，可任意集成第三方C/C++库，不仅可以支持mex文件生成，而且还支持原生的第三方代码（OpneCV或者其他任意C++库），功能强大！

## 本目录结构说明

- `example1/`:独立的示例程序文件夹，用于简单的C++代码调用。

- `example2/`:独立的示例程序文件夹，用于opencv函数式文件的C++代码调用。

- `OpenCV_API.m`:为通用的类文件，自定义程度较高。位于同层次的其他`.m`文件是C++代码的入口函数（可编译为mex或者直接生成C++代码），根据自己情况定义来调用`OpenCV_API.m`类的成员函数即可。

- `matlabcoder_long_horn_template.m`: 自定义模板。

## 如何编译生成mex文件

1. 切换到在当前工作目录下，在`OpenCV_API.m`文件中修改`updateBuildInfo`函数的当前MATLAB环境变量`isDockerContainer`是否是docker容器还是其他系统环境(opencv库安装路径不一样)。

1. 在`OpenCV_API.m`类中实现好自己的接口成员函数，然后为每个函数写一个套壳函数文件(如`imarp_opencv.m`、`loopDatabase_opencv.m`等)，输入输出保持一致，然后按照套壳函数内函数codegen command命令生成对应的mex文件。

## Notes

- 外部调用本目录的函数应当直接调用非mex文件的套壳函数文件(如`imarp_opencv.m`、`loopDatabase_opencv.m`等)，因为有验证参数，相对直接调用mex文件较为安全。

- 套壳函数分别对应主类中的成员函数，成员函数中实现了target为“MATLAB”环境和非“非MATLAB”环境下的C++代码，“MATLAB”环境部分应当始终使用对应编译的mex文件，这样可以保证外部调用套壳函数和生成的C++代码保持高度一致性的结果。

- `OpenCV_API.m`中包含的OpneCV自定义源代码或者第三方C++代码请移步到[此库](https://github.com/cuixing158/DBOW3)的`c_file/`文件夹。

- 如遇到mex文件执行崩溃，绝大多数是用户自定义的C/C++代码内存问题，这时候强烈推荐`valgrind`工具进行内存崩溃位置定位诊断。生成mex文件需要`codegen`命令加上`-g`参数，然后如下在linux下的终端命令：

```bash
matlab -nojvm -nosplash -r "myMexMatlabFunc(yourParams)" -D"valgrind --error-limit=no --tool=memcheck --leak-check=yes --log-file=valMatlabLog"
```

- 使用C/C++自定义函数中谨慎使用static变量，因为MATLAB中使用`clear all`仍然清除不了c/c++中的static持久变量，除非重新打开MATLAB。推荐如果在C/C++中使用static变量前清除以前缓存！！！

## Reference

[How do I pass the correct string for a function input parameter?](https://www.mathworks.com/matlabcentral/answers/1944969-how-do-i-pass-the-correct-string-for-a-function-input-parameter)
