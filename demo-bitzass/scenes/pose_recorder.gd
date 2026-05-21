extends MenuOption
class_name PoseRecorder

var saved_path := "res://saved/"

var active_joycon : JoyCon:
	set(v):
		if active_joycon == v:
			return
		if active_joycon:
			if active_joycon.zr_just_pressed.is_connected(on_zr_pressed):
				active_joycon.zr_just_pressed.disconnect(on_zr_pressed)
		active_joycon = v
		if not active_joycon:
			state = State.INACTIVE
			return
		await get_tree().process_frame
		active_joycon.zr_just_pressed.connect(on_zr_pressed)

@export var world_environment: WorldEnvironment
@export var post_processor: PostProcessor

enum State {
	INACTIVE,
	WAITING_TO_START,
	RECORDING,
	FINISHED,
	POST_PROCESSING
}

var new_action : AnimationRes:
	set(v):
		new_action = v
		if new_action:
			anim_player.animations[anim_player.next_slot] = new_action
			anim_player.current_animation_name = anim_player.next_slot

@export var anim_player : AnimPlayerModifier

@export var state := State.INACTIVE:
	set(value):
		if state == value:
			return
		var prev_state := state
		if value > State.POST_PROCESSING:
			state = State.INACTIVE
		else:
			state = value
		if not world_environment:
			await ready
		match state:
			State.INACTIVE:
				if anim_player:
					anim_player.active = false
				if prev_state == State.POST_PROCESSING:
					if new_action:
						select_animation_menu.add_option(new_action)
		
						
				world_environment.environment.background_color = color_at_start
				active_joycon = null
				new_action = null
			State.WAITING_TO_START:
				world_environment.environment.background_color = waiting_to_start_color
				anim_player.active = true
				anim_player.apply_on_top = false
			State.RECORDING:
				world_environment.environment.background_color = recording_color
				anim_player.current_playing_state = AnimPlayerModifier.PlayingState.RECORDING
			State.FINISHED:
				world_environment.environment.background_color = finished_color
				anim_player.current_playing_state = AnimPlayerModifier.PlayingState.PLAYING
				# Maybe not necessary to set in parallel, but setter won't be called inside setter
				Delayer.set_delayed(self, State.POST_PROCESSING, "state", 0.5, get_tree())
				ResourceSaver.save(anim_player.current_animation, saved_path + anim_player.current_animation_name + ".res")
			State.POST_PROCESSING:
				anim_player.current_time = 0.0
				world_environment.environment.background_color = post_processing_color
				anim_player.apply_on_top = true
				anim_player.active = true
				post_processor.active = true

var color_at_start : Color

const waiting_to_start_color := Color(0.702, 0.0, 0.266, 1.0)
const recording_color := Color(0.7, 0.495, 0.0, 1.0)
const finished_color := Color(0.0, 0.653, 0.014, 1.0)
const post_processing_color := Color(0.709, 0.612, 1.0, 1.0)

@export var select_animation_menu : TopDownMenu

func select(jc : JoyCon):
	select_animation_menu.active = true
	active_joycon = jc

func _ready() -> void:
	color_at_start = world_environment.environment.background_color

func on_b_pressed():
	match state:
		State.WAITING_TO_START, State.POST_PROCESSING:
			active_joycon = null

func on_zr_pressed():
	if state == State.FINISHED or state == State.POST_PROCESSING:
		return
	if select_animation_menu.active:
		select_animation_menu.select_current(active_joycon)
	if state == State.INACTIVE:
		return
	
	if not select_animation_menu.active:
		state += 1
	
	
