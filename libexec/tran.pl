#!/usr/bin/perl
use strict;
use warnings;
use Zeta::Run;
use DBI;
use Carp;
use POE;
use ZPOS::Tran;

use constant{
    DEBUG => $ENV{ZPOS_DEBUG} || 0,
};

BEGIN {
    require Data::Dump if DEBUG;
}

sub {
    # 子进程重新设置
    zkernel->zsetup();

    # 获取配置与日志
    my $zcfg = zkernel->zconfig();
    my $logger = zlogger;
    my %nacd;
    for $name (keys %{$zcfg->{nacd}}) {
        $nacd{$name} = zkernel->channel_writer($name);
    }

    # 启动交易处理进程(POE)
    $zcfg->{tran}->spawn(\%nacd);

    # 运行
    $poe_kernel->run();
    exit 0;
};

__END__

