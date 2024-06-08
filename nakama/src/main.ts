function InitModule(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer) {
    initializer.registerRpc("healthcheck", rpcHealthCheck);

    initializer.registerMatchmakerMatched(onMatchmakerMatched);

    initializer.registerMatch('race', {
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
    let query = envelope.matchmakerAdd.query;
    if (!matchType) {
        matchType = "race";
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
}


const onMatchmakerMatched: nkruntime.MatchmakerMatchedFunction = function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, matches: nkruntime.MatchmakerResult[]): string | void {
    logger.debug("Matchmaker matched %d matches", matches.length);
    const matchType: string = matches[0].properties.matchType as string;
    const matchId = nk.matchCreate("race", { "invited": matches })
    return matchId;
};