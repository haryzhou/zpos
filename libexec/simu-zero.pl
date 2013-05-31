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
# 
#
sub {

    # 获取配置与日志
    my $zcfg = zkernel->zconfig();
    my $logger = zlogger;

    ZPOS::Simu::Zero->spawn();

    # 运行
    $poe_kernel->run();

    exit 0;
};

__END__
nac模拟器  :  异步转同步













