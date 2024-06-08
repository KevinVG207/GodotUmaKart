enum raceOp {
    SERVER_UPDATE_VEHICLE_STATE = 1,
    CLIENT_UPDATE_VEHICLE_STATE = 2,
}

const raceMatchInit = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, params: { [key: string]: string }): { state: nkruntime.MatchState, tickRate: number, label: string } {
    logger.debug("Matchinit");

    return {
        state: { presences: {}, emptyTicks: 0, vehicles: {} },
        tickRate: 10, // 1 tick per second = 1 MatchLoop func invocations per second
        label: ''
    };
};

const raceMatchJoinAttempt = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, presence: nkruntime.Presence, metadata: { [key: string]: any }): { state: nkruntime.MatchState, accept: boolean, rejectMessage?: string | undefined } | null {
    logger.debug("MatchJoinAttempt", presence.userId);

    return {
        state,
        accept: true
    };
}

const raceMatchJoin = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, presences: nkruntime.Presence[]): { state: nkruntime.MatchState } | null {
    presences.forEach(function (p) {
        state.presences[p.sessionId] = p;
        state.vehicles[p.sessionId] = {};
        logger.debug("%q joined match", p.userId);
    });

    return {
        state
    };
}

const raceMatchLeave = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, presences: nkruntime.Presence[]): { state: nkruntime.MatchState } | null {
    presences.forEach(function (p) {
        delete state.presences[p.sessionId];
        delete state.vehicles[p.sessionId];
        logger.debug("%q left match", p.userId);
    });

    return {
        state
    };
}

const raceMatchLoop = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, messages: nkruntime.MatchMessage[]): { state: nkruntime.MatchState } | null {
    logger.debug("Match loop");

    // If we have no presences in the match according to the match state, increment the empty ticks count
    if (state.presences.length === 0) {
        state.emptyTicks++;
    }

    // If the match has been empty for more than 100 ticks, end the match by returning null
    if (state.emptyTicks > 100) {
        return null;
    }

    // Loop over all messages received by the match
    messages.forEach(function (message) {
        // Extract the operation code and payload from the message
        const opCode = message.opCode;
        const payload = message.data;

        // Handle the operation code
        switch (opCode) {
            case raceOp.CLIENT_UPDATE_VEHICLE_STATE:
                const updateVehicleState = JSON.parse(String.fromCharCode.apply(null, new Uint8Array(payload) as any) as string);
                state.vehicles[message.sender.userId] = updateVehicleState;
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
    logger.debug('Lobby match signal received: ' + data);

    return {
        state,
        data: "Lobby match signal received: " + data
    };
}

const raceMatchTerminate = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, graceSeconds: number): { state: nkruntime.MatchState } | null {
    logger.debug('Lobby match terminated');

    return {
        state
    };
}