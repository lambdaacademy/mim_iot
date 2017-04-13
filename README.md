# IoT for UPnP+

## Setup UPnP Cloud Capable Device (UCCD)

### Host target

```bash
mix do deps.get, compile
cd apps/nerves_uccd/
iex -S mix
```

### RaspberryPi target

1. Prepare SSH

```bash
export MIX_TARGET=mim_iot_rpi
./deps/erl_sshd/make_keys
mv priv apps/nerves_uccd/priv
# take a note of the generated id_rsa and id_rsa.pub files that will be required at login
```

2. Build and run

```bash
cd apps/nerves_uccd
mix do deps.get, compile
mix firmware
# insert and SD card
mix firmware.burn
# insert the card into the Pi and start it - it will boot into the shell
```

2. SHH-in

```bash
cd $ROOT
ssh -p 2222 -i id_rsa $RPI_IP # if you have [zeroconf] then use raspberrypi.local
# the id_rsa file was generated in the Prepare ssh step
```

3. Start Elixir shell

```erlang
'Elixir.IEx.CLI':local_start().
```

### Connect to an XMPP server (target agnostic)

```elixir
alias Romeo.Connections, as: Conn
alias Romeo.Stanza
opts = [jid: "user_1@localhost", password: "pass_1", host: "169.254.11.124"]
{:ok,pid} = Conn.start_link opts
Conn.send pid, Romeo.Stanza.presence
flush() # it will reveal XMPP messages being received from the server
```



