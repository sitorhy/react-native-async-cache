import {randomNum} from "../lib/common";

export default class {
    constructor() {
        this.size = 768;
        this.caches = [];
        this.index = 0;
    }

    get(url) {
        const cache = this.caches.find((i) => i.url === url);
        return cache || null;
    }

    set(url, local) {
        if (typeof url === 'string' && url.startsWith('http') && typeof local === 'string' && local.startsWith('file')) {
            const cache = this.get(url);
            if (!cache) {
                if (this.caches.length === this.size) {
                    this.caches[randomNum(0, this.size - 1)] = {
                        url,
                        local,
                        message: null,
                        statusCode: null
                    };
                } else {
                    this.caches.push({
                        url,
                        local,
                        message: null,
                        statusCode: null
                    });
                }
            }
        }
    }

    error(url, statusCode, message = null) {
        const cache = this.get(url);
        if (!cache) {
            if (this.caches.length === this.size) {
                this.caches[randomNum(0, this.size - 1)] = {
                    url,
                    local: null,
                    statusCode,
                    message
                };
            } else {
                this.caches.push({
                    url,
                    local: null,
                    statusCode,
                    message
                });
            }
        }
    }
}