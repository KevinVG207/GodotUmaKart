function InitModule(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer) {
    initializer.registerRpc("healthcheck", rpcHealthCheck);
    initializer.registerRpc("updateDisplayName", rpcUpdateDisplayName);
    initializer.registerRpc("getDisplayName", rpcGetDisplayName);
    initializer.registerRtBefore("MatchmakerAdd", beforeMatchmakerAdd);
    initializer.registerBeforeListMatches(beforeListMatches);

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

const beforeListMatches: nkruntime.BeforeHookFunction<nkruntime.ListMatchesRequest> = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, request: nkruntime.ListMatchesRequest): nkruntime.ListMatchesRequest | void {
    let query = "*";

    if (request?.query) {
        query = request.query;
    }

    if (query?.indexOf("+properties.version:") == -1) {
        query += " +properties.version:Unknown";
    }

    request.query = query.trim();

    return request;
}

const beforeMatchmakerAdd: nkruntime.RtBeforeHookFunction<nkruntime.EnvelopeMatchmakerAdd> = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, envelope: nkruntime.EnvelopeMatchmakerAdd): nkruntime.EnvelopeMatchmakerAdd | void {
    let matchType = envelope.matchmakerAdd.stringProperties["matchType"];
    let version = envelope.matchmakerAdd.stringProperties["version"];

    if (!version) {
        version = "Unknown";
        envelope.matchmakerAdd.stringProperties["version"] = version;
    }

    if (!matchType) {
        matchType = "lobby";
        envelope.matchmakerAdd.stringProperties["matchType"] = matchType;
    }

    let query = envelope.matchmakerAdd.query;
    if (query == "*") {
        query = "";
    }

    query += " +properties.matchType:" + matchType;
    query += " +properties.version:" + version;
    // Strip whitespace
    query = query.trim();
    envelope.matchmakerAdd.query = query;
    logger.debug("Matchmaker add query: %q", query);

    return envelope;
};


const onMatchmakerMatched: nkruntime.MatchmakerMatchedFunction = function (context: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, matches: nkruntime.MatchmakerResult[]): string {
    let matchType: string = matches[0].properties["matchType"];
    let nextMatchType: string = matches[0].properties["nextMatchType"] || "race";
    let version: string = matches[0].properties["version"] || "Unknown";

    const matchId = nk.matchCreate(matchType, {matchType: matchType, nextMatchType: nextMatchType, version: version});
    return matchId;
};