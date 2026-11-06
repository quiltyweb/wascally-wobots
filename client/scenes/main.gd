extends Control
## Shows the connection status and the server's hello reply.

@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	status_label.text = "Connecting…"
	Net.hello_received.connect(_on_hello_received)
	Net.failed.connect(_on_failed)
	Net.start()


func _on_hello_received(message: String) -> void:
	status_label.text = message


func _on_failed(error: String) -> void:
	status_label.text = "Error: %s" % error
