extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")

var player
var enemy
var hud: CanvasLayer
var chapter := 0
var collected := 0
var needed := 3
var game_over := false
var won := false
var chapter_names = [
    "ГЛАВА I — ЗЕЛЁНЫЙ ХОЛМ",
    "ГЛАВА II — ЗАБЫТАЯ СТАНЦИЯ",
    "ГЛАВА III — ЛЕС ШЁПОТОВ",
    "ГЛАВА IV — КРАСНЫЙ КОРИДОР",
    "ГЛАВА V — ПОСЛЕДНИЙ ЭМЕРАЛЬД"
]
var chapter_subtitles = [
    "Найди три осколка. Не слушай голос из кустов.",
    "Станция закрыта уже много лет. Поезд всё ещё приходит.",
    "Фонари гаснут, когда он приближается.",
    "Не смотри слишком долго в красные окна.",
    "Собери последний осколок и доберись до выхода."
]
var objective: Label
var title_label: Label
var message_label: Label
var progress_label: Label
var chapter_label: Label
var overlay: ColorRect
var ambience_time := 0.0

func _ready():
    randomize()
    _setup_inputs()
    _build_hud()
    start_chapter(0)

func _process(delta):
    ambience_time += delta
    if game_over or won:
        return
    if is_instance_valid(enemy) and is_instance_valid(player):
        if enemy.global_position.distance_to(player.global_position) < 1.45:
            _end_game(false)
    if Input.is_action_just_pressed("ui_cancel"):
        _show_message("ПАУЗА  •  Нажми ESC, чтобы продолжить", 2.0)

func _setup_inputs():
    for action in ["move_forward","move_back","move_left","move_right","sprint"]:
        if not InputMap.has_action(action):
            InputMap.add_action(action)

func _build_hud():
    hud = CanvasLayer.new()
    add_child(hud)
    overlay = ColorRect.new()
    overlay.color = Color(0.0,0.0,0.0,0.0)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(overlay)

    var top = VBoxContainer.new()
    top.position = Vector2(24,18)
    top.add_theme_constant_override("separation",4)
    hud.add_child(top)
    chapter_label = Label.new()
    chapter_label.add_theme_font_size_override("font_size",22)
    chapter_label.add_theme_color_override("font_color",Color(0.85,0.82,1))
    top.add_child(chapter_label)
    objective = Label.new()
    objective.add_theme_font_size_override("font_size",17)
    objective.add_theme_color_override("font_color",Color(0.85,0.85,0.9))
    top.add_child(objective)

    progress_label = Label.new()
    progress_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    progress_label.position = Vector2(-220,22)
    progress_label.add_theme_font_size_override("font_size",20)
    progress_label.add_theme_color_override("font_color",Color(0.9,0.25,0.3))
    hud.add_child(progress_label)

    title_label = Label.new()
    title_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    title_label.position = Vector2(-350,-100)
    title_label.size = Vector2(700,60)
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size",34)
    title_label.add_theme_color_override("font_color",Color(1,0.18,0.24))
    hud.add_child(title_label)

    message_label = Label.new()
    message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    message_label.position = Vector2(-330,5)
    message_label.size = Vector2(660,80)
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message_label.add_theme_font_size_override("font_size",19)
    message_label.add_theme_color_override("font_color",Color(0.92,0.9,0.9))
    hud.add_child(message_label)

    _add_touch_controls()

func _add_touch_controls():
    var pad = Control.new()
    pad.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    pad.position = Vector2(18,-175)
    pad.size = Vector2(220,160)
    hud.add_child(pad)
    var specs = [
        ["↑",Vector2(70,0),"move_forward"],["←",Vector2(10,55),"move_left"],
        ["↓",Vector2(70,55),"move_back"],["→",Vector2(130,55),"move_right"]
    ]
    for spec in specs:
        var b=Button.new()
        b.text=spec[0]
        b.position=spec[1]
        b.size=Vector2(54,48)
        b.modulate=Color(0.8,0.8,1,0.72)
        pad.add_child(b)
        b.button_down.connect(func(): Input.action_press(spec[2]))
        b.button_up.connect(func(): Input.action_release(spec[2]))
    var sprint=Button.new()
    sprint.text="БЕГ"
    sprint.position=Vector2(160,5)
    sprint.size=Vector2(55,45)
    pad.add_child(sprint)
    sprint.button_down.connect(func(): Input.action_press("sprint"))
    sprint.button_up.connect(func(): Input.action_release("sprint"))
    var use=Button.new()
    use.text="ВЗЯТЬ"
    use.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
    use.position=Vector2(-150,-105)
    use.size=Vector2(125,70)
    hud.add_child(use)
    use.pressed.connect(_try_interact)

func start_chapter(index:int):
    chapter = index
    collected = 0
    needed = 3 if index < 4 else 1
    game_over = false
    won = false
    for child in get_children():
        if child != hud:
            child.queue_free()
    _make_world(index)
    player = CharacterBody3D.new()
    player.set_script(PlayerScript)
    player.name = "Player"
    player.position = Vector3(0,1.0,7)
    add_child(player)
    enemy = CharacterBody3D.new()
    enemy.set_script(EnemyScript)
    enemy.name = "The_Impostor"
    enemy.target_path = NodePath("../Player")
    enemy.position = Vector3(0,1.0,-15)
    add_child(enemy)
    chapter_label.text = chapter_names[index]
    objective.text = chapter_subtitles[index]
    progress_label.text = "ОСКОЛКИ: 0/%d" % needed
    title_label.text = chapter_names[index]
    message_label.text = chapter_subtitles[index]
    title_label.visible = true
    message_label.visible = true
    await get_tree().create_timer(3.2).timeout
    title_label.visible = false
    message_label.visible = false

func _make_world(index:int):
    var env = WorldEnvironment.new()
    var e = Environment.new()
    e.background_mode = Environment.BG_SKY
    var sky = Sky.new()
    var sky_mat = ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.008,0.006,0.025)
    sky_mat.sky_horizon_color = Color(0.055,0.012,0.035)
    sky_mat.ground_bottom_color = Color(0.008,0.006,0.012)
    sky_mat.ground_horizon_color = Color(0.035,0.01,0.025)
    sky.sky_material = sky_mat
    e.sky = sky
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.18,0.12,0.2)
    e.ambient_light_energy = 0.35
    e.fog_enabled = true
    e.fog_light_color = Color(0.07,0.025,0.055)
    e.fog_density = 0.035 + index*0.006
    env.environment=e
    add_child(env)
    var light=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-55,-25,0)
    light.light_energy=0.22
    add_child(light)
    _box(Vector3(0,-0.55,0),Vector3(18,1,70),Color(0.035,0.09,0.055))
    for side in [-1,1]:
        _box(Vector3(side*9,1,-5),Vector3(1,3,65),Color(0.025,0.035,0.03))
    for i in range(18):
        var z = -30 + i*3.6
        var x = [-1,1][i%2] * (4.2 + float(i%3))
        if index == 1:
            _box(Vector3(x,1.4,z),Vector3(1.8,2.8,1.8),Color(0.09,0.08,0.11))
            _box(Vector3(x,3,z),Vector3(2.2,0.2,2.2),Color(0.18,0.035,0.05))
        elif index == 3:
            _box(Vector3(x,1.4,z),Vector3(1.2,3,1.2),Color(0.16,0.015,0.025))
        else:
            _tree(Vector3(x,0,z),index)
    for i in range(needed):
        var shard=Area3D.new()
        shard.name="Shard"
        shard.position=Vector3(randf_range(-5,5),0.8,randf_range(-26,1))
        var mesh=MeshInstance3D.new()
        var sm=SphereMesh.new()
        sm.radius=0.32
        sm.height=0.65
        mesh.mesh=sm
        var mat=StandardMaterial3D.new()
        mat.albedo_color=Color(0.15,0.85,1)
        mat.emission_enabled=true
        mat.emission=Color(0.05,0.6,1)
        mat.emission_energy_multiplier=2.8
        mesh.material_override=mat
        shard.add_child(mesh)
        var col=CollisionShape3D.new()
        var shape=SphereShape3D.new()
        shape.radius=1.1
        col.shape=shape
        shard.add_child(col)
        shard.body_entered.connect(func(body): if body == player: _collect(shard))
        add_child(shard)
    _box(Vector3(0,1,-32),Vector3(5,2,1),Color(0.22,0.015,0.035))
    _show_message("Найди светящиеся осколки. Беги, если услышишь шаги.",3.0)

func _tree(pos:Vector3,index:int):
    var trunk=MeshInstance3D.new()
    var m=CylinderMesh.new()
    m.top_radius=0.18
    m.bottom_radius=0.32
    m.height=2.8
    trunk.mesh=m
    trunk.position=pos+Vector3(0,1.4,0)
    trunk.material_override=_mat(Color(0.055,0.035,0.045))
    add_child(trunk)
    var crown=MeshInstance3D.new()
    var s=SphereMesh.new()
    s.radius=1.45
    crown.mesh=s
    crown.position=pos+Vector3(0,3.1,0)
    crown.material_override=_mat(Color(0.018,0.065+index*0.006,0.035))
    add_child(crown)

func _box(pos:Vector3,size:Vector3,color:Color):
    var body=StaticBody3D.new()
    body.position=pos
    var mesh=MeshInstance3D.new()
    var bm=BoxMesh.new()
    bm.size=size
    mesh.mesh=bm
    mesh.material_override=_mat(color)
    body.add_child(mesh)
    var cs=CollisionShape3D.new()
    var shape=BoxShape3D.new()
    shape.size=size
    cs.shape=shape
    body.add_child(cs)
    add_child(body)

func _mat(color:Color):
    var m=StandardMaterial3D.new()
    m.albedo_color=color
    m.roughness=0.95
    return m

func _collect(shard):
    if not is_instance_valid(shard): return
    shard.queue_free()
    collected+=1
    progress_label.text="ОСКОЛКИ: %d/%d" % [collected,needed]
    _show_message("Осколок найден. Он уже знает, где ты.",1.8)
    if collected>=needed:
        if chapter<4:
            _show_message("Выход открыт. Доберись до красных ворот!",3.0)
            needed=0
        else:
            _end_game(true)

func _try_interact():
    if game_over or won: return
    if collected>=3 or (chapter==4 and collected>=1):
        start_chapter(min(chapter+1,4))
    else:
        _show_message("Здесь пока нечего открыть. Ищи осколки.",1.5)

func _show_message(text_value:String,duration:float):
    message_label.text=text_value
    message_label.visible=true
    await get_tree().create_timer(duration).timeout
    if not game_over and not won:
        message_label.visible=false

func _end_game(victory:bool):
    game_over=true
    won=victory
    if victory:
        title_label.text="ТЫ ВЫБРАЛСЯ… ИЛИ НЕТ?"
        message_label.text="Экран погас. Из динамика раздался шёпот: «До скорой встречи».\nСпасибо за игру."
    else:
        title_label.text="ОН НАШЁЛ ТЕБЯ"
        message_label.text="Тьма поглотила лес.\nНажми «ПОВТОРИТЬ», чтобы попробовать снова."
    title_label.visible=true
    message_label.visible=true
    var b=Button.new()
    b.text="ПОВТОРИТЬ"
    b.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    b.position=Vector2(-90,115)
    b.size=Vector2(180,55)
    hud.add_child(b)
    b.pressed.connect(func(): start_chapter(0))
