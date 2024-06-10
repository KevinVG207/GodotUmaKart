interface label {
    matchType: string;
    joinable: number;
    players: number;
}

function updateLabel(state: nkruntime.MatchState, dispatcher: nkruntime.MatchDispatcher) {
    let label: label = state.label;
    label.players = Object.keys(state.presences).length;
    dispatcher.matchLabelUpdate(JSON.stringify(label));
}