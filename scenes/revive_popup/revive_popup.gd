extends CanvasLayer

signal revived
signal rejected

@onready var cost_label := $Panel/VBox/CostLabel
@onready var revive_btn := $Panel/VBox/ReviveBtn
@onready var reject_btn := $Panel/VBox/RejectBtn

func _ready() -> void:
	revive_btn.pressed.connect(_on_revive)
	reject_btn.pressed.connect(_on_reject)

func show_revive(cost: int) -> void:
	cost_label.text = "Revivir por %d palitos?" % cost
	visible = true

func _on_revive() -> void:
	revived.emit()

func _on_reject() -> void:
	rejected.emit()
