extends SceneTree

## 量测伤害飘字截图：字身包围盒（设备像素 / 设计像素）与近黑描边厚度。
## 用法：
##   Godot --headless --path . --script res://tools/measure_damage_popup.gd -- \
##     --input=/tmp/after.png --rect=130,85,110,60 --fill=255,245,224 --label=after-normal
## rect 为设备像素（截图 750x1334，设计尺寸 375x667，2x）。
## 字身像素：与给定填充色每通道相差 <= tol 的像素，取最大连续行 / 列带，避免噪点。
## 描边：从字身左右边缘向外找第一段近黑像素，记录连续长度（排除基线阴影深蓝）。

const DESIGN_SCALE := 2.0
const MAX_STROKE_SCAN := 8
const DARK_LEVEL := 110

var _input := ""
var _rect := Rect2i()
var _fill := Color(1.0, 0.96, 0.88)
var _tol := 20.0
var _label := "popup"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--input="):
			_input = arg.trim_prefix("--input=")
		elif arg.begins_with("--rect="):
			var parts := arg.trim_prefix("--rect=").split(",")
			if parts.size() == 4:
				_rect = Rect2i(int(parts[0]), int(parts[1]), int(parts[2]), int(parts[3]))
		elif arg.begins_with("--fill="):
			var parts := arg.trim_prefix("--fill=").split(",")
			if parts.size() == 3:
				_fill = Color(float(parts[0]) / 255.0, float(parts[1]) / 255.0, float(parts[2]) / 255.0)
		elif arg.begins_with("--tol="):
			_tol = float(arg.trim_prefix("--tol="))
		elif arg.begins_with("--label="):
			_label = arg.trim_prefix("--label=")
	if _input.is_empty() or _rect.size == Vector2i.ZERO:
		push_error("[MeasurePopup] need --input and --rect")
		quit(1)
		return
	var image := Image.load_from_file(ProjectSettings.globalize_path(_input))
	if image == null:
		push_error("[MeasurePopup] cannot load %s" % _input)
		quit(1)
		return
	var bbox := _fill_bbox(image)
	if bbox.size == Vector2i.ZERO:
		push_error("[MeasurePopup] %s: no fill pixels in rect" % _label)
		quit(1)
		return
	var stroke_samples := _stroke_samples(image, bbox)
	var stroke_median := _median(stroke_samples)
	var stroke_max := 0
	for value in stroke_samples:
		stroke_max = maxi(stroke_max, int(value))
	print("[MeasurePopup] %s bbox=%d,%d %dx%d device; height=%.1f design px; width=%.1f design px; stroke median=%.1f device px (%.2f design px), max=%d; samples=%s" % [
		_label,
		bbox.position.x, bbox.position.y, bbox.size.x, bbox.size.y,
		float(bbox.size.y) / DESIGN_SCALE,
		float(bbox.size.x) / DESIGN_SCALE,
		stroke_median,
		stroke_median / DESIGN_SCALE,
		stroke_max,
		str(stroke_samples)
	])
	quit(0)


func _fill_bbox(image: Image) -> Rect2i:
	var row_counts: Dictionary = {}
	var col_counts: Dictionary = {}
	for y in range(maxi(_rect.position.y, 0), mini(_rect.position.y + _rect.size.y, image.get_height())):
		for x in range(maxi(_rect.position.x, 0), mini(_rect.position.x + _rect.size.x, image.get_width())):
			if not _matches_fill(image.get_pixel(x, y)):
				continue
			row_counts[y] = int(row_counts.get(y, 0)) + 1
			col_counts[x] = int(col_counts.get(x, 0)) + 1
	if row_counts.is_empty():
		return Rect2i()
	var row_band := _largest_band(row_counts, 2)
	if row_band.is_empty():
		return Rect2i()
	var min_x := 1 << 30
	var max_x := -1
	for x in col_counts.keys():
		if int(col_counts[x]) < 2:
			continue
		min_x = mini(min_x, int(x))
		max_x = maxi(max_x, int(x))
	if max_x < min_x:
		return Rect2i()
	return Rect2i(min_x, row_band[0], max_x - min_x + 1, row_band[1] - row_band[0] + 1)


## 返回像素计数 >= threshold 的最大连续区间 [start, end]。
func _largest_band(counts: Dictionary, threshold: int) -> Array:
	var keys := counts.keys()
	keys.sort()
	var best: Array = []
	var start := -1
	var last := -1
	for key in keys:
		if int(counts[key]) < threshold:
			continue
		if start < 0 or int(key) != last + 1:
			if start >= 0 and (best.is_empty() or last - start > best[1] - best[0]):
				best = [start, last]
			start = int(key)
		last = int(key)
	if start >= 0 and (best.is_empty() or last - start > best[1] - best[0]):
		best = [start, last]
	return best


func _matches_fill(color: Color) -> bool:
	return (
		absf(color.r * 255.0 - _fill.r * 255.0) <= _tol
		and absf(color.g * 255.0 - _fill.g * 255.0) <= _tol
		and absf(color.b * 255.0 - _fill.b * 255.0) <= _tol
	)


## 在字身包围盒的上 / 下及中间若干行，从左右边缘向外找近黑描边并数连续长度。
func _stroke_samples(image: Image, bbox: Rect2i) -> Array:
	var samples: Array = []
	var row_count := 9
	for i in range(row_count):
		var y := bbox.position.y + int(round(float(i) / float(row_count - 1) * float(bbox.size.y - 1)))
		var left_edge := -1
		var right_edge := -1
		for x in range(bbox.position.x, bbox.position.x + bbox.size.x):
			if _matches_fill(image.get_pixel(x, y)):
				if left_edge < 0:
					left_edge = x
				right_edge = x
		if left_edge < 0:
			continue
		var left_run := _run_outline(image, y, left_edge - 1, -1)
		var right_run := _run_outline(image, y, right_edge + 1, 1)
		if left_run > 0:
			samples.append(left_run)
		if right_run > 0:
			samples.append(right_run)
	return samples


func _run_outline(image: Image, y: int, start_x: int, direction: int) -> int:
	var first_dark := -1
	for step in range(6):
		var x := start_x + direction * step
		if x < 0 or x >= image.get_width():
			break
		if _is_dark(image.get_pixel(x, y)):
			first_dark = x
			break
	if first_dark < 0:
		return 0
	var run := 0
	for step in range(MAX_STROKE_SCAN):
		var x := first_dark + direction * step
		if x < 0 or x >= image.get_width():
			break
		if _is_dark(image.get_pixel(x, y)):
			run += 1
		else:
			break
	return run


## 近黑描边包含抗锯齿过渡：亮度低且三通道接近中性（排除旧版深蓝阴影 18,41,61）。
func _is_dark(color: Color) -> bool:
	var r := color.r * 255.0
	var g := color.g * 255.0
	var b := color.b * 255.0
	var max_channel := maxf(r, maxf(g, b))
	var min_channel := minf(r, minf(g, b))
	return max_channel <= DARK_LEVEL and (max_channel - min_channel) <= 26.0


func _median(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	var middle := sorted.size() / 2
	if sorted.size() % 2 == 1:
		return float(sorted[middle])
	return (float(sorted[middle - 1]) + float(sorted[middle])) / 2.0
