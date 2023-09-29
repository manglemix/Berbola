extends Panel


@onready var player: LocalPlayer = $"../.."


func _ready() -> void:
	player.died.connect(_on_dying)


func _on_dying():
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	await tween.finished
	player.respawn_at(ThisUser.last_activated_checkpoint)
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1).set_delay(0.2)
	tween.play()
