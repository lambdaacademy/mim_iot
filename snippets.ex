# Trace the act of connection

UcaLib.ConnFsm.module_info
ReconTrace.calls({UcaLib.ConnFsm,:connect,fn _ -> :return_trace end}, 10)

# "Register" and activate
alias UcaLib.{Registration, Discovery}
{:ok, pid} = Registration.connect
:ok = Discovery.activate pid

