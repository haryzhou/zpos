package ZPOS::Simu::NAC;
use strict;
use warnings;
use POE;

#---------------------------------------------------------------------------
#                            NAC模拟器
# -----                       -----                            ------
# |POS|----tel+head+8583----->|NAC|<----skey+tel+head+8583---->|POSP|
# -----                       -----                            ------
#
# name => 'head',
# posp => {
#     name => 'head'
#     host =>
#     port => 
# },
# nac => {
# },
#---------------------------------------------------------------------------
sub new {
}

#
# $self->{$zcfg, $logger)
#
sub spawn {
    my ($self, $zcfg, $logger) = @_;
    $self->{logger} = $logger;
    POE::Session->create(
        object_states => [
            $self => {
                on_posp_connect => 'on_posp_connect',   # 开始连接POSP
                on_posp_packet  => 'on_posp_packet',    # 收到POSP应答
                on_posp_error   => 'on_posp_error',     # POSP关闭

                on_accept       => 'on_accept',         # 收到POS连接
                on_pos_packet   => 'on_pos_packet',     # 收到POS请求
                on_pos_error    => 'on_pos_error',      # POS终端关闭
                on_pos_flush    => 'on_pos_flush',      # 发送POS应答完毕
            },
        ],
        inline_states => {
            _start => sub {
                $_[KERNEL]->alias_set($self->{name});                
                $_[KERNEL]->yield('on_posp_connect');
            },
        },
    );
}

#
# 连接posp
#
sub on_connect_posp {
    my $self = $_[OBJECT];
    my $psock = IO::Socket::INET->new(
        PeerAddr  => $self->{posp}{host},
        PeerPort  => $self->{posp}{port},
    );
    unless($psock) {
        $_[KERNEL]->delay('on_connect_posp' => 1);
        return 1;
    }
    my $pw = POE::Wheel::ReadWrite->new(
        Handle     => $psock,
        InputEvent => 'on_posp_packet',
        Filter     => POE::Filter::Block->new( LengthCodec => binary_n(2)),
    );
    $_[HEAP]{pw} = $pw;
    return 1;
}

#
# 收到pos请求连接
#
sub on_accept {
    my $sock = $_[ARG0];
    my $pos = POE::Wheel::ReadWrite->new(
        Handle     => $sock,
        InputEvent => 'on_pos_packet',
        Filter     => POE::Filter::Block->new( LengchCodec => binary_n(2) ),
    );
    $_[HEAP]{pos}{$pos->ID}{wheel} = $pos;
}

#
# 收到pos发送的报文: tel + head + 8583
#
sub on_pos_packet {
    my ($packet, $id) = @_[ARG0, ARG1];
    my $skey = int(rand(100000));   # 相当于报文头

    $_[HEAP]{pos}{$id}{skey} = $skey;
    $_[HEAP]{skey}{$skey}    = $id;
}

#
# 响应pos终端完毕
#
sub on_pos_flush { 
    delete $_[HEAP]{pos}{$_[ARG0]};  
}
 

#
# pos终端关闭连接
#
sub on_pos_error {
    my ($op, $errno, $errstr, $id) = @_[ARG0,ARG1,ARG2,ARG3];
    my $t = delete $_[HEAP]{$id};
    delete $_[HEAP]{skey}{$t->{skey}};
}

#
# 收到posp的报文: skey + head + 8583
#
sub on_posp_packet {
    my ($packet, $id) = @_[ARG0, ARG1];    
    my $skey;  # 从$packet中取出skey
    my $pos_id = delete $_[HEAP]{skey}{$skey};
    $_[HEAP]{pos}{$pos_id}->put($packet);
}


#
# posp关闭连接 :  重连POSP
#
sub on_posp_error {
    delete $_[HEAP]{pw};
    $_[KERNEL]->yield('on_posp_connect');
    return;
}

1;

__END__

