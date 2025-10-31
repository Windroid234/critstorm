class_name IngredientContainer extends HBoxContainer


@export var icon_tex: TextureRect
@export var label: Label

func _ready() -> void:
	pass

func set_label(text: String) -> void:
	label.text = text

func set_icon(texture) -> void:
	icon_tex.texture = texture
