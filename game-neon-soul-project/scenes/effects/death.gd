extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$animetionPlayer.play("death")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	queue_free()
