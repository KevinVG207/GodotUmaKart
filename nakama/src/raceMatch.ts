enum raceOp {
    SERVER_UPDATE_VEHICLE_STATE = 1,
    CLIENT_UPDATE_VEHICLE_STATE = 2,
}

const raceMatchInit = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, params: { [key: string]: string }): { state: nkruntime.MatchState, tickRate: number, label: string } {
    // logger.debug("Matchinit");

    logger.debug("Inside Matchinit. MatchType: " + params.matchType)

    var tickRate = 10;
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
            startingIds: JSON.parse(params.startingIds) as string[]
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
        state.presences[p.sessionId] = p;
        state.vehicles[p.sessionId] = {};
        updateLabel(state, dispatcher)
    });

    return {
        state
    };
}

const raceMatchLeave = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, presences: nkruntime.Presence[]): { state: nkruntime.MatchState } | null {
    presences.forEach(function (p) {
        delete state.presences[p.sessionId];
        delete state.vehicles[p.sessionId];
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

    // Loop over all messages received by the match
    messages.forEach(function (message) {
        // Extract the operation code and payload from the message
        const opCode = message.opCode;
        const payload = message.data;
        const data = JSON.parse(String.fromCharCode.apply(null, new Uint8Array(payload) as any) as string);
        const presence = message.sender;

        if (!(presence.sessionId in state.presences)) {
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
            default:
                logger.warn("Unrecognized operation code", opCode);
                break;
        }
    });

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