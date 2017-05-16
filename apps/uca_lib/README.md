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

[UDA 2.0]: http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v2.0.pdf

