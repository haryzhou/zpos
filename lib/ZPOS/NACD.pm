package ZPOS::NACD;
use strict;
use warnings;
use POE::Session;
use Time::HiRes qw/gettimeofday tv_interval/;
use POE::Filter::Block;
use Zeta::Codec::Frame qw/binary_n/;

my %tmap = (
    '0200.00.22'      => 'co',
    '0400.00.22'      => 'cor',
    '0200.20.23'      => 'cod',
    '0400.20.23'      => 'codr',
    #'0110.03.10'      => 'pa',
    #'0410.03.10'      => 'par',
    #'0110.20.11'      => 'pad',
    #'0410.20.11'      => 'padr', # 0410.20.11
    #'0210.00.20'      => 'pac',
    #'0410.00.20'      => 'pacr',
    #'0210.20.21'      => 'pacd',
    #'0410.20.21'      => 'pacdr',
    '0810.00'         => 'si',
);

#
# name => 'head',
# host => 'xxx',
# port => '',
#
sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    return $self;
}

#
# $self->spawn($zcfg, $logger)
#
sub spawn {

    my ($self, $zcfg, $logger) = @_;

    $self->{logger} = $logger;
    $self->{zcfg}   = $zcfg;

    POE::Session->create(
        object_states => [
            $self => { 
                on_nac_packet    => 'on_nac_packet',    # 收到NAC报文
                on_nac_response  => 'on_nac_response',  # 响应NAC
                on_accept        => 'on_accept',        # NAC连接
                on_la_error      => 'on_la_error',      # accept错误
                on_nac_flush     => 'on_nac_flush',     # flush event
                on_nac_error     => 'on_nac_error',     # NAC关闭连接

                on_tran_packet   => 'on_tran_packet',
                on_tran_error    => 'on_tran_error',
            },
        ],

        inline_states => {
            _start => sub {
                $self->{logger}->debug("[$self->{name}] started");
                $_[KERNEL]->alias_set($self->{name});    
                my $lsock = IO::Socket::INET->new(
                    LocalAddr  => $self->{host},
                    LocalPort  => $self->{port},
                    ReuseAddr  => 1,
                    Proto      => 'tcp',
                );
                $_[HEAP]{la} = POE::Wheel::ListenAccept->new(
                    Handle      => $lsock,
                    AcceptEvent => 'on_accept',     # 连接
                    ErrorEvent  => 'on_la_error',   # accept失败
                );

                # 从tran模块通道中读
                $_[HEAP]{reader} = POE::Wheel::ReadWrite->new(
                    Handle      => \*STDOUT,
                    InputEvent  => 'on_tran_packet', 
                    ErrorEvent  => 'on_tran_error',
                );
            },
        },
    );
}

#
# 收到交易模块数据
#
sub on_tran_packet {
}

#
#
#
sub on_tran_error {
}

#
# 接收到NAC请求
#
sub on_accept {
    my $self  = $_[OBJECT];
    my $csock = $_[ARG0];
    my $cw = POE::Wheel::ReadWrite->new(
        Handle       => $csock,
        InputEvent   => 'on_nac_packet', 
        ErrorEvent   => 'on_nac_error',
        FlushedEvent => 'on_nac_flush',
        Filter       => POE::Filter::Block->new( LengthCodec => &binary_n(2)),
    );
    $_[HEAP]{nac} = $cw;
    return 1;
}

#
# accept错误
#
sub on_la_error {
    my $self = $_[OBJECT];
    $self->{logger}->error("[$self->{name}] accept error");
}

#
# 从NAC收到报文
#
sub on_nac_packet {

    my $self   = $_[OBJECT];
    my $packet = $_[ARG0];
    my $cid    = $_[ARG1];

    $self->{logger}->debug_hex("收到NAC数据<<<<<<<<:", $packet);

    # NAC请求报文 - 解包
    my $creq = $self->unpack($packet);

    # 设置内部交易代码(creq组匹配串)
    my $tstr = $creq->[0].'.'.substr($creq->[3], 0, 2).'.'.substr($creq->[60], 0, 2);

    # 交易记录
    my $tran = {
        nac    => $self->{name},
        cid     => $cid,
        creq    => $creq,
        c_tcode => $tmap{$tstr},
        ts_in   => [gettimeofday],
    };
    $_[HEAP]{nac}{$cid}{tran} = $tran;
    $self->{logger}->debug("self is :".Data::Dump->dump($self));
    # 发送交易监控消息到监控队列, 如果有监控队列的话
    if ($self->{zcfg}{monq}) {
        my $msg = join '|', ('zpos', $ENV{ZPOS_ID}, 1, $tran->{nac}, $tran->{c_tcode}, $tran->{creq}[4], $tran->{creq}[11], $tran->{creq}[41], $tran->{creq}[42], @{$tran->{ts_in}});
        # $self->{logger}->debug("发送交易监控消息到监控队列[$msg]");
        $self->{zcfg}{monq}->send($msg, $$);
    }

    # 发送到tran模块
    $_[KERNEL]->post('tran', 'on_nac', $tran);
}

#
# NAC端错误, ()
#
sub on_nac_error {
    my $self = $_[OBJECT];
    my $id   = $_[ARG3];
    
    $self->{logger}->debug("[$self->{name}] on_nac_error called[$id], 释放资源");
    
    # 释放资源
    my @r = keys %{$_[HEAP]{nac}};
    $self->{logger}->debug("[$self->{name}] 释放[$id]资源[前]的堆栈情况[@r]");
    
    my $t = delete $_[HEAP]{nac}{$id};
    
    @r = keys %{$_[HEAP]{nac}};
    $self->{logger}->debug("[$self->{name}] 释放[$id]资源[后]的堆栈情况[@r]");

    # 如果在银行响应后, NAC端断开
    if ($t->{tran}{cres}) {
        # 直接delete掉
    }
    $self->{logger}->debug("[$self->{name}] tran[bank]:".Data::Dump->dump($t->{tran}));

    # 通知相应的银行端释放资源
    if ($t->{tran}{bid}) {
        $self->{logger}->debug("[$self->{name}] on_nac_error called[$id], 通知银行端");
        $_[KERNEL]->post($t->{tran}{bank}, 'on_nac_error', $t->{tran}{bid} );
    }

    return 1;
}


#
# 发送NAC响应完毕
#
sub on_nac_flush {
    my $self = $_[OBJECT];
    my $cid  = $_[ARG0];
  
    my $t = delete $_[HEAP]{nac}{$cid};

    # 应答时间戳
    my $ts_out = [ gettimeofday ];
    $self->{logger}->debug("[$self->{name}] [$t->{tran}{c_tcode}][$t->{tran}{c_tkey}] elapse[" . tv_interval($t->{tran}{ts_in}, $ts_out) . "]");

    # 发送监控消息
    if ($self->{zcfg}{monq}) {
        my $tran = $t->{tran};
        my $msg = join '|', ('zpos', $ENV{ZPOS_ID}, 2, $tran->{nac}, $tran->{c_tcode}, $tran->{cres}[4], $tran->{cres}[11], $tran->{cres}[41], $tran->{cres}[42], @$ts_out);
        $self->{zcfg}{monq}->send($msg, $$); 
    }
}

#
# 从bank收到数据:
# {
#    nac => 'cardsv',
#    bank => 'icbc',
#    cid  => $cid,
#    bid  => $bid,
#    creq => $creq,
#    cres => $cres,
#    breq => $breq,
#    bres => $bres,
# }
# 处理:
#    
#
sub on_nac_response {
    my $self = $_[OBJECT];
    my $tran = $_[ARG0];
    $self->{logger}->debug("[$self->{name}] 发送NAC数据>>>>>>>>:".Data::Dump->dump($tran));
    # 打包NAC应答
    my $packet = $self->pack($tran->{cres});
    
    # 发送
    $self->{logger}->debug_hex("[$self->{name}] 发送NAC数据>>>>>>>>:", $packet);
    unless ($_[HEAP]{nac}{$tran->{cid}}{wheel}) {
        $self->{logger}->warn("");
        return 1;
    }
    
    $_[HEAP]{nac}{$tran->{cid}}{wheel}->put($packet);
}

#
# NAC打包
# NAC解包
#
sub pack   { my ($self, $res) = @_; $self->{pack}->pack($res);   }
sub unpack {
    my ($self, $req) = @_;
    $self->{pack}->unpack($req);
}

1;

__DATA__
##################################################################################
#         易宝pos终端规范 
##################################################################################
# 说明:
# id:    域号
# type:  检验数据是否只包含指定类型的字符
# len:   数据域长度(如果是固定域的话) || 数据域的最大长度(llvar|lllvar)
# class: 变长|固定长 fix|llvar|lllvar
# denc:  数据域的数据编码方式:  bcd: | bcdl: bcd编码左靠
# lenc:  llvar/lllvar数据的长度部分编码方式
##################################################################################
#       0      1      2         3        4         5
# id    type   len    class     lenc     denc      desc      
##################################################################################
  2     n      19     llvar     bcd      bcdl      主账号
  3     n      6      fix       ascii    bcd       交易处理码
  4     n      12     fix       ascii    bcd       交易金额
  11    n      6      fix       ascii    bcd       受卡方系统跟踪号
  12    n      6      fix       ascii    bcd       受卡方所在地时间
  13    n      4      fix       ascii    bcd       受卡方所在地日期
  14    n      4      fix       ascii    bcd       卡有效期
  18    n      8      fix       ascii    bcd       银行代码
  15    n      4      fix       ascii    bcd       清算日期
  22    n      3      fix       ascii    bcdl      服务点输入方式码
  23    n      3      fix       ascii    bcd       卡序列号
  25    n      2      fix       ascii    bcdl      服务点条件码
  26    n      2      fix       ascii    bcd       服务点PIN获取码
  32    n      11     llvar     bcd      bcdl      受理方标识码
  35    z      37     llvar     bcd      bcdl      第二磁道数据
  36    z      104    lllvar    bcd      bcdl      第三磁道数据
  37    an     12     fix       ascii    ascii     检索参考号
  38    an     6      fix       ascii    ascii     授权标识应答码
  39    an     2      fix       ascii    ascii     应答码
  41    ans    8      fix       ascii    ascii     受卡机终端标识码
  42    ans    15     fix       ascii    ascii     受卡方标识码
  44    an     25     llvar     bcd      ascii     附加响应数据
  48    n      322    lllvar    bcd      bcdl      附加数据——私有
  49    an     3      fix       ascii    ascii     交易货币代码
  52    b      8      binary    ascii    ascii     个人标识码数据
  53    n      16     fix       ascii    bcd       安全控制信息
  54    an     20     lllvar    bcd      ascii     附加金额
  55    b      255    lllvar    bcd      ascii     IC卡数据域
  56    ans    100    lllvar    bcd      ascii     自定义域
  58    ans    100    lllvar    bcd      ascii     PBOC电子钱包标准的交易信息
  59    ans    160    lllvar    bcd      ascii     自定义域
  60    n      13     lllvar    bcd      bcdl      自定义域
  61    n      29     lllvar    bcd      bcdl      原始信息域
  62    ans    512    lllvar    bcd      ascii     自定义域
  63    ans    163    lllvar    bcd      ascii     自定义域
  64    b      8      binary    ascii    ascii     报文鉴别码 
##################################################################################
