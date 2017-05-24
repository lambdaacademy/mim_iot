use Mix.Config

config :uca_lib, Registration,
  jid: "user_1@localhost",
  password: "pass_1",
  host: "169.254.213.54",
  # host: "localhost",
  device_type: "Player",
  device_version: 1

config :nerves_uccd, Networking,
  # none
  # type: :none
  # eth
  type: :eth,
  opts: [interface: :eth0]
  # wireless
  # type: :wireless,
  # opts: [interfac: "wlan0", ssid: "IoTWorkshop", key_mgmt: :"WPA-PSK", psk: "iloveiot"]

config :erl_sshd,
  app: :nerves_uccd,
  port: 2222
