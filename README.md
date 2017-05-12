# IoT for UPnP+

This repository contains instructions on how to setup a simple
IoT network based on the UPnP+.

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->
**Table of Contents**

- [IoT for UPnP+](#iot-for-upnp)
    - [Prerequisites](#prerequisites)
    - [Setup UPnP Cloud Server (UCS)](#setup-upnp-cloud-server-ucs)
    - [Setup UPnP Cloud Capable Device (UCCD)](#setup-upnp-cloud-capable-device-uccd)
        - [Prepare](#prepare)
        - [Build for the *host* target](#build-for-the-host-target)
        - [Build for *mim_iot_rpi* target](#build-for-mimiotrpi-target)
        - [Connect to an XMPP server](#connect-to-an-xmpp-server)
    - [UcaLib](#ucalib)
    - [SampleApp](#sampleapp)

<!-- markdown-toc end -->


## Prerequisites

* Elixir 1.4.x installed (http://elixir-lang.org/install.html or kiex)
* Erlang 19.x installed (http://www.erlang.org/downloads or kerl)
* Phoenix Framework installed (http://www.phoenixframework.org/docs/installation)
* Elixir Nerves installed (https://hexdocs.pm/nerves/installation.html)
* Docker installed (https://www.docker.com/community-edition)
* PSI/PSI+ installed (http://psi-im.org/download/ or https://sourceforge.net/projects/psiplus/)
* Install [eXpat] development kit (packages exists for different platform, e.g. [expat-ubuntu](ubuntu))

## Setup UPnP Cloud Server (UCS)

This is an instruction on how to setup UCS using [MongooseIM] XMPP server.


1. Run [MongooseIM Docker container](https://hub.docker.com/r/mongooseim/mongooseim/)

   ```bash 
   docker run -d -t -h mongooseim-1 --name mongooseim-1  -p 5222:5222 \
   -v `pwd`/mongooseim/config:/member mongooseim/mongooseim:rel-2.0
   ```

   > The `mongooseim/config` directory contains MongooseIM configuration 
   > (ejabberd.cfg) file.

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

    > Note: **Do not register a new user with PSI**. Use the account that you've
    > registered above.

    5. Change the user status to *Online* (Right Click on the user -> Status)
    6. Perform the two previous steps for *user_2*
    7. Make *user_1* and *user_2* friends

        1. Add *user_2* to *user_1* contact list (*Right Click* on *user_1* -> Add Contact)
            * XMPP Address: **user_2@localhost**

        1. Authorize the invitations on both sides

    10. Send a chat message between the users


## Setup UPnP Cloud Capable Device (UCCD)

This is an instruction for running UCCD as Nerves/Elixir application
on Raspberry Pi.

### Prepare

```bash
# fetch the dependencies
mix deps.get
# generate the ssh keys required to log in to the devices
./deps/erl_sshd/make_keys
# copy the host keys
mv priv apps/nerves_uccd/
# take a note of the generated in the CWD id_rsa and id_rsa.pub files
# that will be required at login into a device
```

### Build for the *host* target

1. Get dependencies and compile

```bash
cd apps/nerves_uccd/
# if the MIX_TARGET is not set it defaults to "host""
mix do deps.get, compile
```

2. Run

```bash
iex -S mix
```

After you have completed these steps you can go to the
[Connect to an XMPP server](#connect-to-an-xmpp-server) section and connect
to the XMPP server.

### Build for *mim_iot_rpi* target

1. Get dependencies and compile

```bash
cd apps/nerves_uccd/
export MIX_TARGET=mim_iot_rpi
mix do deps.get, compile

```

2. Build firmware for the board

```bash
mix firmware
# insert and SD card
mix firmware.burn
# insert the card into the Pi and start it - it will boot into the shell
```

2. SSH-in

```bash
# go to the root directory of the project
cd ../..
# ssh into the device
ssh -p 2222 -i id_rsa $RPI_IP # if you have [zeroconf] then use raspberrypi.local
# the id_rsa file was generated in the Prepare ssh step
```

3. Start Elixir shell

```erlang
'Elixir.IEx.CLI':local_start().
```

### Connect to an XMPP server

Connect to the XMPP server using of the accounts created in the
[Setup UPnP Cloud Server (UCS)](#setup-upnp-cloud-server-ucs) section.

To see the presences "flying" enable the XML console in the PSI for the
user account you're using to log in.

```elixir
alias Romeo.Connection, as: Conn
alias Romeo.Stanza
# the host is the IP address the UCS is listening on
opts = [jid: "user_1@localhost", password: "pass_1", host: "localhost"]
{:ok,pid} = Conn.start_link opts
Conn.send pid, Romeo.Stanza.presence
flush() # it will reveal XMPP messages being received from the server
```

In the aforementioned console you should see the presence being broadcasted by the
server on the behalf of the resource that you've just connected:

```xml
<presence from="user_1@localhost/9C8A435B9A7118081493384264818216" xml:lang="en" to="user_1@localhost/szm-mac"/>
```

## UcaLib

See [apps/uca_lib] which a library supporting UPnP+ steps.

## SampleApp

See [apps/sample_app] which is a sample app implementing UPnP Contorl Point with a UI.

[MongooseIM]: https://github.com/esl/MongooseIM
[Nerves]: http://nerves-project.org/
[eXpat]: http://expat.sourceforge.net/
[expat-ubuntu]: http://packages.ubuntu.com/precise-updates/libexpat1-dev
