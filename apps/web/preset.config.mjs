import 'dotenv/config';

const config = {
  enableIndexedDBProvider: Boolean(process.env.ENABLE_IDB_PROVIDER ?? '1'),
  enableBroadCastChannelProvider: Boolean(
    process.env.ENABLE_BC_PROVIDER ?? '1'
  ),
  prefetchWorkspace: Boolean(process.env.PREFETCH_WORKSPACE ?? '1'),
  exposeInternal: Boolean(process.env.EXPOSE_INTERNAL ?? '1'),
  enableDebugPage: Boolean(process.env.ENABLE_DEBUG_PAGE ?? false),
};
export default config;
