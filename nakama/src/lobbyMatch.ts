enum lobbyOp {
    CLIENT_VOTE = 1,
    SERVER_VOTE_DATA = 2,
    SERVER_MATCH_DATA = 3,
}


const lobbyMatchInit = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, params: { [key: string]: string }): { state: nkruntime.MatchState, tickRate: number, label: string } {
    // logger.debug("Matchinit");

    logger.debug("Inside Matchinit. MatchType: " + params.matchType)

    var tickRate = 3;

    let label: label = {
        matchType: params.matchType,
        joinable: 1,
        players: 0,
        maxPlayers: 12
    }

    let voteTimeout = 30 * tickRate;
    let joinTimeout = 20 * tickRate;

    return {
        state: {
            presences: {},
            emptyTicks: 0,
            nextMatchType: params.nextMatchType,
            votes: {},
            curTick: 0,
            voteTimeout: voteTimeout,
            joinTimeout: joinTimeout,
            expireTimeout: voteTimeout*2,
            label: label
        },
        tickRate: tickRate,
        label: '{}'
    };
};

const lobbyMatchJoinAttempt = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, presence: nkruntime.Presence, metadata: { [key: string]: any }): { state: nkruntime.MatchState, accept: boolean, rejectMessage?: string | undefined } | null {
    // logger.debug("MatchJoinAttempt", presence.userId);

    return {
        state,
        accept: true
    };
}

const lobbyMatchJoin = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, presences: nkruntime.Presence[]): { state: nkruntime.MatchState } | null {
    presences.forEach(function (p) {
        state.presences[p.userId] = p;
        updateLabel(state, dispatcher)
    });

    return {
        state
    };
}

const lobbyMatchLeave = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, presences: nkruntime.Presence[]): { state: nkruntime.MatchState } | null {
    presences.forEach(function (p) {
        delete state.presences[p.userId];
        delete state.votes[p.userId];
        updateLabel(state, dispatcher)
    });

    return {
        state
    };
}

const lobbyMatchLoop = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, messages: nkruntime.MatchMessage[]): { state: nkruntime.MatchState } | null {
    // logger.info("Match loop " + state.emptyTicks);
    // logger.info("Amount of presences: " + Object.keys(state.presences).length)

    state.curTick++;

    if (state.curTick > state.joinTimeout) {
        state.label.joinable = 0;
        updateLabel(state, dispatcher);
    }

    let trueVoteTimeout = state.voteTimeout + 5 * ctx.matchTickRate; // 5 seconds buffer

    if (state.curTick == trueVoteTimeout) {
        // Start the match
        
        // Kick users who haven't voted evern after grace period
        let presences = Object.keys(state.presences).map((key) => state.presences[key]);
        presences.forEach(function (p: nkruntime.Presence) {
            if (!(p.userId in state.votes)) {
                dispatcher.matchKick([p])
            }
        });

        // Pick a random user's vote.
        let keys = Object.keys(state.votes);
        let randomIndex = Math.floor(Math.random() * keys.length);
        let randomKey = keys[randomIndex];
        let randomVote = state.votes[randomKey];

        // Create a race match using this course
        let matchId = nk.matchCreate(state.nextMatchType, { matchType: state.nextMatchType, winningVote: randomVote });

        // Broadcast the new match to all presences
        dispatcher.broadcastMessage(lobbyOp.SERVER_MATCH_DATA, JSON.stringify({ matchId: matchId, winningVote: randomVote, voteUser: randomKey }), null, null);
    }

    if (state.curTick < trueVoteTimeout) {
        // Loop over all messages received by the match
        messages.forEach(function (message) {
            // Extract the operation code and payload from the message
            const opCode = message.opCode;
            const payload = message.data;
            const data = JSON.parse(nk.binaryToString(payload));
            const presence = message.sender;

            if (!(presence.userId in state.presences)) {
                return;
            }

            // Handle the operation code
            switch (opCode) {
                case lobbyOp.CLIENT_VOTE:
                    logger.info(`Receive time: ${message.receiveTimeMs}`);
                    state.votes[presence.userId] = data;
                    break;
                default:
                    logger.warn("Unrecognized operation code", opCode);
                    break;
            }
        });

        var vote_data = {
            votes: state.votes,
            presences: state.presences,
            curTick: state.curTick,
            voteTimeout: state.voteTimeout,
            tickRate: ctx.matchTickRate
        }

        // Broadcast all votes to all presences
        dispatcher.broadcastMessage(lobbyOp.SERVER_VOTE_DATA, JSON.stringify(vote_data), null, null);
    }

    if (state.curTick > state.expireTimeout) {
        return null;
    }

    return {
        state
    };
}

const lobbyMatchSignal = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, data: string): { state: nkruntime.MatchState, data?: string } | null {
    // logger.debug('Lobby match signal received: ' + data);

    return {
        state,
        data: "Lobby match signal received: " + data
    };
}

const lobbyMatchTerminate = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState, graceSeconds: number): { state: nkruntime.MatchState } | null {
    logger.info('Starting graceful termination');

    return {
        state
    };
}