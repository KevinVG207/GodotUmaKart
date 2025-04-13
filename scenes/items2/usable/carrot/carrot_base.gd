extends UsableItem

class_name CarrotBase

@export var uses_left: int = 3
@export var images: Array[CompressedTexture2D]

func use() -> void:
	uses_left -= 1
	
	owned_by.apply_boost(Vehicle4.BoostType.NORMAL)
	
	if uses_left <= 0:
		clear()
		return
	
	update_image(images[uses_left-1])
