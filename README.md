# IoT for UPnP+

## Setup MongooseIM


1. Run [MongooseIM Docker container](https://hub.docker.com/r/mongooseim/mongooseim/)

   ```bash 
   docker run -d -t -h mongooseim-1 --name mongooseim-1  -p 5222:5222 \
   -v `pwd`/mongooseim/config:/member mongooseim/mongooseim:rel-2.0
   ```

   > The `mongooseim/config` directory contains MongooseIM configuration 
   > (ejabberd.cfg) file that has multi-user chat enabled.

2. Check that the server is running

   `telnet localhost 5222`

   > Issue `docker logs -f mongooseim-1` to see the server logs. Alternatively,
   > start the container with `-i` option.

3. *(optional)* Connect two users to see that the service works

    1. Install [Psi XMPP client](http://psi-im.org/)
    1. Register two users in the server
       ```bash
       docker exec -i -t mongooseim-1 /usr/lib/mongooseim/bin/mongooseimctl register user_1 localhost pass_1
       docker exec -i -t mongooseim-1 /usr/lib/mongooseim/bin/mongooseimctl register user_2 localhost pass_2
       ```
    2. Add an account for *user_1* to PSI (General -> Account Setup -> Add)

        * XMPP Address: **user_1@localhost**
        * Password **pass_1**

    5. Change the user status to *Online* (Right Click on the user -> Status)
    6. Perform the two previous steps for *user_2*
    7. Make *user_1* and *user_2* friends

        1. Add *user_2* to *user_1* contact list (*Right Click* on *user_1* -> Add Contact)
            * XMPP Address: **user_2@localhost**

        1. Authorize the invitations on both sides

    10. Send a chat message between the users


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

2. SSH-in

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



