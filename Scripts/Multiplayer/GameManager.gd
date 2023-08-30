extends Node

var secondPlayerId = 0
var currentSeed = 0

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket
var username = "Unknown"
var nMatch : NakamaRTAPI.Match
