目录说明:

1、 配置文件目录conf/
    
    |nacd/           : nacd配置
    |    east.conf   : 东部-nacd, 包含host/port/codec
    |    head.conf   : 总部-nacd, 
    |    nc.conf     : 华北-nacd,   north china
    |    ne.conf     : 东北部-nacd, north east
    |    nw.conf     : 西北部-nacd, north west
    |    sc.conf     : 中南-nacd,   south center
    |    west.conf   : 西部-nacd,   西部
    |
    |zpos.conf       : 应用主配置
    |zeta.conf       : zeta配置
    |8583.conf       : 8583配置文件
    |nacd.conf       : 加载nacd目录下的配置

2、 bin目录

    tsimu  : zero模拟器
    tpos   : pos模拟器
    tperf  : 性能测试工具

3、 libexec目录

    plugin.pl  :  加载插件+应用配置
    main.pl    :  主控函数
    worker.pl  :  工作进程函数
    simu.pl    :  按需启动银行模拟器(配置zeta模块时,指定需要运行模拟器的银行列表作为参数para)
    magent.pl  :  监控节点进程
    msvr.pl    :  监控服务器进程

4、 etc目录

    profile.mak  : 开发测试环境变量
    
5、 log目录
    
    Zsimu.log          : zero模拟器日志
    Znacd.east.log     : 
    Znacd.head.log     :
    Znacd.nc.log       :
    Znacd.ne.log       :
    Znacd.nw.log       :
    Znacd.sc.log       :
    Znacd.west.log     :
    Ztran.N.log        : 第N个工作进程的某个渠道日志
    Zmagent.log        : 监控节点进程日志
    Zstomp.log         : 测试用-可靠消息队列

6、 t目录

