interface label {
    matchType: string;
    joinable: number;
    players: number;
    maxPlayers: number;
}

const config = {
    maxPing: 1500
}

function updateLabel(state: nkruntime.MatchState, dispatcher: nkruntime.MatchDispatcher) {
    let label: label = state.label;
    label.players = Object.keys(state.presences).length;

    if (label.players >= label.maxPlayers) {
        label.joinable = 0;
    }

    dispatcher.matchLabelUpdate(JSON.stringify(label));
}