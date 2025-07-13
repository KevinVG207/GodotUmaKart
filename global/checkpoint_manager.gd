extends Node3D

class CheckpointSegment:
	var length: float = 0.0
	var fraction: float = -1
	var start_fraction: float = -1
	var checkpoints: Array[Checkpoint] = []
	var first: Checkpoint:
		get:
			return checkpoints[0]
	var last: Checkpoint:
		get:
			return checkpoints[checkpoints.size()-1]
	var next: Array[CheckpointSegment] = []
	var prev: Array[CheckpointSegment] = []

var indexed_checkpoints: Dictionary[int, Checkpoint]
var segments: Array[CheckpointSegment]
var first_segment: CheckpointSegment
var last_segment: CheckpointSegment
var is_loop: bool

func get_next_checkpoints(checkpoint: Checkpoint) -> Array[Checkpoint]:
	var out: Array[Checkpoint] = []

	var segment := checkpoint.segment
	for next_segment in segment.next:
		out.append(next_segment.first)

	return out

func get_previous_checkpoints(checkpoint: Checkpoint) -> Array[Checkpoint]:
	var out: Array[Checkpoint] = []

	var segment := checkpoint.segment
	for prev_segment in segment.prev:
		out.append(prev_segment.last)

	return out

func fix_check_idx(idx: int) -> int:
	return posmod(idx, indexed_checkpoints.size())

func get_progress(vehicle: Vehicle4) -> float:
	var segment := indexed_checkpoints[fix_check_idx(vehicle.check_idx)].segment
	var checkpoint := indexed_checkpoints[fix_check_idx(vehicle.check_idx)]
	var progress: float = float(vehicle.lap)
	progress += segment.start_fraction
	progress += segment.fraction * checkpoint.segment_fraction_start
	progress += segment.fraction * checkpoint.segment_fraction * get_progress_in_checkpoint(vehicle)
	return progress

func get_progress_in_checkpoint(vehicle: Vehicle4) -> float:
	var checkpoint := indexed_checkpoints[fix_check_idx(vehicle.check_idx)]
	var dist_behind: float = abs(dist_to_checkpoint(vehicle, checkpoint))
	
	var shortest_dist_ahead: float = INF
	for next_checkpoint in checkpoint.next_points:
		var dist_ahead: float = abs(dist_to_checkpoint(vehicle, next_checkpoint))
		if dist_ahead < shortest_dist_ahead:
			shortest_dist_ahead = dist_ahead
	return dist_behind / (dist_behind + shortest_dist_ahead)

func dist_to_checkpoint(player: Vehicle4, checkpoint: Checkpoint) -> float:
	return Util.dist_to_plane(checkpoint.transform.basis.z, checkpoint.global_position, player.get_node("%Front").global_position)

func initialize_checkpoints(checkpoints: Array[Checkpoint]) -> void:
	set_indexes(checkpoints)
	
	create_segments(checkpoints)
	
	for segment in segments:
		print("LINKING SEGMENT ", segment.first.name, " - ", segment.last.name)
		segment.prev = find_related_segments(segment.first.prev_points, false)
		segment.next = find_related_segments(segment.last.next_points, true)
		calc_segment_length(segment)
	
	var shortest_path: Array[CheckpointSegment] = find_shortest_path(first_segment, last_segment)
	var shortest_path_length := calc_segment_array_length(shortest_path)
	
	set_segment_fractions(0.0, 1.0, shortest_path)
	
	var segments_that_need_fraction: Array[CheckpointSegment] = segments.duplicate()
	while segments_that_need_fraction.size() > 0:
		segments_that_need_fraction.append(segments_that_need_fraction.pop_front())
		var segment := segments_that_need_fraction[0]
		if segment.fraction >= 0:
			segments_that_need_fraction.erase(segment)
			continue
		
		var fraction_parent: CheckpointSegment = null
		for parent in segment.prev:
			if parent.fraction >= 0:
				fraction_parent = parent
				break
		
		if fraction_parent == null:
			continue
		
		var start_frac: float = fraction_parent.start_fraction + fraction_parent.fraction
		
		var path = find_shortest_path(segment, last_segment)
		
		var end_frac: float = find_first_valid_start_fraction(path)
		var valid_segments: Array[CheckpointSegment] = []
		for check_segment in path:
			if check_segment.fraction > 0:
				break
			valid_segments.append(check_segment)
		
		if end_frac < 0:
			printerr("ERROR: END FRAC NOT FOUND!")
			continue
		set_segment_fractions(start_frac, end_frac, valid_segments)
	return

func set_indexes(checkpoints: Array[Checkpoint]) -> void:
	var idx := 0
	for checkpoint in checkpoints:
		checkpoint.index = idx
		indexed_checkpoints.set(idx, checkpoint)
		idx += 1

func find_first_valid_start_fraction(path: Array[CheckpointSegment]) -> float:
	for segment in path:
		if segment.fraction >= 0:
			return segment.start_fraction
	return -1

func set_segment_fractions(start: float, end: float, segments: Array[CheckpointSegment]) -> void:
	var section_length := calc_segment_array_length(segments)
	var fraction_total := start
	for segment in segments:
		segment.fraction = remap(segment.length, 0.0, section_length, start, end) - start
		segment.start_fraction = fraction_total
		
		set_checkpoint_fractions(segment)
		
		fraction_total += segment.fraction

func set_checkpoint_fractions(segment: CheckpointSegment) -> void:
	var segment_length := 0.0
	for checkpoint in segment.checkpoints:
		if not checkpoint.next_points:
			continue
		
		var checkpoint_length := 0.0
		for next_checkpoint in checkpoint.next_points:
			checkpoint_length += checkpoint.global_position.distance_to(next_checkpoint.global_position)
		checkpoint_length /= checkpoint.next_points.size()
		checkpoint.length = checkpoint_length
		segment_length += checkpoint_length
	
	var fraction_total := 0.0
	for checkpoint in segment.checkpoints:
		checkpoint.segment_fraction = remap(checkpoint.length, 0.0, segment_length, 0.0, 1.0)
		checkpoint.segment_fraction_start = fraction_total
		fraction_total += checkpoint.segment_fraction

func find_shortest_path(first: CheckpointSegment, last: CheckpointSegment) -> Array[CheckpointSegment]:
	var history: Array[CheckpointSegment] = []
	var output: Array[Array] = []
	
	recursively_find_paths(first, last, history, output)
	
	output.sort_custom(func(a: Array[CheckpointSegment], b: Array[CheckpointSegment]): return calc_segment_array_length(a) < calc_segment_array_length(b))
	
	return output[0]

func calc_segment_array_length(segments: Array[CheckpointSegment]) -> float:
	var out := 0.0
	for segment in segments:
		out += segment.length
	return out

func recursively_find_paths(start: CheckpointSegment, end: CheckpointSegment, history: Array[CheckpointSegment], output: Array[Array]) -> void:
	var new_history := history.duplicate()
	new_history.append(start)
	if end in start.next:
		#print("STOP")
		new_history.append(end)
		output.append(new_history)
		return
	#print(start.last.name, " NEXT SIZE: ", start.next.size())
	for segment in start.next:
		#print("NEXT")
		recursively_find_paths(segment, end, new_history, output)

#func recursively_find_paths_until_fraction_set(start_frac: float, start: CheckpointSegment, history: Array[CheckpointSegment]) -> void:
	#var new_history := history.duplicate()
	#new_history.append(start)
	#for segment in start.next:
		#if segment.fraction >= 0:
			#print("STOP")
			#var full_list: Array[CheckpointSegment] = new_history.duplicate()
			#full_list.append(segment)
			#continue
		#recursively_find_paths_until_fraction_set(start_frac, segment, new_history, output)

func calc_segment_length(segment: CheckpointSegment) -> void:
	if segment.checkpoints.size() > 1:
		for i in range(segment.checkpoints.size() - 1):
			var c1 := segment.checkpoints[i]
			var c2 := segment.checkpoints[i+1]
			segment.length += c1.global_position.distance_to(c2.global_position)
	
	if segment.last.next_points:
		var next_distances := 0.0
		for c2 in segment.last.next_points:
			next_distances += segment.last.global_position.distance_to(c2.global_position)
		segment.length += next_distances / segment.last.next_points.size()


func find_related_segments(related_checkpoints: Array[BasePoint], next: bool) -> Array[CheckpointSegment]:
	var out: Array[CheckpointSegment]
	for checkpoint in related_checkpoints:
		print("RELATED: ", checkpoint.name)
		for segment in segments:
			if next and checkpoint == segment.first:
				print("FORWARD LINKING WITH ", checkpoint.name)
				out.append(segment)
				continue
			if !next and checkpoint == segment.last:
				print("BACKWARDS LINKING WITH ", checkpoint.name)
				out.append(segment)
				continue
	return out

func create_segments(checkpoints: Array[Checkpoint]) -> Array[CheckpointSegment]:
	var checkpoints_left: Array[Checkpoint] = checkpoints.duplicate()
	var cur_segment: CheckpointSegment = CheckpointSegment.new()
	segments = []
	var cur_checkpoint: Checkpoint = null
	
	var used_checkpoints: Array[Checkpoint] = []

	while checkpoints_left.size() > 0:
		if cur_checkpoint == null:
			cur_checkpoint = checkpoints_left.pop_front()
			#print("POPPED: ", cur_checkpoint.name)
		checkpoints_left.erase(cur_checkpoint)
		
		cur_segment.checkpoints.append(cur_checkpoint)
		cur_checkpoint.segment = cur_segment
		
		if cur_checkpoint.begin_node:
			first_segment = cur_segment
		if cur_checkpoint.end_node:
			last_segment = cur_segment
		#print("Adding checkpoint: ", cur_checkpoint.name, ", making segment: ", cur_segment.checkpoints)
		
		if cur_checkpoint.next_points.size() != 1 or cur_checkpoint.next_points[0].prev_points.size() != 1 or cur_checkpoint.next_points[0] not in checkpoints_left:
			segments.append(cur_segment)
			cur_segment = CheckpointSegment.new()
			cur_checkpoint = null
		else:
			cur_checkpoint = cur_checkpoint.next_points[0] as Checkpoint
	
	if cur_segment.checkpoints:
		segments.append(cur_segment)
	
	print("Segments:")
	for segment in segments:
		print(segment.checkpoints)

	return segments
