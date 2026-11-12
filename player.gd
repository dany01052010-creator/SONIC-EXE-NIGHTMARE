extends CharacterBody3D

var speed := 4.1
var sprint_speed := 6.5
var gravity := 18.0
var look_sensitivity := 0.0025
var camera_pivot: Node3D
var camera: Camera3D
var flashlight: SpotLight3D
var touch_origin := Vector2.ZERO
var touching_look := false

func _ready():
    var col=CollisionShape3D.new()
    var capsule=CapsuleShape3D.new()
    capsule.radius=0.38
    capsule.height=1.7
    col.shape=capsule
    add_child(col)
    camera_pivot=Node3D.new()
    camera_pivot.position=Vector3(0,0.55,0)
    add_child(camera_pivot)
    camera=Camera3D.new()
    camera.current=true
    camera.fov=78
    camera_pivot.add_child(camera)
    flashlight=SpotLight3D.new()
    flashlight.light_color=Color(0.78,0.84,1)
    flashlight.light_energy=3.2
    flashlight.spot_range=19
    flashlight.spot_angle=38
    camera.add_child(flashlight)
    flashlight.position=Vector3(0,0,0)
    Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
    if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x*look_sensitivity)
        camera_pivot.rotate_x(-event.relative.y*look_sensitivity)
        camera_pivot.rotation.x=clamp(camera_pivot.rotation.x,-1.25,1.25)
    elif event is InputEventScreenTouch:
        if event.pressed and event.position.x > get_viewport().size.x*0.42:
            touch_origin=event.position
            touching_look=true
        elif not event.pressed:
            touching_look=false
    elif event is InputEventScreenDrag and touching_look:
        rotate_y(-event.relative.x*0.004)
        camera_pivot.rotate_x(-event.relative.y*0.004)
        camera_pivot.rotation.x=clamp(camera_pivot.rotation.x,-1.25,1.25)
    elif event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
        Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
    if not is_on_floor():
        velocity.y-=gravity*delta
    var input_dir=Vector2.ZERO
    if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A): input_dir.x-=1
    if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D): input_dir.x+=1
    if Input.is_action_pressed("move_forward") or Input.is_key_pressed(KEY_W): input_dir.y+=1
    if Input.is_action_pressed("move_back") or Input.is_key_pressed(KEY_S): input_dir.y-=1
    input_dir=input_dir.normalized()
    var dir=(transform.basis*Vector3(input_dir.x,0,-input_dir.y)).normalized()
    var current_speed=sprint_speed if Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT) else speed
    velocity.x=dir.x*current_speed
    velocity.z=dir.z*current_speed
    move_and_slide()
