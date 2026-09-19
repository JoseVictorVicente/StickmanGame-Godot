class_name InventoryLayout
extends Resource
## Offsets visuais das seções do painel de inventário.
## O espaço reservado no layout permanece igual; offsets negativos sobrepõem para cima.


@export_group("Character column")
@export var portrait_region_offset: Vector2 = Vector2(0, -12)
@export var formation_button_offset: Vector2 = Vector2(0, -14)
@export var portrait_controls_spacing: float = 2.0

@export_group("Seções do painel")
@export var offset_area_heroi: Vector2 = Vector2.ZERO
@export var offset_linha_inventario: Vector2 = Vector2.ZERO
@export var offset_menu_inferior: Vector2 = Vector2.ZERO
