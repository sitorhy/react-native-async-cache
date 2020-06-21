export default class {
    constructor() {
        this.size = 100;
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
                    this.caches[this.index++ % this.size] = {
                        url,
                        local,
                        message: null,
                        statusCode: null
                    };
                    if (this.index >= this.size) {
                        this.index = 0;
                    }
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
                this.caches[this.index++ % this.size] = {
                    url,
                    local: null,
                    statusCode,
                    message
                };
                if (this.index >= this.size) {
                    this.index = 0;
                }
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