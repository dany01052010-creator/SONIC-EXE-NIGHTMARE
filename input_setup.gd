extends Node
func _ready():
    _bind("move_forward",KEY_W)
    _bind("move_back",KEY_S)
    _bind("move_left",KEY_A)
    _bind("move_right",KEY_D)
    _bind("sprint",KEY_SHIFT)
func _bind(action:String,key:int):
    if not InputMap.has_action(action): InputMap.add_action(action)
    var ev=InputEventKey.new()
    ev.physical_keycode=key
    InputMap.action_add_event(action,ev)
