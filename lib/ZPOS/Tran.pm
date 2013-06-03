package ZPOS::Tran;
use strict;
use warnings;
use POE;
use POE::Filter::Block;
use IO::Socket::INET;
use Zeta::Codec::Frame qw/ascii_n binary_n/;

#
# 管理交易-交易代码
#
my %tmap = (
    '800.001.002'  => 'si',    # 签到
    '800.001.002'  => 'so',    # 签退
);

#
# 交易处理进程
# ZPOS::Tran->new();
#
sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

#
# 创建交易处理进程
# $self->spawn($zcfg, $logger, $nacd)
#
sub spawn {

    my ($self, $zcfg, $logger, $nacd) = @_;
    $self->{zcfg}   = $zcfg;
    $self->{logger} = $logger;
    $self->{nacd}   = $nacd;

    # 建立tran
    return POE::Session->create(
        object_states => [
            $self => {
                on_nacd => 'on_nacd',   # 收到渠道请求
                on_zero => 'on_zero',   # 收到交易应答
            },
        ],
        inline_states => {
            _start => sub {
               $_[KERNEL]->alias_set('tran');
               $_[HEAP]{nacd} = $nacd;
            },
        }
    );
}

#
# 收到nacd数据: [4 bytes len] + $src . $tpdu + $8583
#
sub on_nacd {
    my ($self, $packet) = @_[OBJECT, ARG0];
    $packet =~ /^(\w+)\.(.{5})//;

    # mac校验
    
    # 解包
    my $preq  = $self->{zcfg}{pack}->unpack($packet);
    
    # 交易代码: zpos只处理管理交易
    my $tcode = $tmap{'000000'};

    # 签到， 
    if ($tcode =~ /si/) {
        $self->sign_in($1, $2, $preq);
    }
    # 签退处理
    else ($tcode =~ /so/) {
        $self->sign_out($1, $2, $preq);
    }
    # 调用交易系统
    else {
        $self->zero($1, $2, $preq);
    }
}


#
# 收到zero交易系统应答
#
sub on_sero {
    my ($self, $zpacket, $id) = @_[OBJECT, ARG0, ARG1];
    my $zero = delete $_[HEAP]{$id};
 
    # 解包zero报文 
    my $zres = $self->{zcfg}{zpack}->unpack($zpacket);

    # 组pos res :  tpdu + $packet
    my $pres;

    # 发送到nacd
    my $ppacket;
    $_[HEAP]{nacd}{$zero->{nacd}}->put($ppacket);
}

#
# pos签到:  密码钥下发, 终端程序更新(tms)
#
sub sign_in {
    my ($self, $src, $tpdu, $preq) = @_; 
}

#
# pos签退
#
sub sigin_out {
    my ($self, $src, $tpdu, $preq) = @_; 
}


#
# 调用交易系统zero
#
sub zero {
    my ($self, $src, $tpdu, $preq) = @_; 

    # 连接zero 
    my $zsock = IO::Socket::INET->new(
        PeearAddr  => $self->{zcfg}{zero}{host},
        PeearPort  => $self->{zcfg}{zero}{port},
    );
    my $zw = POE::Wheel::ReadWrite->new(
         Handle     => $zsock,
         InputEvent => 'on_zero',
         Filter     => POE::Filter::Block->new( LengthCodec => ascii_n(4),
    );
    $_[HEAP]{zero}{$zw->ID} = {
        wheel => $zw,    # zero传送带
        nacd  => $src,   # 来自那个nacd
        tpdu  => $tpdu,  #  
    };

    # 组zero报文
    my $zreq;
 
    # 发送zero报文 
    $zw->put($zreq);
}

1;

__END__

