import Emitter from './Emitter';

export default new (class extends Emitter {
    handle(url, event, handler) {
        const {statusCode, message, path, size} = event;
        handler({statusCode, message, url, path, size});
    }
})('RNAsyncCachePosted');