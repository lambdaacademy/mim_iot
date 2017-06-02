use Mix.Config

config :uca_lib, Registration,
  jid: "user_1@localhost",
  password: "pass_1",
  host: "192.168.0.1",
  device_type: "Player",
  device_version: 1

config :nerves_uccd, Networking,
  # NO NETWORKING - no config

  # types: :ethernet, :wireless
  type: :ethernet,
  # opts for :ethernet type and DHCP
  #  [interface: :eth0]
  # opts for :ethernet type and fixed IP address
  #  [interface: :eth0, ip: "192.168.0.100"]
  # opts for :wireless type and DHCP
  #  [interface: :wlan0, ssid: "my_net", psk: "pass", key_mgmt: :"WPA-PSK"]
  opts: [interface: :eth0]

config :erl_sshd,
  app: :nerves_uccd,
  port: 2222
