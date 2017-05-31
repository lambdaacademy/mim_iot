use Mix.Config

config :uca_lib, Registration,
  jid: "user_1@localhost",
  password: "pass_1",
  host: "192.168.0.1",
  # host: "localhost",
  device_type: "Player",
  device_version: 1

config :nerves_uccd, Networking,
  # NO NETWORKING - no config

  # types: :ethernet, :wireless
  type: :ethernet,
  # modes: :static, :dynamic
  mode: :static,
  # opts for :ethernet type and :dynamic mode:
  #  [interface: :eth0]
  # opts for :ethernet type and :static mode: interface:
  #  [:eth0, ip: "192.168.0.1", mask: "16"]
  # opts for :wireless type and :dynamic mode:
  #   [interface: "wlan0", ssid: "my_net", key_mgmt: :"WPA-PSK", psk: "pass"]
  # opts for :wireless type and :static mode: interface:
  #   [interface: "wlan0", ip: "192.168.0.1", ssid: "my_net", key_mgmt: :"WPA-PSK", psk: "pass"]
  opts: [interface: :eth0, ip: "192.168.0.100", mask: "16"]

config :erl_sshd,
  app: :nerves_uccd,
  port: 2222
