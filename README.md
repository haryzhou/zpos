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
    |8583.conf       : POS8583配置文件
    |nacd.conf       : 加载nacd目录下的配置

2、 bin目录

    tpos   : pos模拟器
    tperf  : 性能测试工具

3、 libexec目录

    plugin.pl  :  加载插件+应用配置
    main.pl    :  主控函数
    tran.pl    :  交易处理进程
    simu.pl    :  zero交易系统模拟器
    magent.pl  :  监控节点进程

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

