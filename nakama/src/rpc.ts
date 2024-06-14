function rpcUpdateDisplayName(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;

    const displayName = payload;

    let metadata = nk.accountGetId(userId).user.metadata;

    metadata.displayName = displayName;

    nk.accountUpdateId(userId, null, null, null, null, null, null, metadata);

    return JSON.stringify({ success: true });
}

function rpcGetDisplayName(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;

    let metadata = nk.accountGetId(userId).user.metadata;

    return metadata.displayName;
}