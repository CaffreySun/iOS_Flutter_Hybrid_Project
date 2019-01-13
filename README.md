# iOS_Flutter_Hybrid_Project

[从零搭建 iOS Native Flutter 混合工程](https://juejin.im/post/5c3ae5ef518825242165c5ca)[![](https://badge.juejin.im/entry/5c3afcf26fb9a049f1546e7d/likes.svg?style=flat-square)](https://juejin.im/post/5c3ae5ef518825242165c5ca)

## 使用说明

本仓库为创建 iOS Flutter 混合工程的脚本和例子。

使用本仓库搭建混合工程步骤：
1. 使用`flutter create -t module my_flutter`创建 Flutter Module 工程。
2. 复制"Script/Flutter"目录内的所有文件到 Flutter Module 工程根目录.
3. 修改 Maven.sh，将Maven服务器地址、用户名、项目地址改成自己的。如果不使用Maven管理产物，则修改 build_ios.sh 里 maven_upload 函数部分为自己管理产物的代码。
4. 复制"Script/Native"中出Podfile外的文件到 Native 根目录。
5. 复制"Script/Native/Podfile"文件内 "end" 后面的配置内容到自己 Native 工程的 Podfile。并根据自己的工程修改配置。
6. 修改 Native 工程目录里的 Maven.sh，将Maven服务器地址、用户名、项目地址改成自己的。如果不使用Maven管理产物，则修改 flutterhelper.rb 里 download_release_flutter_app 函数部分为自己管理产物的代码。
7. pod install

## 例子说明

如果例子工程里的 Flutter 工程不能正确打包，并且错误提示和 .gitignore 有关，则复制"Example"目录到非git管理的目录再次运行。