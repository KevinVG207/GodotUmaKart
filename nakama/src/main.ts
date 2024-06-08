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
    // let matchType = envelope.matchmakerAdd.stringProperties["matchType"];
    // let query = envelope.matchmakerAdd.query;
    // if (!matchType) {
    //     matchType = "race";
    //     envelope.matchmakerAdd.stringProperties["matchType"] = matchType;
    // }

    // if (query == "*") {
    //     query = "";
    // }

    // query += " +matchType:" + matchType;
    // // Strip whitespace
    // query = query.trim();
    // envelope.matchmakerAdd.query = query;
    // logger.debug("Matchmaker add query: %q", query);

    return envelope;
};


const onMatchmakerMatched: nkruntime.MatchmakerMatchedFunction = function (context: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, matches: nkruntime.MatchmakerResult[]): string {
    matches.forEach(function (match) {
        logger.info("Matched user '%s' named '%s'", match.presence.userId, match.presence.username);

        Object.keys(match.properties).forEach(function (key) {
            logger.info("Matched on '%s' value '%v'", key, match.properties[key])
        });
    });

    const serializedMatches = matches.map(match => ({
        presence: match.presence,
        properties: JSON.parse(JSON.stringify(match.properties))  // This will throw an error if properties are not serializable
    }));

    try {
        const matchId = nk.matchCreate("race", { invited: serializedMatches });
        return matchId;
    } catch (err) {
        logger.error(`${err}`);
        throw (err);
    }
};