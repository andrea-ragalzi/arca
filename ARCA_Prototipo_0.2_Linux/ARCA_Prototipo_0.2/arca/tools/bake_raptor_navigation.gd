extends SceneTree
func _initialize():call_deferred('run')
func run():
 var room=load('res://arca/raptor_room.tscn').instantiate()
 root.add_child(room)
 var mesh=NavigationMesh.new()
 mesh.agent_radius=0.6
 mesh.agent_height=1.5
 mesh.agent_max_climb=0.4
 mesh.cell_size=0.2
 mesh.cell_height=0.2
 mesh.geometry_parsed_geometry_type=NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
 mesh.geometry_collision_mask=1
 var data=NavigationMeshSourceGeometryData3D.new()
 NavigationServer3D.parse_source_geometry_data(mesh,data,room)
 NavigationServer3D.bake_from_source_geometry_data(mesh,data)
 print('Navigation polygons: ',mesh.get_polygon_count())
 var result=ResourceSaver.save(mesh,'res://arca/raptor_navigation.tres')
 print('Navigation save: ',result)
 room.stop_audio();room.queue_free()
 await process_frame
 quit(result)
