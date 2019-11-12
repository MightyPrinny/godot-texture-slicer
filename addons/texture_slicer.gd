tool
extends EditorPlugin

var dialog:WindowDialog = null

func _enter_tree():
	# Initialization of the plugin goes here
	dialog = preload("res://addons/texture_slicer/ts_dialog.tscn").instance()
	if is_instance_valid(dialog):
		get_editor_interface().get_base_control().add_child(dialog)
		on_dialog_created()
		add_tool_menu_item("Texture Slicer",self,"launch_tool")
		
	
func _exit_tree():
	# Clean-up of the plugin goes here
	remove_tool_menu_item("Texture Slicer")
	if is_instance_valid(dialog):
		dialog.free()

#Dialog code

var width = 0
var height = 0
var hsep = 0
var vsep = 0
var xoff = 0
var yoff = 0
var image_path = ""
var output_path = ""

func launch_tool(thing):
	if is_instance_valid(dialog):
		dialog.popup_centered(Vector2(503,239))
	
func close_dialog():
	if is_instance_valid(dialog):
		dialog.hide()

func on_dialog_created():
	dialog.get_node("OkCancel/C").connect("pressed",self,"on_cancel_pressed")
	dialog.get_node("OkCancel/O").connect("pressed",self,"on_ok_pressed")
	dialog.get_node("VBoxContainer/Image/LoadImage").connect("pressed",self,"on_load_image_pressed")
	dialog.get_node("VBoxContainer/Output/OpenFolder").connect("pressed",self,"on_load_output_pressed")
func on_load_image_pressed():
	var fdialog = EditorFileDialog.new()
	get_editor_interface().get_base_control().add_child(fdialog)
	fdialog.popup_exclusive = true
	fdialog.add_filter("*.png,*.stex,*.res,*.tex;Textures")
	fdialog.access = EditorFileDialog.ACCESS_RESOURCES
	fdialog.display_mode = EditorFileDialog.DISPLAY_THUMBNAILS
	fdialog.mode = EditorFileDialog.MODE_OPEN_FILE
	fdialog.popup_centered_ratio()
	fdialog.connect("confirmed",self,"on_image_selected",[fdialog])

func on_image_selected(fdialog:EditorFileDialog):
	var file = fdialog.current_dir
	if file == "res://":
		file += fdialog.current_file
	else:
		file += "/"+fdialog.current_file
	if is_instance_valid(dialog):
		dialog.get_node("VBoxContainer/Image/ImagePath").text = file
	image_path = file
	if !fdialog.is_queued_for_deletion():
		fdialog.queue_free()

func on_folder_selected(fdialog:EditorFileDialog):
	output_path = fdialog.current_dir
	if is_instance_valid(dialog):
		dialog.get_node("VBoxContainer/Output/OutputPath").text = output_path
	if !fdialog.is_queued_for_deletion():
		fdialog.queue_free()
	
func on_load_output_pressed():
	var fdialog = EditorFileDialog.new()
	get_editor_interface().get_base_control().add_child(fdialog)
	fdialog.popup_exclusive = true
	fdialog.access = EditorFileDialog.ACCESS_RESOURCES
	fdialog.display_mode = EditorFileDialog.DISPLAY_LIST
	fdialog.mode = EditorFileDialog.MODE_OPEN_DIR
	fdialog.popup_centered_ratio()
	fdialog.connect("confirmed",self,"on_folder_selected",[fdialog])
	
func on_ok_pressed():
	var tex = load(image_path)
	print(image_path)
	print(tex)
	if tex != null:
		if tex is Texture:
			width = dialog.get_node("VBoxContainer/Dimensions/Width").value
			height = dialog.get_node("VBoxContainer/Dimensions/Height").value
			hsep = dialog.get_node("VBoxContainer/Separation/HSep").value
			vsep = dialog.get_node("VBoxContainer/Separation/VSep").value
			xoff = dialog.get_node("VBoxContainer/Offset/XOff").value
			yoff = dialog.get_node("VBoxContainer/Offset/YOff").value
			slice_texture(tex)
		else:
			printerr("not a texture")
	close_dialog()
	
func on_cancel_pressed():
	close_dialog()
	
func get_filename_no_ext(path:String):
	var fname = ""
	var extension_dot_pos = path.find_last(".")
	var last_slash_pos = path.find_last("/") + 1 
	fname = path.substr(last_slash_pos,extension_dot_pos-last_slash_pos)
	return fname
	
func slice_texture(texture:Texture):
	var x = xoff
	var y = yoff
	var t_width = texture.get_width()
	var t_height = texture.get_height()
	var atex_name = get_filename_no_ext(image_path)
	var total = 0
	
	print("x:" + str(x))
	print("y:" + str(y))
	print("hsep:" + str(hsep))
	print("vsep:" + str(vsep))
	print("wdith:" + str(width))
	print("height:" + str(height))
	print("t_width:" + str(t_width))
	print("t_height:" + str(t_height))
	print("atex_name:" + str(atex_name))
	
	
	while(x < t_width):
		if x + width >= t_width:
				x += width + hsep
				continue
		while(y < t_height):
			if y + height >= t_height:
				y += height + vsep
				continue
				
			var atex = AtlasTexture.new()
			atex.atlas = texture
			atex.region = Rect2(Vector2(x,y),Vector2(width,height))
			var save_path = output_path+"/"+atex_name+"_"+str(total)+".atlastex"
			print("saving: "+ save_path)
			ResourceSaver.save(save_path,atex)
			
			y += height + vsep
			total += 1
		y = yoff
		x += width + hsep
		
		
