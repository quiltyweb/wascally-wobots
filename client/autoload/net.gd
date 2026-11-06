extends Node
## Owns the connection to the Nakama server: client, session and socket.
## Call `start()` once listeners are connected to the signals below.

signal hello_received(message: String)
signal failed(error: String)

const CONFIG: Dictionary = {
	"host": "127.0.0.1",
	"port": 7350,
	"server_key": "local-server-key",
	"scheme": "http",
}
const DEVICE_ID_PATH: String = "user://device_id"

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket


func start() -> void:
	client = Nakama.create_client(
		CONFIG["server_key"], CONFIG["host"], CONFIG["port"], CONFIG["scheme"]
	)

	var device_id: String = _load_or_create_device_id()
	session = await client.authenticate_device_async(device_id)
	if session.is_exception():
		_fail("Authentication failed", session.get_exception())
		return

	socket = Nakama.create_socket_from(client)
	var connected: NakamaAsyncResult = await socket.connect_async(session)
	if connected.is_exception():
		_fail("Socket connection failed", connected.get_exception())
		return

	var rpc: NakamaAPI.ApiRpc = await client.rpc_async(session, "hello", "")
	if rpc.is_exception():
		_fail("hello RPC failed", rpc.get_exception())
		return

	var data: Variant = JSON.parse_string(rpc.payload)
	if not data is Dictionary or not (data as Dictionary).has("message"):
		failed.emit("hello RPC returned an unexpected payload: %s" % rpc.payload)
		return
	hello_received.emit(str((data as Dictionary)["message"]))


func _fail(context: String, exception: NakamaException) -> void:
	var error: String = "%s: %s" % [context, exception.message]
	push_error(error)
	failed.emit(error)


func _load_or_create_device_id() -> String:
	if FileAccess.file_exists(DEVICE_ID_PATH):
		var existing: String = FileAccess.get_file_as_string(DEVICE_ID_PATH).strip_edges()
		if not existing.is_empty():
			return existing

	var device_id: String = _generate_uuid_v4()
	var file: FileAccess = FileAccess.open(DEVICE_ID_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save device id: %s" % error_string(FileAccess.get_open_error()))
	else:
		file.store_string(device_id)
		file.close()
	return device_id


## Random (version 4) UUID, e.g. "0f8fad5b-d9cb-469f-a165-70867728950e".
static func _generate_uuid_v4() -> String:
	var bytes: PackedByteArray = Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 0x0F) | 0x40  # version 4
	bytes[8] = (bytes[8] & 0x3F) | 0x80  # RFC 4122 variant
	var hex: String = bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12)
	]
