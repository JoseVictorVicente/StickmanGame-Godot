class_name CombatEvent
extends RefCounted
## Domain combat event emitted by CombatSimulator (presentation-agnostic).

enum Kind {
	HERO_HIT_ENEMY,
	ENEMY_HIT_HERO,
	ENEMY_MEMBER_DIED,
	ENEMY_WAVE_CLEARED,
	PARTY_DEFEATED,
	PHASE_CHANGED,
	SWARM_ATTACK,
	MEMBER_PROMOTED,
	ENGAGED,
	SPAWN_WAVE,
}

var kind: Kind = Kind.HERO_HIT_ENEMY
var tick: int = 0
var payload: Dictionary = {}


static func make(kind: Kind, tick: int, payload: Dictionary = {}):
	var event := new()
	event.kind = kind
	event.tick = tick
	event.payload = payload.duplicate()
	return event
