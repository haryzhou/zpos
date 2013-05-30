package ZPOS::HSM;
use strict;
use warnings;
use POE;
# use Zeta::HSM;

#
# 交易处理进程
# ZPOS::HSM->new();
#
sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

#
# 创建交易处理进程
# $self->spawn($zcfg, $logger)
#
sub spawn {

    my ($self, $zcfg, $logger, $index) = @_;

    $self->{logger} = $logger->clone($logname);

    # $self->{check}  = Zero::Tran::Check->new($zcfg, $self->{logger});

    # 建立tran
    return POE::Session->create(
        object_states => [
            $self => {
                on_tranpin => 'on_tranpin',     # 收到渠道请求
                on_gmac  => 'on_gmac',
                on_vmac  => 'on_vmac',
            },
        ],
        inline_states => {
            _start => sub {
               $_[KERNEL]->alias_set('hsm');
            },
        }
    );
}

#
# 收到tranpin请求
#
sub on_tranpin {
    my ($self, $req, $src, $event) = @_[OBJECT, ARG0, ARG1, ARG2];
    my $res;
    $_[KERNEL]->post($src, $event, $res);
    return 1;
}

#
# 收到gmac请求
#
sub on_gmac {
    my ($self, $req, $src, $event) = @_[OBJECT, ARG0, ARG1, ARG2];
    my $res = 'FFFFFFFF';
    $_[KERNEL]->post($src, $event, $res);
}

#
# 收到vmac请求
#
sub on_vmac {
    my ($self, $req, $src, $event) = @_[OBJECT, ARG0, ARG1, ARG2];
    my $res = 1;
    $_[KERNEL]->post($src, $event, $res);
}

#
# 调用加密机
#
sub call_hsm {
}


1;

