function InitModule(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer) {
    initializer.registerRpc("healthcheck", rpcHealthCheck);

    initializer.registerMatch('race', {
        matchInit: raceMatchInit,
        matchJoinAttempt: raceMatchJoinAttempt,
        matchJoin: raceMatchJoin,
        matchLeave: raceMatchLeave,
        matchLoop: raceMatchLoop,
        matchSignal: raceMatchSignal,
        matchTerminate: raceMatchTerminate
    });
    // initializer.registerRtBefore("MatchmakerAdd", beforeMatchmakerAdd);
    initializer.registerMatchmakerMatched(onMatchmakerMatched);

    logger.info("Hello, World!");
}

const beforeMatchmakerAdd: nkruntime.RtBeforeHookFunction<nkruntime.EnvelopeMatchmakerAdd> = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, envelope: nkruntime.EnvelopeMatchmakerAdd): nkruntime.EnvelopeMatchmakerAdd | void {
    let matchType = envelope.matchmakerAdd.stringProperties["match_type"];
    let query = envelope.matchmakerAdd.query;
    if (!matchType) {
        matchType = "race";
    }

    if (query == "*") {
        query = "";
    }

    query += " +match_type:" + matchType;
    // Strip whitespace
    query = query.trim();
    envelope.matchmakerAdd.query = query;
    logger.debug("Matchmaker add query: %q", query);

    return envelope;
}

const onMatchmakerMatched: nkruntime.MatchmakerMatchedFunction = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, matches: nkruntime.MatchmakerResult[]): string | void {
    logger.debug("Matchmaker matched %d matches", matches.length);
    const matchType = matches[0].properties["match_type"];
    const matchId = nk.matchCreate(matchType, { "invited": matches })
    return matchId;
};