use Mix.Config

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
