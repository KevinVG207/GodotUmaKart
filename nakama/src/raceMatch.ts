enum raceOp {
    SERVER_UPDATE_VEHICLE_STATE = 1,
    CLIENT_UPDATE_VEHICLE_STATE = 2,
    SERVER_PING = 3,
    CLIENT_VOTE = 4,
    SERVER_PING_DATA = 5,
	SERVER_RACE_START = 6,
    CLIENT_READY = 7,
    SERVER_RACE_OVER = 8
}

const raceMatchInit = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, params: { [key: string]: string }): { state: nkruntime.MatchState, tickRate: number, label: string } {
    // logger.debug("Matchinit");

    logger.debug("Inside Matchinit. MatchType: " + params.matchType)

    var tickRate = 20;
    var emptyTimeout = 60 * tickRate;

    let label: label = {
        matchType: params.matchType,
        joinable: 0,
        players: 0,
        maxPlayers: 12,
    }

    logger.info("Starting IDs: " + params.startingIds)

    return {
        state: {
            presences: {},
            emptyTicks: 0,
            tickRate: tickRate,
            emptyTimeout: emptyTimeout,
            vehicles: {},
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
            finishTimeout: tickRate * 60 * 6
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

    if (!state.startingIds.includes(presence.userId)) {
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
        state.vehicles[p.userId] = {};
        state.pingData[p.userId] = {
            lastPings: [],
            ongoingPings: {},
            ping: 0
        };
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
        updateLabel(state, dispatcher)
    });

    return {
        state
    };
}

const raceMatchLoop = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, messages: nkruntime.MatchMessage[]): { state: nkruntime.MatchState } | null {
    // logger.info("Match loop " + state.emptyTicks);
    // logger.info("Amount of presences: " + Object.keys(state.presences).length)

    // If we have no presences in the match according to the match state, increment the empty ticks count
    if (Object.keys(state.presences).length === 0) {
        state.emptyTicks++;
    } else {
        state.emptyTicks = 0;
    }

    // If the match has been empty for more than 100 ticks, end the match by returning null
    if (state.emptyTicks > state.emptyTimeout) {
        return null;
    }

    if (state.finished || tick >= state.finishTimeout) {
        logger.info(`${state.finished}`)
        logger.info(`${state.finishTimeout}`)
        // Start a new lobby.
        // Signal finish to all presences, with the next lobby match ID.

        var matchId = nk.matchCreate('lobby', {matchType: 'lobby', nextMatchType: state.label.matchType})
        dispatcher.broadcastMessage(raceOp.SERVER_RACE_OVER, JSON.stringify({ matchId: matchId, playerCount: Object.keys(state.presences).length }), null, null);

        return null;
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

                state.vehicles[message.sender.userId] = data;
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
        }


    // Finishing
    if (state.started){
        let oneFinished = false;
        let finished = true;
        logger.info("Finish check");
        logger.info(`${Object.keys(state.vehicles)}`)
        for (let userId in state.vehicles){
            let vehicle = state.vehicles[userId];
            logger.info(`${userId}`);
            // logger.info(`${vehicle}`);
            for (let key in vehicle){
                logger.info(`${key}: ${vehicle[key]}`);
            }
            if (vehicle.finished == true){
                oneFinished = true;
            } else {
                finished = false;
            }
        }

        if (oneFinished && !state.oneFinished) {
            // This is the first time a vehicle finishes.
            state.finishTimeout = tick + ctx.matchTickRate * 30;
        }

        state.oneFinished = oneFinished;
        state.finished = finished;
    }

        dispatcher.broadcastMessage(raceOp.SERVER_PING, JSON.stringify({ pings: pingDict }), null, null);
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