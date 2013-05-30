package Zero;

our $VERSION = '0.1';

1;

__END__

=cut

===> : 请求过程
<--- : 应答过程
             
               (渠道进程)                                            (银行进程) 
               卡友渠道进程                                          银行工行进程
          ---------------------                                  --------------------
          |                   |                                  |                  |
          |  -----------------|                                  |   ---------------|
<-packet--|..|on_chnl_response|<------------$tran----------------|...|on_bank_packet|<--packet---
          |  -----------------|                                  |   ---------------| 
          |                   |                                  |                  | 
          |                   |            交易进程              |                  | 
          |                   |          --------------          |                  |
          |                   |          |            |          |                  |
          |                   |          |            |          |                  |
          |---------------    |          |--------    |          |--------          |     
=packet==>|on_chnl_packet|....|==$tran==>|on_chnl|....|==$tran==>|on_tran|..........|===packet==>
          |---------------    |          |--------    |          |--------          |
          |1> 解包            |          |1> 业务检查 |          |                  |
          |2> c_tcode         |          |2> 银行路由 |          |                  |
          |                   |          |  a> bank   |          |                  |
          |                   |          |  b> b_tcode|          |                  |
          |                   |          |            |          |                  |
|-------------------------------------------------------------------------------------------|
|                                  POE  Kernel                                              |
|-------------------------------------------------------------------------------------------|

=back




