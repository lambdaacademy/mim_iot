# UcaLib

Provides implementation for UPnP+ steps as described in 
"C.1.7 UCA Steps as Analogies to UDA" of [UDA 2.0]. 

To include `UcaLib` in the Nerves Image for a target add it as a dependency
in [../nerves_uccd/mix.exs](../nerves_uccd/mix.exs):

```elixir
def deps do
  [{:nerves, "~> 0.5.0", runtime: false},
   {:uca_lib, in_umbrella: true}, # <--- here
  deps(@target)
end
```

## Steps

### Registration

Refers to "C.5 Creating a Device or Control Point Resource" of [UDA 2.0]

```elixir
# config.exs
config :uca_lib, Registration,
  jid: "user_1@localhost",
  password: "pass_1",
  host: "localhost"
```

```elixir
# Connect to an UCS (XMPP server)
{:ok, pid} = UcaLib.Registration.connect host: "169.254.42.110"
# Disconnect from the UCS
UcaLib.Registration.disconnect pid
```

### Discovery

Refers to "C.6 Presence and Discovery" of [UDA 2.0]

```elixir
# Send presence of type "available" to the UCS
UcaLib.Discovery.activate pid
# Send presence of type "unavailable" to the UCS
UcaLib.Discovery.deactivate pid
```

### Eventing

Refers to "C.7 PubSub (Analog of Eventing)" of [UDA 2.0]

#### The publisher setup (a device)

1. Connect to the server and activate the device

```elixir
alias UcaLib.{Registration, Discovery, Eventing, Worker}
alias Romeo.Stanza
{:ok, pid} = Registration.connect
:ok = Discovery.activate pid
```

2. Discover a pubsub service and check it the device's node (a topic) exits

```elixir
Worker.send_stanza pid, Romeo.Stanza.disco_info("pubsub.localhost")
Worker.send_stanza pid, Stanza.pubsub_discover("pubsub.localhost", Registration.id(pid, :resource) |> elem(1))
# The following will discover all nodes
# Worker.send_stanza pid, Romeo.Stanza.disco_items("pubsub.localhost")
```

3. Create a pubsub node

```elixir
Worker.send_stanza pid, Stanza.pubsub_create("pubsub.localhost", Registration.id(pid, :resource) |> elem(1))
```

#### The subscriber setup (a control point)

1. Discover a node for a deivce

```elixir
alias SampleApp.UccCp
pub_device_resource = ... # the publisher device resource - copy it!
UccCp.send_stanza Romeo.Stanza.disco_info("pubsub.localhost")
UccCp.send_stanza Romeo.Stanza.pubsub_discover("pubsub.localhost", pub_device_resource)
```

2. Subscribe to a node

```elixir
my_full_jid = .... # the subscriber full jid
UccCp.send_stanza Romeo.Stanza.pubsub_subscribe("pubsub.localhost", pub_device_resource, my_full_jid)
```

#### Send an event from the publisher (the device)

```elixir
subitem = Eventing.xml_node("subitem", [], [Eventing.xml_node_content("hello")])
item = Eventing.xml_node("item", [{"id", "12345"}], [subitem])
Worker.send_stanza pid, Stanza.pubsub_publish("pubsub.localhost", Registration.id(pid, :resource) |> elem(1), item)
```

#### See the event being delivered to the subscriber (the control point)

```elixir
[debug] [user_1@localhost][INCOMING] "<message from='pubsub.localhost' to='user_1@localhost/urn:schemas-upnp-org:device:ContorlPoint:1:116665c5-b52d-47bc-86a9-46ebbf8bfb80' type='headline'><event xmlns='http://jabber.org/protocol/pubsub#event'><items node='urn:schemas-upnp-org:device:Player:1:b43e90b3-454b-4635-a7eb-bc4e618fb01d'><item id='12345'><subitem>hello</subitem></item></items></event></message>"
```

[UDA 2.0]: http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v2.0.pdf

