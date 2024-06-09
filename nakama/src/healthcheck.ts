function rpcHealthCheck(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    logger.info("Health check");
    return JSON.stringify({ success: true });
}