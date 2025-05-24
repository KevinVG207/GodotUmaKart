extends Node

class_name DomainRace

class VehicleDataWrapper:
    var player: DomainPlayer.Player
    var vehicle_state: Dictionary

    func serialize() -> Array[Variant]:
        var list: Array[Variant] = []
        list.append(player.serialize())
        list.append(vehicle_state)
        return list
    
    static func deserialize(list: Array[Variant]) -> VehicleDataWrapper:
        var wrapper := VehicleDataWrapper.new()
        wrapper.player = DomainPlayer.Player.deserialize(list.pop_front())
        wrapper.vehicle_state = list.pop_front()
        return wrapper