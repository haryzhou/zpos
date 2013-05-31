#!/usr/bin/perl
use strict;
use warnings;
use Zeta::Run;
use DBI;
use Carp;
use POE;

use constant{
    DEBUG => $ENV{ZPOS_DEBUG} || 0,
};

BEGIN {
    require Data::Dump if DEBUG;
}

#
# $name  :  nacd所服务的地区名称
#
sub {

    my @name = @_;   # 需要被模拟的nac

    # 获取配置与日志
    my $zcfg = zkernel->zconfig();
    my $logger = zlogger;

    # 启动 - nacd
    for (@name) {
        POE::Session->create(
            inline_states  => {
                _start => sub {
                     $zcfg->{nacd}{$name}->spawn($zcfg, $logger);
                },
            },
        );
    }

    # 运行
    $poe_kernel->run();

    exit 0;
};

__END__
nac模拟器  :  异步转同步













