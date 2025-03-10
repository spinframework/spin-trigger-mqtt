# An MQTT Trigger/Plugin for Fermyon Spin Framework

MQTT is a dominant communication protocol in IoT and edge scenarios, used by major products and services in manufacturing, automotive and other industries.
Objective of this repo is to provide a robust plugin/trigger to receive MQTT messages in the Spin based wasm components.

## Usage Guidance

This plugin is a trigger plugin i.e. it is activated when message is received on a configured MQTT topic.
The plugin then instantiates a Wasm component and injects the message to the component, which in turn process the message and can optionally publish the messages to any of the available targets in Spin e.g. MQTT, Redis, Http endpoints.

### Install Plugin

Install MQTT Plugin:

```bash
spin plugin install --url https://github.com/spinkube/spin-trigger-mqtt/releases/download/canary/trigger-mqtt.json --yes
```

[Note: release management for multiple versions of this plugin/trigger will be added soon]

If you want to learn more about Spin's plugin model, read [here](https://www.fermyon.com/blog/managing-spin-templates-and-plugins).

### Install Template

[Spin templates](https://www.fermyon.com/blog/managing-spin-templates-and-plugins) allow a Spin developer to quickly create the skeleton of an application or component, ready for the application logic to be filled in. As part of this repo, a new template is created to help build applications which make use of MQTT as a communication protocol/trigger.

Install MQTT Template:

```bash
spin templates install --git https://github.com/spinkube/spin-trigger-mqtt --upgrade
```

### Create Spin App

```bash
spin new -t mqtt-rust mqtt-app
```

## Templating `mqtt` Configuration in `spin.toml`

The `address`, `username`, `password` and `topic` support the ability to be configured using Spin variables. An example of configuring the password using env variables:

```toml
#spin.toml
spin_manifest_version = 2

[application]
name = "mqtt-app"
version = "0.1.0"
description = "Demo app to receive MQTT messages."
authors = ["Suneet Nangia <suneetnangia@gmail.com>"]

[variables]
password = { required = true }

[application.trigger.mqtt]
address = "mqtt://localhost:1883"
username = "user"
password = "{{ password }}"
keep_alive_interval = "30"
...
```

To inject the Spin variable using environment variables:

```bash
SPIN_VARIABLE_PASSWORD=password spin up
```

## State of Play

1. Authenticates using anonymous and username/password to MQTT server.
2. Receive messages from an MQTT topic per configured QoS.

[more MQTT client/subscription attributes will be available soon]

## Dev Loop [Build and Install from Source]

* Open the repo in Dev Container or in pre-configured GitHub [Codespace](https://codespaces.new/spinkube/spin-trigger-mqtt)
* Run ```make``` to build and install the plugin locally.
* Update ```examples/mqtt-app/spin.toml``` to reflect your MQTT server details and ensure it's accessible on the network.
* Run ```spin build --up --from examples/mqtt-app/spin.toml``` to run the example Spin app.
* Run ```mqttx pub -t 'messages-in01' -h '<mqtt server ip>' -p 1883 -u <user> -P <password> -m 'Hello to  MQTT Spin Component!'``` with the hostname and credentials for your server, to publish the message which is then received by Spin app.
* Optionally, run ```make clean``` to clean up and rebuild and install the plugin locally.
