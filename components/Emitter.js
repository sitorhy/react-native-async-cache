import {NativeModules, NativeEventEmitter} from 'react-native';
import {isNull} from '../lib/common';

const {ReactNativeAsyncCache} = NativeModules;

const AsyncCacheEventEmitter = new NativeEventEmitter(ReactNativeAsyncCache);

export default class {
    bundles = [];

    constructor(event) {
        AsyncCacheEventEmitter.addListener(event, (event) => {
            const {url} = event;
            const bundle = this.bundles.find(i => i.url === url);
            if (bundle) {
                const {handlers} = bundle;
                handlers.forEach(pair => {
                    const nextData = this.handle(url, event, pair.handler);
                    if (!isNull(nextData)) {
                        pair.data = nextData;
                    }
                });
            }
        });
    }

    data() {
        return null;
    }

    handle() {
        return null;
    }

    add(url, handler) {
        let bundle = this.bundles.find(i => i.url === url);
        if (!bundle) {
            bundle = {
                handlers: [],
                url
            };
            this.bundles.push(bundle);
        }
        if (typeof handler === 'function') {
            bundle.handlers.push({
                handler,
                data: this.data()
            });
        }
    }

    remove(url, handler) {
        const index = this.bundles.findIndex(i => i.url === url);
        if (index >= 0) {
            const bundle = this.bundles[index];
            const hIndex = bundle.handlers.findIndex(h => h.handler === handler);
            if (hIndex >= 0) {
                bundle.handlers.splice(hIndex, 1);
            }
            if (bundle.handlers.length <= 0) {
                this.bundles.splice(index, 1);
            }
        }
    }
}