# SampleApp

Provides implementation for UPnP Cloud Capable Control Point as described in
"Annex C Cloud" of [UDA 2.0].

Install its dependencies with:

```bash
mix deps.get
cd assets && npm install
```

To include `SampleApp` in the Nerves Image for a target add it as a dependency
in [../nerves_uccd/mix.exs]:

```elixir
def deps do
  [{:nerves, "~> 0.5.0", runtime: false},
   {:sample_app, in_umbrella: true}, # <--- here
  deps(@target)
end
```

It can also be started standalone with `mix phx.server`

Now you can visit [`localhost:4000/devices`](http://localhost:4000/devices) from your browser.
It should display all the connected UPnP+ devices.

[UDA 2.0]: http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v2.0.pdf
