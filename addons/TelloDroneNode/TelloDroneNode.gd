extends Node
class_name Tello

signal recive_control_code
signal recive_control_code_ok
signal recive_control_code_error

export(bool) var activate_telemetry := false
export(int, 0, 8) var keep_active := 0

export(int) var local_ctrl_port := 8889
export(int) var local_telemetry_port := 8890
export(String) var drone_ip := "192.168.10.1"
export(int) var drone_ctrl_port := 8889

var ctrl_socket : PacketPeerUDP
var tele_socket : PacketPeerUDP
var timer : Timer

var last_ctrl_msg : String
var telemetry_raw : String
var telemetry : Dictionary
var command_sended := false

func _ready() -> void:
    init_ctrl_socket()
    init_tele_socket()
    if keep_active > 0:
        timer = Timer.new()
        timer.wait_time = 5
        timer.one_shot = false
        timer.connect("timeout", self, "_on_timer_timeout")
        add_child(timer)
        timer.start(keep_active)

func _process(delta: float) -> void:
    if !command_sended:
        return
    process_ctrl()
    process_telemetry()
    
func _on_timer_timeout() -> void:
    speedQ()

func init_tele_socket() -> void:
    if !activate_telemetry:
        return
    tele_socket = PacketPeerUDP.new()
    # warning-ignore:return_value_discarded
    tele_socket.listen(local_telemetry_port)

func init_ctrl_socket() -> void:
    # warning-ignore:return_value_discarded
    ctrl_socket = PacketPeerUDP.new()
    ctrl_socket.listen(local_ctrl_port)

func process_telemetry() -> void:
    if !tele_socket:
        return
    var count := tele_socket.get_available_packet_count()
    if count < 1:
        return
    var bytes : PoolByteArray
    for _i in range(count):
        bytes = tele_socket.get_packet()
    telemetry_raw = bytes.get_string_from_ascii()

func update_telemetry() -> void:
    var raw := telemetry_raw
    var dir : Dictionary = {}
    var split1 := raw.split(";", false, 15)
    for item1 in split1:
        var split2 := String(item1).split(":", false, 2)
        var k := String(split2[0])
        var v := split2[1]
        if k.begins_with("ag"):
            dir[k] = float(v)
        else:
            dir[k] = int(v)
    telemetry = dir

func process_ctrl() -> void:
    var count := ctrl_socket.get_available_packet_count()
    if count < 1:
        return
    for _i in range(count):
        var bytes := ctrl_socket.get_packet()
        var msg := bytes.get_string_from_ascii()
        last_ctrl_msg = msg
        emit_signal("recive_control_code", msg)
        match msg:
            "ok":
                emit_signal("recive_control_code_ok")
            "error":
                emit_signal("recive_control_code_error")

func send_cmd(cmd: String, wait: bool = false) -> void:
    if keep_active > 0:
        timer.start(keep_active)
    if !command_sended and !cmd.begins_with("command"):
        push_error("command 'command' was never sended")
        return
    command_sended = true
    var packet := cmd.to_ascii()
    # warning-ignore:return_value_discarded
    ctrl_socket.set_dest_address(drone_ip, drone_ctrl_port)
    # warning-ignore:return_value_discarded
    ctrl_socket.put_packet(packet)
    if wait:
        yield(self, "recive_control_code_ok")

func command(wait: bool = false) -> void:
    send_cmd("command", wait)

func takeoff(wait: bool = false) -> void:
    send_cmd("takeoff", wait)

func land(wait: bool = false) -> void:
    send_cmd("land", wait)

func emergency(wait: bool = false) -> void:
    send_cmd("emergency", wait)

func up(distance: int, wait: bool = false) -> void:
    if distance < 20:
        push_error("up distance must be greater than or equeals 20")
        return
    if distance > 500:
        push_error("up distance must be smaller than or equeals 500")
        return
    send_cmd("up " + String(distance), wait)

func down(distance: int, wait: bool = false) -> void:
    if distance < 20:
        push_error("down distance must be greater than or equeals 20")
        return
    if distance > 500:
        push_error("down distance must be smaller than or equeals 500")
        return
    send_cmd("down " + String(distance), wait)

func left(distance: int, wait: bool = false) -> void:
    if distance < 20:
        push_error("left distance must be greater than or equeals 20")
        return
    if distance > 500:
        push_error("left distance must be smaller than or equeals 500")
        return
    send_cmd("left " + String(distance), wait)

func right(distance: int, wait: bool = false) -> void:
    if distance < 20:
        push_error("right distance must be greater than or equeals 20")
        return
    if distance > 500:
        push_error("right distance must be smaller than or equeals 500")
        return
    send_cmd("right " + String(distance), wait)

func forward(distance: int, wait: bool = false) -> void:
    if distance < 20:
        push_error("forward distance must be greater than or equeals 20")
        return
    if distance > 500:
        push_error("forward distance must be smaller than or equeals 500")
        return
    send_cmd("forward " + String(distance), wait)

func back(distance: int, wait: bool = false) -> void:
    if distance < 20:
        push_error("backward distance must be greater than or equeals 20")
        return
    if distance > 500:
        push_error("backward distance must be smaller than or equeals 500")
        return
    send_cmd("back " + String(distance), wait)

func cw(angle: int, wait: bool = false) -> void:
    if angle < 1:
        push_error("clockwise angle must be greater than or equeals 1")
        return
    if angle > 3600:
        push_error("clockwise angle must be smaller than or equeals 3600")
        return
    send_cmd("cw " + String(angle), wait)

func ccw(angle: int, wait: bool = false) -> void:
    if angle < 1:
        push_error("counter clockwise angle must be greater than or equeals 1")
        return
    if angle > 3600:
        push_error("counter clockwise angle must be smaller than or equeals 3600")
        return
    send_cmd("ccw " + String(angle), wait)

func flip(direction: int, wait: bool = false) -> void:
    match direction:
        1:
            send_cmd("flip f", wait)
        2:
            send_cmd("flip r", wait)
        3:
            send_cmd("flip b", wait)
        4:
            send_cmd("flip l", wait)
        _:
            push_error("flip direction not unkown")

func go(x: int, y: int, z: int, s: int, wait: bool = false) -> void:
    if x < 20 or y < 20 or z < 20 or s < 10:
        push_error("go x, y or z under 20 or speed under 10")
        return
    if x > 500 or y > 500 or z > 500 or s > 100:
        push_error("go x, y or z over 500 or speed over 100")
        return
    send_cmd("go {x} {y} {z} {s}".format({"x": x, "y": y, "z": z, "s": s}), wait)

func curve(x1: int, y1: int, z1: int, x2: int, y2: int, z2: int, s: int, wait: bool = false) -> void:
    if x1 < 20 or y1 < 20 or z1 < 20 or x2 < 20 or y2 < 20 or z2 < 20 or s < 10:
        return
    if x1 > 500 or y1 > 500 or z1 > 500 or x2 > 500 or y2 > 500 or z2 > 200 or s > 60:
        return
    # TODO check x/y/z can’t be between -20 – 20 at the same time
    # TODO check if the arc radius is not within the range of 0.5-10 meters, it responses false
    send_cmd("curve {x1} {y1} {z1} {x2} {y2} {z3} {s}".format({"x1": x1, "y1": y1, "z1": z1, "x2": x2, "y2": y2, "z2": z2, "s": s}), wait)

func speed(s: int, wait: bool = false) -> void:
    if s < 10 or s > 100:
        push_error("speed under 10 or over 100")
        return
    send_cmd("speed " + String(s), wait)

func rc(left_right: int, forward_backward: int, up_down: int, yaw: int, wait: bool = false) -> void:
    if left_right < -100 or forward_backward < -100 or up_down < -100 or yaw < -100:
        push_error("rc all values must be over -100")
        return
    if left_right > 100 or forward_backward > 100 or up_down > 100 or yaw > 100:
        push_error("rc all values must be under 100")
        return
    send_cmd("rc {lr} {fb} {ud} {y}".format({"lr": left_right, "fb": forward_backward, "ud": up_down, "y": yaw}), wait)

func wifi(ssid: String, password: String, wait: bool = false) -> void:
    if ssid.length() == 0:
        push_error("wifi ssid can not be an empty string")
        return
    send_cmd("wifi {ssid} {pass}".format({"ssid": ssid, "pass": password}), wait)

func speedQ(wait: bool = false) -> void:
    send_cmd("speed?", wait)
    
func batteryQ(wait: bool = false) -> void:
    send_cmd("battery?", wait)
    
func timeQ(wait: bool = false) -> void:
    send_cmd("time?", wait)
    
func heightQ(wait: bool = false) -> void:
    send_cmd("height?", wait)
    
func tempQ(wait: bool = false) -> void:
    send_cmd("temp?", wait)
    
func attitudeQ(wait: bool = false) -> void:
    send_cmd("attitude?", wait)
    
func baroQ(wait: bool = false) -> void:
    send_cmd("baro?", wait)
    
func accelerationQ(wait: bool = false) -> void:
    send_cmd("acceleration?", wait)
    
func tofQ(wait: bool = false) -> void:
    send_cmd("tof?", wait)
    
func wifiQ(wait: bool = false) -> void:
    send_cmd("wifi?", wait)
