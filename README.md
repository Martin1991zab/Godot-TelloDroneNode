# Godot Engine - Tello Control Node

With this Addon you can control your Ryze/ DJI Tello Drone with Godot.
It is also possible to read the telemetry with this Node.

Because godot does not support h264 there is no video or photo support.
But i accept pull request if you want to implement it.

You can find the API documentation [here](https://www.ryzerobotics.com/de/tello/downloads) under "Tello SDK"

# Usage

Add the Tello Node to your project tree.
To connect with the drone first connect to the wifi of the drone.
After that you can call the `start()` method of the node.

The default setting should fit.

## Settings

### Activate Telemetry (default: true)

This says that telemetry shall be received at all

### Telemetry Update Time (default: 0.2)

How often shall the received telemetry be parsed.

Any positive value means there is a timer that call the update every x seconds.
Zero means every frame.
And a negative value means you have to call the `update_telemetry()` method yourself

### Local Ctrl Port (default: 8889)

On which udp port should the return codes from the drone arrive.

### Local Telemetry Port (default: 8890)

On which udp port the telemetry arrives. Only change when you know what you do, 
for example when you use a port redirect or udp proxy.

### Drone IP (default: 192.168.10.1)

The IP-Address of the drone.

### Drone Ctrl Port (default: 8889)

This is the udp port the drone listens on for new commands

## API

### `start()`

Tells the drone to listen to api commands and initiate anything

### `takeoff()`

Lets the drone start

### `land()`

Lets the drone land

### `emergency()`

Turn of the motors.

### forward, back, left, right, up, down (distance: int)

Move the drone in that direction.

### cw, ccw (angle: int)

Turn clock or counter clockwise.

