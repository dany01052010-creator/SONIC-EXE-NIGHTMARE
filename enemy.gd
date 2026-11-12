extends CharacterBody3D

var target_path:NodePath
var target:Node3D
var speed:=2.05
var gravity:=18.0
var hunt_timer:=0.0
var body_mesh:MeshInstance3D

func _ready():
    var col=CollisionShape3D.new()
    var cap=CapsuleShape3D.new()
    cap.radius=0.48
    cap.height=2.0
    col.shape=cap
    add_child(col)
    body_mesh=MeshInstance3D.new()
    var mesh=CapsuleMesh.new()
    mesh.radius=0.48
    mesh.height=2.0
    body_mesh.mesh=mesh
    var mat=StandardMaterial3D.new()
    mat.albedo_color=Color(0.015,0.025,0.12)
    mat.emission_enabled=true
    mat.emission=Color(0.035,0.0,0.025)
    mat.emission_energy_multiplier=0.8
    body_mesh.material_override=mat
    add_child(body_mesh)
    for side in [-1,1]:
        var eye=MeshInstance3D.new()
        var em=SphereMesh.new()
        em.radius=0.105
        eye.mesh=em
        eye.position=Vector3(side*0.19,0.32,-0.39)
        var red=StandardMaterial3D.new()
        red.albedo_color=Color(1,0.015,0.025)
        red.emission_enabled=true
        red.emission=Color(1,0,0)
        red.emission_energy_multiplier=4
        eye.material_override=red
        add_child(eye)

func _physics_process(delta):
    if target==null:
        target=get_node_or_null(target_path)
        return
    hunt_timer+=delta
    var distance=global_position.distance_to(target.global_position)
    if distance<23:
        speed=3.25 if distance>8 else 4.5
    else:
        speed=1.4
    var dir=target.global_position-global_position
    dir.y=0
    if dir.length()>0.1:
        dir=dir.normalized()
        velocity.x=dir.x*speed
        velocity.z=dir.z*speed
        look_at(Vector3(target.global_position.x,global_position.y,target.global_position.z),Vector3.UP)
    if not is_on_floor(): velocity.y-=gravity*delta
    move_and_slide()
