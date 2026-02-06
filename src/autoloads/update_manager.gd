extends Node

signal update_checked(update_available: bool, current_version: String, latest_version: String)
signal update_download_progress(downloaded_bytes: int, total_bytes: int)
signal update_ready(latest_version: String)
signal update_error(message: String)

const CHECK_COOLDOWN_SEC: float = 300.0

var _check_request: HTTPRequest
var _download_request: HTTPRequest
var _progress_timer: Timer

var _last_check_unix: int = 0

var _current_version: String = "0.0.0"
var _latest_version: String = ""

var _asset_name: String = ""
var _asset_url: String = ""
var _checksums_url: String = ""

var _download_dir_abs: String = ""
var _downloaded_asset_abs: String = ""
var _downloaded_checksums_abs: String = ""

enum DownloadStep { NONE, CHECKSUMS, ASSET }
var _download_step: DownloadStep = DownloadStep.NONE


func _ready() -> void:
	_current_version = _get_current_version()

	_check_request = HTTPRequest.new()
	add_child(_check_request)
	_check_request.request_completed.connect(_on_check_request_completed)

	_download_request = HTTPRequest.new()
	add_child(_download_request)
	_download_request.request_completed.connect(_on_download_request_completed)
	# Godot builds may not expose progress signal on HTTPRequest.
	if _download_request.has_signal("request_progress"):
		_download_request.connect(
			"request_progress",
			Callable(self, "_on_download_request_progress")
		)

	_progress_timer = Timer.new()
	_progress_timer.one_shot = false
	_progress_timer.wait_time = 0.25
	add_child(_progress_timer)
	_progress_timer.timeout.connect(_on_progress_timer_timeout)


func check_for_updates(force: bool = false) -> void:
	if _is_config_missing():
		return

	var now_unix: int = Time.get_unix_time_from_system() as int
	if not force and _last_check_unix > 0 and float(now_unix - _last_check_unix) < CHECK_COOLDOWN_SEC:
		update_checked.emit(_is_update_available(), _current_version, _latest_version)
		return

	_last_check_unix = now_unix
	_current_version = _get_current_version()

	var owner: String = _get_repo_owner()
	var repo: String = _get_repo_name()
	var url: String = "https://api.github.com/repos/%s/%s/releases/latest" % [owner, repo]

	var headers: Array[String] = [
		"User-Agent: NeonSurvivorUpdateManager",
		"Accept: application/vnd.github+json",
	]

	var err: int = _check_request.request(url, headers)
	if err != OK:
		update_error.emit("update_check_request_failed err=%d" % err)


func start_update_download() -> void:
	if not _is_update_available():
		return
	if _asset_url.is_empty() or _checksums_url.is_empty():
		update_error.emit("update_missing_assets")
		return

	var updates_dir_abs: String = ProjectSettings.globalize_path("user://updates")
	DirAccess.make_dir_recursive_absolute(updates_dir_abs)

	var version_dir: String = _sanitize_filename(_latest_version)
	_download_dir_abs = updates_dir_abs.path_join(version_dir)
	DirAccess.make_dir_recursive_absolute(_download_dir_abs)

	_downloaded_checksums_abs = _download_dir_abs.path_join("SHA256SUMS.txt")
	_download_request.download_file = _downloaded_checksums_abs
	_download_step = DownloadStep.CHECKSUMS
	_progress_timer.start()

	var headers: Array[String] = ["User-Agent: NeonSurvivorUpdateManager"]
	var err: int = _download_request.request(_checksums_url, headers)
	if err != OK:
		update_error.emit("update_download_checksums_failed err=%d" % err)


func apply_update_and_restart() -> void:
	if _downloaded_asset_abs.is_empty() or not FileAccess.file_exists(_downloaded_asset_abs):
		update_error.emit("update_not_downloaded")
		return

	if OS.has_feature("editor"):
		update_error.emit("update_apply_not_supported_in_editor")
		return

	var pid: int = OS.get_process_id()
	var exe_abs: String = OS.get_executable_path()
	var install_dir_abs: String = exe_abs.get_base_dir()

	if OS.get_name() == "Windows":
		_apply_windows(pid, exe_abs, install_dir_abs)
		return
	if OS.get_name() == "Linux":
		_apply_linux(pid, exe_abs)
		return

	update_error.emit("update_apply_unsupported_os=%s" % OS.get_name())


func _apply_windows(pid: int, exe_abs: String, install_dir_abs: String) -> void:
	var script_abs: String = _download_dir_abs.path_join("apply_update.cmd")
	var stage_abs: String = _download_dir_abs.path_join("stage")

	var zip_abs: String = _downloaded_asset_abs
	var zip_quoted: String = '"%s"' % zip_abs
	var stage_quoted: String = '"%s"' % stage_abs
	var install_quoted: String = '"%s"' % install_dir_abs
	var exe_quoted: String = '"%s"' % exe_abs

	var content: String = "".join([
		"@echo off\r\n",
		"setlocal enableextensions\r\n",
		"set PID=%d\r\n" % pid,
		"set ZIP=%s\r\n" % zip_quoted,
		"set STAGE=%s\r\n" % stage_quoted,
		"set INSTALL=%s\r\n" % install_quoted,
		"set EXE=%s\r\n" % exe_quoted,
		"\r\n",
		":wait\r\n",
		"tasklist /FI \"PID eq %PID%\" 2>NUL | find /I \"%PID%\" >NUL\r\n",
		"if not errorlevel 1 (\r\n",
		"  timeout /t 1 /nobreak >NUL\r\n",
		"  goto wait\r\n",
		")\r\n",
		"\r\n",
		"if exist %STAGE% rmdir /s /q %STAGE%\r\n",
		"mkdir %STAGE%\r\n",
		"powershell -NoProfile -Command \"Expand-Archive -Force '%ZIP%' '%STAGE%'\"\r\n",
		"for /d %%D in (%STAGE%\\*) do set ROOT=%%D\r\n",
		"if \"%ROOT%\"==\"\" set ROOT=%STAGE%\r\n",
		"robocopy %ROOT% %INSTALL% /E /NFL /NDL /NJH /NJS /NP >NUL\r\n",
		"start \"\" %EXE%\r\n",
		"exit /b 0\r\n",
	])

	_write_text_file(script_abs, content)
	OS.create_process("cmd.exe", ["/C", script_abs])
	get_tree().quit()


func _apply_linux(pid: int, exe_abs: String) -> void:
	# Prefer swapping the current AppImage file (when running as AppImage).
	# If running from an extracted folder, exe_abs points to the binary and we just replace it in-place.
	var target_abs: String = exe_abs
	var new_abs: String = _downloaded_asset_abs
	var script_abs: String = _download_dir_abs.path_join("apply_update.sh")

	var content: String = "".join([
		"#!/usr/bin/env sh\n",
		"set -eu\n",
		"PID=%d\n" % pid,
		"TARGET=\"%s\"\n" % target_abs.replace("\"", "\\\""),
		"NEW=\"%s\"\n" % new_abs.replace("\"", "\\\""),
		"\n",
		"while kill -0 \"$PID\" 2>/dev/null; do sleep 0.2; done\n",
		"\n",
		"chmod +x \"$NEW\"\n",
		"if [ -f \"$TARGET\" ]; then\n",
		"  mv \"$TARGET\" \"$TARGET.bak\" 2>/dev/null || true\n",
		"fi\n",
		"mv \"$NEW\" \"$TARGET\"\n",
		"chmod +x \"$TARGET\"\n",
		"\n",
		"\"$TARGET\" &\n",
	])

	_write_text_file(script_abs, content)
	OS.execute("chmod", ["+x", script_abs])
	OS.create_process("sh", [script_abs])
	get_tree().quit()


func _on_check_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		update_error.emit("update_check_http_failed result=%d code=%d" % [result, response_code])
		return

	var text: String = body.get_string_from_utf8()
	var json: Variant = JSON.parse_string(text)
	if typeof(json) != TYPE_DICTIONARY:
		update_error.emit("update_check_invalid_json")
		return

	var data: Dictionary = json as Dictionary
	var tag_name: String = (data.get("tag_name", "") as String)
	_latest_version = tag_name

	var assets: Array = data.get("assets", []) as Array
	_select_assets(assets)

	update_checked.emit(_is_update_available(), _current_version, _latest_version)


func _select_assets(assets: Array) -> void:
	_asset_name = ""
	_asset_url = ""
	_checksums_url = ""

	for a: Variant in assets:
		if typeof(a) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = a as Dictionary
		var name: String = d.get("name", "") as String
		var url: String = d.get("browser_download_url", "") as String
		if name == "SHA256SUMS.txt":
			_checksums_url = url
			continue

	var want_appimage: bool = OS.get_name() == "Linux"
	var win_suffix: String = "_windows_x86_64.zip"
	var linux_zip_suffix: String = "_linux_x86_64.zip"
	var linux_appimage_suffix: String = "_linux_x86_64.AppImage"

	for a2: Variant in assets:
		if typeof(a2) != TYPE_DICTIONARY:
			continue
		var d2: Dictionary = a2 as Dictionary
		var name2: String = d2.get("name", "") as String
		var url2: String = d2.get("browser_download_url", "") as String
		if want_appimage and name2.ends_with(linux_appimage_suffix):
			_asset_name = name2
			_asset_url = url2
			return
		if OS.get_name() == "Windows" and name2.ends_with(win_suffix):
			_asset_name = name2
			_asset_url = url2
			return
		if OS.get_name() == "Linux" and name2.ends_with(linux_zip_suffix):
			_asset_name = name2
			_asset_url = url2
			return


func _on_download_request_progress(downloaded: int, total: int) -> void:
	update_download_progress.emit(downloaded, total)


func _on_download_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	_body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		update_error.emit(
			"update_download_http_failed step=%d result=%d code=%d" % [_download_step, result, response_code]
		)
		_download_step = DownloadStep.NONE
		_progress_timer.stop()
		return

	if _download_step == DownloadStep.CHECKSUMS:
		_downloaded_asset_abs = _download_dir_abs.path_join(_asset_name)
		_download_request.download_file = _downloaded_asset_abs
		_download_step = DownloadStep.ASSET
		var headers: Array[String] = ["User-Agent: NeonSurvivorUpdateManager"]
		var err: int = _download_request.request(_asset_url, headers)
		if err != OK:
			update_error.emit("update_download_asset_failed err=%d" % err)
			_download_step = DownloadStep.NONE
			_progress_timer.stop()
		return

	if _download_step == DownloadStep.ASSET:
		_download_step = DownloadStep.NONE
		_progress_timer.stop()
		if not _verify_downloaded_asset():
			return
		update_ready.emit(_latest_version)


func _on_progress_timer_timeout() -> void:
	var path_abs: String = _download_request.download_file
	if path_abs.is_empty() or not FileAccess.file_exists(path_abs):
		return
	var f: FileAccess = FileAccess.open(path_abs, FileAccess.READ)
	if not f:
		return
	var size: int = f.get_length()
	update_download_progress.emit(size, 0)


func _verify_downloaded_asset() -> bool:
	if not FileAccess.file_exists(_downloaded_checksums_abs) or not FileAccess.file_exists(_downloaded_asset_abs):
		update_error.emit("update_missing_downloaded_files")
		return false

	var expected: String = _read_expected_sha256(_downloaded_checksums_abs, _asset_name)
	if expected.is_empty():
		update_error.emit("update_missing_checksum_entry")
		return false

	var actual: String = _sha256_file_hex(_downloaded_asset_abs)
	if actual.is_empty():
		update_error.emit("update_checksum_compute_failed")
		return false

	if actual.to_lower() != expected.to_lower():
		update_error.emit("update_checksum_mismatch")
		return false

	return true


func _read_expected_sha256(checksums_abs: String, wanted_name: String) -> String:
	var f: FileAccess = FileAccess.open(checksums_abs, FileAccess.READ)
	if not f:
		return ""
	while not f.eof_reached():
		var line: String = f.get_line().strip_edges()
		if line.is_empty():
			continue
		# Format: <sha>  <filename>
		var parts: PackedStringArray = line.split(" ", false)
		if parts.size() < 2:
			continue
		var sha: String = parts[0]
		var name: String = parts[parts.size() - 1]
		if name == wanted_name:
			return sha
	return ""


func _sha256_file_hex(path_abs: String) -> String:
	var f: FileAccess = FileAccess.open(path_abs, FileAccess.READ)
	if not f:
		return ""
	var ctx: HashingContext = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)

	while true:
		var chunk: PackedByteArray = f.get_buffer(1024 * 1024)
		if chunk.is_empty():
			break
		ctx.update(chunk)

	var hash: PackedByteArray = ctx.finish()
	return hash.hex_encode()


func _is_update_available() -> bool:
	if _latest_version.is_empty():
		return false
	return _compare_versions(_latest_version, _current_version) > 0


func get_current_version() -> String:
	return _current_version


func get_latest_version() -> String:
	return _latest_version


func _get_current_version() -> String:
	return (ProjectSettings.get_setting("application/config/version", "0.0.0") as String)


func _get_repo_owner() -> String:
	return (ProjectSettings.get_setting("application/config/update_owner", "") as String)


func _get_repo_name() -> String:
	return (ProjectSettings.get_setting("application/config/update_repo", "") as String)


func _is_config_missing() -> bool:
	return _get_repo_owner().is_empty() or _get_repo_name().is_empty()


static func _compare_versions(a: String, b: String) -> int:
	# Accepts tags like v1.2.3 or 1.2.3-rc.1 (suffix ignored).
	var va: PackedInt32Array = _parse_version_triplet(a)
	var vb: PackedInt32Array = _parse_version_triplet(b)

	for i: int in 3:
		if va[i] > vb[i]:
			return 1
		if va[i] < vb[i]:
			return -1
	return 0


static func _parse_version_triplet(v: String) -> PackedInt32Array:
	var s: String = v.strip_edges()
	if s.begins_with("v") or s.begins_with("V"):
		s = s.substr(1)
	if s.find("-") >= 0:
		s = s.split("-", false)[0]

	var parts: PackedStringArray = s.split(".", false)
	var out: PackedInt32Array = PackedInt32Array([0, 0, 0])

	for i: int in min(3, parts.size()):
		var p: String = parts[i]
		var num: int = 0
		# Parse leading digits only.
		for j: int in p.length():
			var c: String = p[j]
			if c < "0" or c > "9":
				break
			num = int(p.substr(0, j + 1))
		out[i] = num
	return out


static func _sanitize_filename(name: String) -> String:
	var out: String = ""
	for i: int in name.length():
		var c: String = name[i]
		if (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9"):
			out += c
			continue
		if c in ["-", "_", ".", "+"]:
			out += c
			continue
		out += "_"
	if out.is_empty():
		return "update"
	return out


func _write_text_file(path_abs: String, content: String) -> void:
	var f: FileAccess = FileAccess.open(path_abs, FileAccess.WRITE)
	if not f:
		update_error.emit("update_write_failed path=%s" % path_abs)
		return
	f.store_string(content)
