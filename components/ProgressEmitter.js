import Emitter from './Emitter';

export default new (class extends Emitter {
    data() {
        return {
            progress: 0.0,
            current: 0,
            total: 0
        };
    }

    handle(url, event, handler) {
        const {total, current, progress} = event;
        const nextProgress = total > 0 ? parseFloat((current / total).toFixed(2)) : 0;
        if (nextProgress !== progress) {
            handler(nextProgress, total, current, url);
            return {
                total,
                current,
                progress: nextProgress
            };
        }
    }
})('RNAsyncCacheProgress');
