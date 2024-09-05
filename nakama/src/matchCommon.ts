interface label {
    version: string;
    matchType: string;
    joinable: number;
    players: number;
    maxPlayers: number;
    course?: string;
}

interface userData {
    displayName: string;
    rating: number;
}

const config = {
    maxPing: 1000
}

function updateLabel(state: nkruntime.MatchState, dispatcher: nkruntime.MatchDispatcher) {
    let label: label = state.label;
    label.players = Object.keys(state.presences).length;

    if (label.players >= label.maxPlayers) {
        label.joinable = 0;
    }

    dispatcher.matchLabelUpdate(JSON.stringify(label));
}

function pingUsers(opCode: number, tick: number, ctx: nkruntime.Context, state: nkruntime.MatchState, dispatcher: nkruntime.MatchDispatcher) {
    if (tick % Math.floor(ctx.matchTickRate / 2) == 0) {
        for (let userId in state.presences) {
            let p = state.presences[userId];

            // Ping user
            let now = Date.now();
            let pingId = tick;

            if (!(p.userId in state.pingData)) {
                state.pingData[p.userId] = {
                    lastPings: [],
                    ongoingPings: {},
                    ping: 0
                };
            }

            state.pingData[p.userId].ongoingPings[pingId] = now;
            dispatcher.broadcastMessage(opCode, JSON.stringify({ pingId: pingId }), [p], null);
        }
    }
}

function handle_ping_message(message: nkruntime.MatchMessage, data: any, presence: nkruntime.Presence, state: nkruntime.MatchState, dispatcher: nkruntime.MatchDispatcher, noPings: number = 8) {
    let pingId = data.pingId;
    if (!(pingId in state.pingData[presence.userId].ongoingPings)) {
        return;
    }
    let receiveTimeMs = message.receiveTimeMs;
    let sendTimeMs = state.pingData[presence.userId].ongoingPings[pingId];
    delete state.pingData[presence.userId].ongoingPings[pingId];
    let ping = (receiveTimeMs - sendTimeMs) / 2;
    state.pingData[presence.userId].lastPings.push(ping);

    // Remove oldest ping if we have more than specified
    if (state.pingData[presence.userId].lastPings.length > noPings) {
        state.pingData[presence.userId].lastPings.shift();
    }

    let sum = 0;
    for (var i = 0; i < state.pingData[presence.userId].lastPings.length; i++) {
        sum += state.pingData[presence.userId].lastPings[i];
    }

    let avgPing = sum / state.pingData[presence.userId].lastPings.length;
    state.pingData[presence.userId].ping = avgPing;

    // Kick user if ping is too high
    if (state.pingData[presence.userId].length > Math.max(0, noPings-2) && avgPing > config.maxPing) {
        dispatcher.matchKick([presence]);
    }
}