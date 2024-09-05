function InitModule(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer) {
    initializer.registerRpc("healthcheck", rpcHealthCheck);
    initializer.registerRpc("updateDisplayName", rpcUpdateDisplayName);
    initializer.registerRpc("getDisplayName", rpcGetDisplayName);

    initializer.registerMatchmakerMatched(onMatchmakerMatched);

    initializer.registerMatch("lobby", {
        matchInit: lobbyMatchInit,
        matchJoinAttempt: lobbyMatchJoinAttempt,
        matchJoin: lobbyMatchJoin,
        matchLeave: lobbyMatchLeave,
        matchLoop: lobbyMatchLoop,
        matchSignal: lobbyMatchSignal,
        matchTerminate: lobbyMatchTerminate
    });

    initializer.registerMatch("race", {
        matchInit: raceMatchInit,
        matchJoinAttempt: raceMatchJoinAttempt,
        matchJoin: raceMatchJoin,
        matchLeave: raceMatchLeave,
        matchLoop: raceMatchLoop,
        matchSignal: raceMatchSignal,
        matchTerminate: raceMatchTerminate
    });

    logger.info("Hello, World!");
}

const beforeMatchmakerAdd: nkruntime.RtBeforeHookFunction<nkruntime.EnvelopeMatchmakerAdd> = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, envelope: nkruntime.EnvelopeMatchmakerAdd): nkruntime.EnvelopeMatchmakerAdd | void {
    let matchType = envelope.matchmakerAdd.stringProperties["matchType"];
    let version = envelope.matchmakerAdd.stringProperties["version"];

    if (!version) {
        version = "0.0.0";
        envelope.matchmakerAdd.stringProperties["version"] = version;
    }

    let query = envelope.matchmakerAdd.query;
    if (!matchType) {
        matchType = "lobby";
        envelope.matchmakerAdd.stringProperties["matchType"] = matchType;
    }

    if (query == "*") {
        query = "";
    }

    query += " +matchType:" + matchType;
    // Strip whitespace
    query = query.trim();
    envelope.matchmakerAdd.query = query;
    logger.debug("Matchmaker add query: %q", query);

    return envelope;
};


const onMatchmakerMatched: nkruntime.MatchmakerMatchedFunction = function (context: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, matches: nkruntime.MatchmakerResult[]): string {
    let matchType: string = matches[0].properties["matchType"];
    let nextMatchType: string = matches[0].properties["nextMatchType"] || "race";
    let version: string = matches[0].properties["version"] || "0.0.0";

    const matchId = nk.matchCreate(matchType, {matchType: matchType, nextMatchType: nextMatchType, version: version});
    return matchId;
};