import React, {useEffect, useState} from 'react';
import AsyncCache from './AsyncCache';
import {isNull} from '../lib/common';

function getInitialSource(url, getter) {
    const cache = getter(url);
    if (cache && cache.local !== null && cache.local !== undefined) {
        return {
            url: cache.local,
            statusCode: null,
            message: null
        };
    }
    return {
        url: null,
        statusCode: null,
        message: null
    };
}

export default function (
    {
        Component,
        PendingComponent,
        mapToRequestOptions,
        mapToComponentProperties,
        sourceProperty = 'source',
        invokeOnComponentErrorProperty = null,
        invokeOnComponentLoadProperty = null,
        sourceMapper = () => null,
        onSourceMapped = null,
        onRequestError = null,
        cacheValidator = null
    }
) {
    return React.memo((
        {
            [sourceProperty || 'source']: src,
            ...props
        }
    ) => {
        const [source, set_source] = useState(cacheValidator ? {} : getInitialSource(src, sourceMapper));
        const [error, set_error] = useState(false);
        const [resp, set_resp] = useState(null);

        useEffect(() => {
            const cache = sourceMapper(src);
            const handleSourceChanged = (cache) => {
                if (cache && !isNull(cache.local)) {
                    set_source({url: cache.local, statusCode: null, message: null});
                } else if (cache && (!isNull(cache.message) || !isNull(cache.statusCode))) {
                    set_source({
                        url: src,
                        statusCode: cache.statusCode,
                        message: cache.message
                    });
                } else {
                    const componentProps = {
                        [sourceProperty || 'source']: src,
                        ...props
                    };
                    AsyncCache.select({
                        url: src,
                        ...(typeof mapToRequestOptions === 'function' ? mapToRequestOptions(componentProps) : null)
                    }, (event) => {
                        set_resp(event);
                    }).then((response) => {
                        if (response.statusCode !== source.statusCode || response.url !== source.url || response.message !== source.message) {
                            set_source(response);
                            if (!isNull(response.statusCode) || !isNull(response.message)) {
                                if (typeof onRequestError === 'function') {
                                    onRequestError(src, response.statusCode, response.message);
                                }
                            } else {
                                if (typeof onSourceMapped === 'function') {
                                    onSourceMapped(src, response.url);
                                }
                            }
                        }
                    });
                }
            };
            if (typeof cacheValidator === "function") {
                cacheValidator(cache, handleSourceChanged);
            } else {
                handleSourceChanged(cache);
            }
        }, [src]);

        useEffect(() => {
            if (error && resp) {
                const local = 'file://' + resp.path;
                if ((resp.message !== source.message || resp.statusCode !== source.statusCode || resp.url !== local)) {
                    set_source({
                        url: local,
                        message: resp.message,
                        statusCode: resp.statusCode
                    });
                }
            }
        }, [error, resp]);

        const {url} = source;

        const invokeProps = {};
        if (invokeOnComponentErrorProperty) {
            const onError = props[invokeOnComponentErrorProperty];
            invokeProps[invokeOnComponentErrorProperty] = (...args) => {
                if (!error) {
                    set_error(true);
                }
                if (typeof onError === 'function') {
                    onError(...args);
                }
            };
        }

        if (invokeOnComponentLoadProperty) {
            const onLoad = props[invokeOnComponentLoadProperty];
            invokeProps[invokeOnComponentLoadProperty] = (...args) => {
                if (error) {
                    set_error(false);
                }
                if (typeof onLoad === 'function') {
                    onLoad(...args);
                }
            };
        }

        const mapProps = {
            ...props,
            ...invokeProps,
            [sourceProperty]: source.url,
            ...(
                typeof mapToComponentProperties === 'function'
                    ? mapToComponentProperties({
                        [sourceProperty]: source.url,
                        statusCode: source.statusCode,
                        message: source.message
                    }) : null
            )
        };


        if (isNull(url)) {
            return PendingComponent ? (
                <PendingComponent {...mapProps} />
            ) : null;
        }
        return <Component {...mapProps} />;
    });
}
