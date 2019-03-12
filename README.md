# iOS_Flutter_Hybrid_Project

[![](https://badge.juejin.im/entry/5c3afcf26fb9a049f1546e7d/likes.svg?style=flat-square)](https://juejin.im/post/5c3ae5ef518825242165c5ca)
[![Gitter](https://badges.gitter.im/iOS_Flutter_Hybrid_Project/community.svg)](https://gitter.im/iOS_Flutter_Hybrid_Project/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

[从零搭建 iOS Native Flutter 混合工程](https://juejin.im/post/5c3ae5ef518825242165c5ca)
## 使用说明

本仓库为创建 iOS Flutter 混合工程的脚本和例子。

使用本仓库搭建混合工程步骤：

使用git方式管理产物：
1. 使用`flutter create -t module my_flutter`创建 Flutter Module 工程。
2. 复制"Script/git/Flutter"目录内的所有文件到 Flutter 工程根目录.
3. 修改复制的 build_ios.sh 里参数"PRODUCT_GIT_DIR"，使其指向用来保存产物的git仓库的路径，**是路径** 不是git地址。
4. 复制"Script/git/Native"中除了Podfile外的文件到 Native 根目录。
5. 复制"Script/git/Native/Podfile"文件内 "end" 后面的配置内容到自己 Native 工程的 Podfile。并根据自己的工程修改配置。
6. 在Flutter工程目录下使用 build_ios.sh -m release/debug 进行打包，会自动将产物复制到git仓库目录，并执行git push。
7. 在Native工程执行 pod install，会自动从git拉取产物并安装。

使用Maven方式管理产物：
1. 使用`flutter create -t module my_flutter`创建 Flutter Module 工程。
2. 复制"Script/Maven/Flutter"目录内的所有文件到 Flutter Module 工程根目录.
3. 修改 Maven.sh，将Maven服务器地址、用户名、项目地址改成自己的。
4. 复制"Script/Maven/Native"中出Podfile外的文件到 Native 根目录。
5. 复制"Script/Maven/Native/Podfile"文件内 "end" 后面的配置内容到自己 Native 工程的 Podfile。并根据自己的工程修改配置。
6. 修改 Native 工程目录里的 Maven.sh，将Maven服务器地址、用户名、项目地址改成自己的。
7. 在Flutter工程下使用build_ios.sh -m release/debug 进行打包，会自动将产物上传到maven。
8. 在Native工程执行 pod install，会自动从maven下载Flutter产物并安装。
