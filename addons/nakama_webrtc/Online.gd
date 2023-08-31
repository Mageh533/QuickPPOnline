extends Node

# For developers to set from the outside, for example:
#   Online.nakama_host = 'nakama.example.com'
#   Online.nakama_scheme = 'https'
var nakama_server_key: String = 'defaultkey'
var nakama_host: String = 'localhost'
var nakama_port: int = 7350
var nakama_scheme: String = 'http'

# For other scripts to access:
var _nakama_client: NakamaClient
var nakama_client: NakamaClient:
	set (value):
		pass
	get:
		return get_nakama_client()

var _nakama_session: NakamaSession
var nakama_session: NakamaSession:
	set (value):
		set_nakama_session(value)
	get:
		return _nakama_session

var _nakama_socket
var nakama_socket: NakamaSocket:
	set (value):
		pass
	get:
		return _nakama_socket

# Internal variable for initializing the socket.
var _nakama_socket_connecting := false

signal session_changed (nakama_session)
signal session_connected (nakama_session)
signal socket_connected (nakama_socket)

func get_nakama_client() -> NakamaClient:
	if _nakama_client == null:
		_nakama_client = Nakama.create_client(
			nakama_server_key,
			nakama_host,
			nakama_port,
			nakama_scheme,
			Nakama.DEFAULT_TIMEOUT,
			NakamaLogger.LOG_LEVEL.DEBUG)
	
	return _nakama_client

func set_nakama_session(p_nakama_session: NakamaSession) -> void:
	# Close out the old socket.
	if _nakama_socket:
		_nakama_socket.close()
		_nakama_socket = null
	
	_nakama_session = p_nakama_session
	
	emit_signal("session_changed", _nakama_session)
	
	if _nakama_session and not _nakama_session.is_exception() and not _nakama_session.is_expired():
		emit_signal("session_connected", _nakama_session)

func connect_nakama_socket() -> void:
	if _nakama_socket != null:
		return
	if _nakama_socket_connecting:
		return
	_nakama_socket_connecting = true
	
	var new_socket = Nakama.create_socket_from(_nakama_client)
	await new_socket.connect_async(_nakama_session)
	_nakama_socket = new_socket
	_nakama_socket_connecting = false
	
	emit_signal("socket_connected", _nakama_socket)

func is_nakama_socket_connected() -> bool:
	return _nakama_socket != null && _nakama_socket.is_connected_to_host()
