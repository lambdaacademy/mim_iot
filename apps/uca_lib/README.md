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
alias UcaLib.{Registration, Discovery, Eventing, Worker, Eventing}
alias Romeo.Stanza
{:ok, pid} = Registration.connect
:ok = Discovery.activate pid
```

2. Setup the Eventing

It includes:

* discovery of a pubsub service (it defaults to `pubsub.localhost` and can be set
via config) 
* ensuring that the device's pubsub node exists (by default it is named after 
the resource part of the device JID) 


```elixir
Eventing.setup pid
```

#### The subscriber setup (a control point)

1. Connect to the service and activate the device's

Same as for the publisher

1. Setup the Eventing

Same as for the publisher expect for creating the device's node.

```elixir
Eventing.setup pid, create_node: false
```

2. Subscribe to a pubsub node of a device

```elixir
device_jid = "user_1@localhost/urn:schemas-upnp-org:device:Player:1:6603896f-1d42-450b-8a84-0ee323fcacb8"
on_notify = &(IO.puts "=== Got notification on #{inspect &1}: #{inspect &2}")
Eventing.subscribe pid, device_jid, on_notify 
```

#### Send an event from the publisher (the device)

```elixir
subitem = Eventing.xml_node("subitem", [], [Eventing.xml_node_content("hello")])
item = Eventing.xml_node("item", [{"id", "12345"}], [subitem])
Eventing.publish pid, item
```

#### See the event being delivered to the subscriber (the control point)

```elixir
=== Got notification on "5D79BD21BD473": [{:xmlel, "item", [{"id", "12345"}], [{:xmlel, "subitem", [], [xmlcdata: "hello"]}]}]
```

[UDA 2.0]: http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v2.0.pdf

