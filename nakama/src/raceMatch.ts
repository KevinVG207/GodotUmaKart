enum raceOp {
    SERVER_UPDATE_VEHICLE_STATE = 1,
    CLIENT_UPDATE_VEHICLE_STATE = 2,
    SERVER_PING = 3,
    CLIENT_VOTE = 4,
    SERVER_PING_DATA = 5,
	SERVER_RACE_START = 6,
    CLIENT_READY = 7,
    SERVER_RACE_OVER = 8,
    SERVER_CLIENT_DISCONNECT = 9,
    SERVER_ABORT = 10,
    CLIENT_SPAWN_ITEM = 11,
    CLIENT_DESTROY_ITEM = 12,
    SERVER_SPAWN_ITEM = 13,
    SERVER_DESTROY_ITEM = 14,
    CLIENT_ITEM_STATE = 15,
    SERVER_ITEM_STATE = 16,
    SERVER_PING_UPDATE = 17
}


enum finishType {
    NORMAL = 0,
    TIMEOUT = 1
}

interface PhysicalItem {
    uniqueId: string;
    ownerId: string;
    type: string;
    state: any;
}


const raceMatchInit = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, params: { [key: string]: string }): { state: nkruntime.MatchState, tickRate: number, label: string } {
    // logger.debug("Matchinit");

    logger.debug("Inside Matchinit. MatchType: " + params.matchType)

    var tickRate = 20;
    var emptyTimeout = 60 * tickRate;
    var finishTimeout = tickRate * 60 * 30;  // 30 minutes for testing. 6 minutes for production
    
    var course: string = JSON.parse(params.winningVote).course;

    let label: label = {
        matchType: params.matchType,
        joinable: 0,
        players: 0,
        maxPlayers: 12,
        course: course
    }

    let userData = {} as { [key: string]: any };

    logger.info("Starting IDs: " + params.startingIds)

    return {
        state: {
            stop: 0,
            course: course,
            presences: {},
            userData: {},
            emptyTicks: 0,
            tickRate: tickRate,
            emptyTimeout: emptyTimeout,
            vehicles: {},
            physicalItems: {},
            destroyedItems: [],
            started: false,
            label: label,
            startingIds: JSON.parse(params.startingIds) as string[],
            pingData: {},
            startTick: -1,
            pingAtStart: {},
            readyUsers: [],
            ready: false,
            oneFinished: false,
            finished: false,
            finishTimeout: finishTimeout
        },
        tickRate: tickRate,
        label: '{}'
    };
};

const raceMatchJoinAttempt = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, presence: nkruntime.Presence, metadata: { [key: string]: any }): { state: nkruntime.MatchState, accept: boolean, rejectMessage?: string | undefined } | null {
    // logger.debug("MatchJoinAttempt", presence.userId);

    if (state.players >= state.maxPlayers) {
        return {
            state,
            accept: false,
            rejectMessage: "Match is full"
        };
    }

    if (!state.started && !state.startingIds.includes(presence.userId)) {
        return {
            state,
            accept: false,
            rejectMessage: "User not in starting list"
        };
    }

    return {
        state,
        accept: true
    };
}

const raceMatchJoin = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, presences: nkruntime.Presence[]): { state: nkruntime.MatchState } | null {
    presences.forEach(function (p) {
        state.presences[p.userId] = p;

        if (!state.started){
            state.vehicles[p.userId] = {};
        }

        state.userData[p.userId] = nk.accountGetId(p.userId).user.metadata;
        
        updateLabel(state, dispatcher)
    });

    return {
        state
    };
}

const raceMatchLeave = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, presences: nkruntime.Presence[]): { state: nkruntime.MatchState } | null {
    presences.forEach(function (p) {
        delete state.presences[p.userId];
        delete state.vehicles[p.userId];
        delete state.pingData[p.userId];
        updateLabel(state, dispatcher)
        dispatcher.broadcastMessage(raceOp.SERVER_CLIENT_DISCONNECT, JSON.stringify({ userId: p.userId }), null, null);
    });

    return {
        state
    };
}

const raceMatchLoop = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, messages: nkruntime.MatchMessage[]): { state: nkruntime.MatchState } | null {
    // logger.info("Match loop " + state.emptyTicks);
    // logger.info("Amount of presences: " + Object.keys(state.presences).length)

    // If we have no presences in the match according to the match state, increment the empty ticks count
    if (state.stop) {
        if (tick >= state.stop) {
            return null;
        }
        return {state};
    }

    if (Object.keys(state.presences).length === 0) {
        state.emptyTicks++;
    } else {
        state.emptyTicks = 0;
    }

    // If the match has been empty for more than 100 ticks, end the match by returning null
    if (state.emptyTicks > state.emptyTimeout) {
        return null;
    }

    if (state.started && Object.keys(state.vehicles).length <= 1) {
        // Race can't continue with less than 2 players
        // dispatcher.broadcastMessage(raceOp.SERVER_ABORT, JSON.stringify({}), null, null);
        // state.stop = tick + ctx.matchTickRate * 5;
        // return {state};
        state.finished = true;
    }

    if (state.finished || tick >= state.finishTimeout) {
        var finType = finishType.NORMAL;

        if (tick >= state.finishTimeout) {
            finType = finishType.TIMEOUT;
        }

        var finishOrder = determineFinishOrder(state, logger);
        logger.info("Finish order: " + finishOrder)
        // Start a new lobby.
        // Signal finish to all presences, with the next lobby match ID.

        var matchId = nk.matchCreate('lobby', {
            matchType: 'lobby',
            nextMatchType: state.label.matchType,
            fromMatch: JSON.stringify(state.presences),
            finishOrder: JSON.stringify(finishOrder)
        });

        dispatcher.broadcastMessage(raceOp.SERVER_RACE_OVER, JSON.stringify({
            matchId: matchId,
            playerCount: Object.keys(state.presences).length,
            finishType: finType,
            finishOrder: finishOrder
        }), null, null);

        state.stop = tick + ctx.matchTickRate * 5;
        return {state};
    }

    pingUsers(raceOp.SERVER_PING, tick, ctx, state, dispatcher);

    // Loop over all messages received by the match
    messages.forEach(function (message) {
        // Extract the operation code and payload from the message
        const opCode = message.opCode;
        const payload = message.data;
        const data = JSON.parse(String.fromCharCode.apply(null, new Uint8Array(payload) as any) as string);
        const presence = message.sender;

        if (!(presence.userId in state.presences)) {
            return;
        }

        // Handle the operation code
        switch (opCode) {
            case raceOp.CLIENT_UPDATE_VEHICLE_STATE:
                // Ignore old state updates
                if (message.sender.userId in state.vehicles) {
                    if (state.vehicles[message.sender.userId].idx >= data.idx) {
                        break;
                    }
                }

                if (!state.startingIds.includes(message.sender.userId)) {
                    // Ignore updates from users not in the starting list
                    break;
                }

                state.vehicles[message.sender.userId] = data;
                state.vehicles[message.sender.userId].userId = message.sender.userId;
                dispatcher.broadcastMessage(raceOp.SERVER_UPDATE_VEHICLE_STATE, payload, null, message.sender);
                break;
            case raceOp.SERVER_PING:
                    handle_ping_message(message, data, presence, state, dispatcher);
                    break;
            case raceOp.CLIENT_READY:
                if (!state.readyUsers.includes(presence.userId)) {
                    state.readyUsers.push(presence.userId);
                }

                if (state.readyUsers.length === Object.keys(state.presences).length) {
                    state.ready = true;
                }
                break;
            case raceOp.CLIENT_SPAWN_ITEM:
                handle_spawn_item(message, data, state, dispatcher, logger);
                break;
            case raceOp.CLIENT_DESTROY_ITEM:
                handle_destroy_item(message, data, state, dispatcher, logger);
                break;
            case raceOp.CLIENT_ITEM_STATE:
                handle_item_state(message, data, state, dispatcher, logger);
                break;
            default:
                logger.warn("Unrecognized operation code", opCode);
                break;
        }
    });

    // Every half
    if (tick % Math.floor(ctx.matchTickRate / 2) === 0) {
        var pingDict: { [key: string]: number; } = {};

        var ready = true;

        for (let userId in state.pingData) {
            pingDict[userId] = state.pingData[userId].ping;
            if (state.pingData[userId].lastPings.length < 5) {
                ready = false;
            }
        }

        if (!state.started && ready && state.ready) {
            // Start the race!
            state.started = true;

            var highest_ping = 0;
            for (let userId in state.pingData) {
                if (state.pingData[userId].ping > highest_ping) {
                    highest_ping = state.pingData[userId].ping;
                }
            }

            var ticksToStart = Math.ceil(((highest_ping / 1000.0) + 1) * ctx.matchTickRate);
            state.pingAtStart = pingDict;

            dispatcher.broadcastMessage(raceOp.SERVER_RACE_START, JSON.stringify({ pings: pingDict, ticksToStart: ticksToStart, tickRate: ctx.matchTickRate }), null, null);
            state.label.joinable = 1;
            updateLabel(state, dispatcher);
        }


    // Finishing
    if (state.started){
        let oneFinished = false;
        let finished = true;
        // logger.info("Checking if all vehicles are finished")
        for (let userId in state.vehicles){
            let vehicle = state.vehicles[userId];
            // logger.info("Checking vehicle: " + userId + " finished: " + vehicle.finished)
            if (vehicle.finished == true){
                oneFinished = true;
            } else {
                finished = false;
            }
        }
        // logger.info("Finished: " + finished + " OneFinished: " + oneFinished)

        if (oneFinished && !state.oneFinished) {
            // This is the first time a vehicle finishes.
            state.joinable = 0;
            updateLabel(state, dispatcher);
            state.finishTimeout = tick + ctx.matchTickRate * 30;
        }

        state.oneFinished = oneFinished;
        state.finished = finished;
    }

        dispatcher.broadcastMessage(raceOp.SERVER_PING_UPDATE, JSON.stringify({ pings: pingDict }), null, null);
    }

    return {
        state
    };
}

const raceMatchSignal = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, data: string): { state: nkruntime.MatchState, data?: string } | null {
    // logger.debug('Lobby match signal received: ' + data);

    return {
        state,
        data: "Lobby match signal received: " + data
    };
}

const raceMatchTerminate = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, graceSeconds: number): { state: nkruntime.MatchState } | null {
    logger.info('Starting graceful termination');

    return {
        state
    };
}

function checkpointToProgress(vehicle: any){
    return 10000 * vehicle.lap + vehicle.check_idx + vehicle.check_progress;
}

function determineFinishOrder(state: nkruntime.MatchState, logger: nkruntime.Logger) {
    let finishedVehicles = [];
    let unfinishedVehicles = [];

    for (let userId in state.vehicles) {
        if (state.vehicles[userId].finished) {
            finishedVehicles.push(state.vehicles[userId]);
        } else {
            unfinishedVehicles.push(state.vehicles[userId]);
        }
    }

    finishedVehicles.sort(function (a, b) {
        return a.finish_time - b.finish_time;
    });

    // Print finish order
    for (let vehicle_data of finishedVehicles) {
        logger.info("Finished vehicle: " + state.presences[vehicle_data.userId].username + " with time: " + vehicle_data.finish_time);
    }

    unfinishedVehicles.sort(function (a, b) {
        return checkpointToProgress(b) - checkpointToProgress(a);
    });

    // Print unfinished vehicles
    for (let vehicle_data of unfinishedVehicles) {
        logger.info("Unfinished vehicle: " + state.presences[vehicle_data.userId].username + " with progress: " + checkpointToProgress(vehicle_data));
    }

    finishedVehicles = finishedVehicles.concat(unfinishedVehicles);

    let userIds = [];
    for (let vehicle_data of finishedVehicles) {
        userIds.push(vehicle_data.userId);
    }

    return userIds;
}

function handle_spawn_item(message: nkruntime.MatchMessage, data: any, state: nkruntime.MatchState, dispatcher: nkruntime.MatchDispatcher, logger: nkruntime.Logger) {
    let uniqueId = data.uniqueId;

    if (uniqueId in state.physicalItems) {
        return;
    }

    let item: PhysicalItem = {
        uniqueId: uniqueId,
        ownerId: message.sender.userId,
        type: data.type,
        state: data.state
    };

    state.physicalItems[uniqueId] = item;

    dispatcher.broadcastMessage(raceOp.SERVER_SPAWN_ITEM, JSON.stringify(item), null, null);
}

function handle_destroy_item(message: nkruntime.MatchMessage, data: any, state: nkruntime.MatchState, dispatcher: nkruntime.MatchDispatcher, logger: nkruntime.Logger) {
    let uniqueId = data.uniqueId;

    if (state.destroyedItems.includes(uniqueId)) {
        return;
    }

    if (uniqueId in state.physicalItems) {
        delete state.physicalItems[uniqueId];
        state.destroyedItems.push(uniqueId);
    }

    dispatcher.broadcastMessage(raceOp.SERVER_DESTROY_ITEM, JSON.stringify({ uniqueId: uniqueId }), null, null);
}

function handle_item_state(message: nkruntime.MatchMessage, data: any, state: nkruntime.MatchState, dispatcher: nkruntime.MatchDispatcher, logger: nkruntime.Logger) {
    let uniqueId = data.uniqueId;

    if (state.destroyedItems.includes(uniqueId)) {
        return;
    }

    if (uniqueId in state.physicalItems) {
        state.physicalItems[uniqueId].state = data.state;
        state.physicalItems[uniqueId].ownerId = message.sender.userId;
    }

    dispatcher.broadcastMessage(raceOp.SERVER_ITEM_STATE, JSON.stringify(state.physicalItems[uniqueId]), null, null);
}