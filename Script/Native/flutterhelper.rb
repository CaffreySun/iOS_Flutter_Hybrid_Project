##############################################################################
#
# 脚本使用方式：
# 你需要在 Podfile 添加以下=begin =end 之间的内容：
=begin 

# 设置要引入的 flutter app 的版本
FLUTTER_APP_VERSION="4.01.01"

# 是否进行调试 flutter app，
# 为true时FLUTTER_APP_VERSION配置失效，下面的配置生效
# 为false时FLUTTER_APP_VERSION配置生效，下面的配置失效
FLUTTER_DEBUG_APP=false

# Flutter App git地址，从git拉取的内容放在当前工程目录下的.flutter/app目录
# 如果指定了FLUTTER_APP_PATH，则此配置失效
FLUTTER_APP_URL="gut://xxx.git"
# flutter git 分支，默认为master
# 如果指定了FLUTTER_APP_PATH，则此配置失效
FLUTTER_APP_BRANCH="master"

# flutter本地工程目录，绝对路径或者相对路径，如果 != nil 则git相关的配置无效
FLUTTER_APP_PATH=nil

=end
# 
##############################################################################

# 拉取代码方法
def update_flutter_app(path, url, branche)
    # 如果flutter项目不存在，则clone
    if !File.exist?(path)
        `git clone #{url} #{path}`
    end
    `cd #{path} && git fetch --all -v && \
    git reset --hard origin/master && \
    git pull && \
    git checkout -B #{branche} origin/#{branche}`
end

# 安装开发环境app
def install_debug_flutter_app

    puts "如果是第一次运行开发环境Flutter项目，此过程可能会较慢"
    puts "请耐心等️待☕️️️️️☕️☕️\n"
    
    # 默认Flutter App 目录
    flutter_application_path = __dir__ + "/.flutter/app"
    flutter_application_url = ""
    flutter_application_branch = 'master'
    
    if FLUTTER_APP_PATH != nil
        File.expand_path(FLUTTER_APP_PATH)
        if File.exist?(FLUTTER_APP_PATH) 
            flutter_application_path = FLUTTER_APP_PATH
        else
            flutter_application_path = File.expand_path(FLUTTER_APP_PATH)
            if !File.exist?(flutter_application_path) 
                raise "Error: #{FLUTTER_APP_PATH} 地址不存在!"
            end
        end
        
        puts "\nFlutter App路径: "+flutter_application_path
    else
        if FLUTTER_APP_URL != nil
            flutter_application_url = FLUTTER_APP_URL
            if FLUTTER_APP_BRANCH != nil
                flutter_application_branch = FLUTTER_APP_BRANCH
            end
        else
            raise "Error: 请在'Podfile'里增加Flutter App git地址配置，配置格式请查看'flutterhelper.rb'文件"
        end
        puts "\n拉取 Flutter App 代码"
        puts "Flutter App路径: "+flutter_application_path
        update_flutter_app(flutter_application_path, flutter_application_url, flutter_application_branch)
    end

    puts "\n编译 Flutter App"
    `export PUB_HOSTED_URL=https://pub.flutter-io.cn && \
    export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn && \
    cd #{flutter_application_path} && \
    #{flutter_application_path}/build_ios.sh -m debug`

    if $?.to_i == 0
        flutter_package_path = "#{flutter_application_path}/.build_ios/debug/product"
        # 开始安装
        install_release_flutter_app_pod(flutter_package_path)
    else
        raise "Error: 编译 Flutter App失败"
    end
end

# 解压flutter app file
def unzip_release_flutter_fill(zip_file, package_unzip, package_path)
    if package_path.nil? || package_path.nil? || package_path.nil?
        return false
    end

    puts "开始解压 flutter app #{zip_file}"

    # 删除标志物
    FileUtils.rm_rf(package_unzip)
    # 解压
    `unzip #{zip_file} -d #{package_path}`
    if $?.to_i == 0
        # 解压成功，创建标志物
        FileUtils.touch(package_unzip)
        
        return true
    else
        return false
    end
end

# 解压flutter app
def unzip_release_flutter_app(package_path, zip_file)
    # 产物包已解压标志
    flutter_package_unzip = File.join(package_path, "unzip.ok")
    # 产物包解压后的目录
    flutter_package_path = File.join(package_path, "product")
    
    if File.exist? flutter_package_unzip
        if File.exist? flutter_package_path
            return flutter_package_path
        else
            unziped = unzip_release_flutter_fill(zip_file, flutter_package_unzip, package_path)
            if unziped == true
                return flutter_package_path
            else
                raise "Error: Flutter app 解压失败 #{zip_file}"
            end
        end
    else
        FileUtils.rm_rf(flutter_package_path)
        unziped = unzip_release_flutter_fill(zip_file, flutter_package_unzip, package_path)
        if unziped == true
            return flutter_package_path
        else
            raise "Error: Flutter app 解压失败 #{zip_file}"
        end
    end
end

# 下载 release 产物
def download_release_flutter_app(app_version, download_path, downloaded_file) 

    if app_version.nil? || download_path.nil?
        raise "Error: 请在 Podfile 里设置要安装的 Flutter app 版本 ，例如：FLUTTER_APP_VERSION='1.0.0'"
    end

    if download_path.nil?
        raise "Error: 无效的下载路径"
    end

    if downloaded_file.nil?
        raise "Error: 无效的下载产物路径"
    end

    puts "开始下载 #{app_version} 版本 flutter app"
    `./maven.sh download #{app_version}`

    if $?.to_i == 0
        # 移动产物
        FileUtils.mv('flutter.zip', download_path)
        # 下载成功，创建标志物
        FileUtils.touch(downloaded_file)
    else
        raise "Error: 下载失败  #{app_version} 版本 flutter app"
    end
end

# 将 Flutter app 通过 pod 安装
def install_release_flutter_app_pod(product_path)
    if product_path.nil?
        raise "Error: 无效的 flutter app 目录"
    end

    puts "将 flutter app 通过 pod 导入到 工程"

    Dir.foreach product_path do |sub|
        if sub.eql?('.') || sub.eql?('..') 
            next
        end

        sub_abs_path = File.join(product_path, sub)
        pod sub, :path=>sub_abs_path
    end

    post_install do |installer|
        installer.pods_project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['ENABLE_BITCODE'] = 'NO'
            end
        end
    end
end 


# 安装正式环境环境app
def install_release_flutter_app
    if FLUTTER_APP_VERSION.nil?
        raise "Error: 请在 Podfile 里设置要安装的 Flutter app 版本 ，例如：FLUTTER_APP_VERSION='1.0.0'"
    else
        puts "当前安装的 flutter app 版本为 #{FLUTTER_APP_VERSION}"
    end

    # 存放产物的目录
    flutter_release_path = File.expand_path('.flutter_release')
    has_version_file = true
    if !File.exist? flutter_release_path
        FileUtils.mkdir_p(flutter_release_path)
        has_version_file = false
    end

    # 存放当前版本产物的目录
    flutter_release_version_path = File.join(flutter_release_path, FLUTTER_APP_VERSION)
    if !File.exist? flutter_release_version_path
        FileUtils.mkdir_p(flutter_release_version_path)
        has_version_file = false
    end

    # 产物包
    flutter_package = "flutter.zip"
    flutter_release_zip_file =  File.join(flutter_release_version_path, flutter_package)
    if !File.exist? flutter_release_zip_file
        has_version_file = false
    end

    # 产物包下载完成标志
    flutter_package_downloaded = File.join(flutter_release_version_path, "download.ok")
    if !File.exist? flutter_package_downloaded
        has_version_file = false
    end

    if has_version_file == true
        # 解压
        flutter_package_path = unzip_release_flutter_app(flutter_release_version_path, flutter_release_zip_file)
        # 开始安装
        install_release_flutter_app_pod(flutter_package_path)
    else
        # 删除老文件
        FileUtils.rm_rf(flutter_release_zip_file)
        # 删除标志物
        FileUtils.rm_rf(flutter_package_downloaded)

        # 下载
        download_release_flutter_app(FLUTTER_APP_VERSION, flutter_release_zip_file, flutter_package_downloaded)
        # 解压
        flutter_package_path = unzip_release_flutter_app(flutter_release_version_path, flutter_release_zip_file)
        # 开始安装
        install_release_flutter_app_pod(flutter_package_path)
    end
end

if FLUTTER_DEBUG_APP.nil? || FLUTTER_DEBUG_APP == false
    # 使用 flutter release 模式
    puts "开始安装 release mode flutter app"
    install_release_flutter_app()
else
    # 存在debug配置，使用 flutter debug 模式
    puts "开始安装 debug mode flutter app"
    install_debug_flutter_app()
end
