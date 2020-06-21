import CacheComponent from './CacheComponent';
import StoreProvider from './DefaultStoreProvider';

export default function (
    {
        Component,
        PendingComponent,
        mapToRequestOptions,
        mapToComponentProperties,
        sourceProperty = 'source',
        invokeOnComponentErrorProperty,
        invokeOnComponentLoadProperty,
        store = new StoreProvider()
    }
) {
    return CacheComponent(
        {
            Component,
            PendingComponent,
            mapToRequestOptions: (source) => {
                if (typeof mapToRequestOptions === 'function') {
                    return {
                        ...mapToRequestOptions(source)
                    };
                }
                return options;
            },
            mapToComponentProperties: (props) => {
                if (typeof mapToComponentProperties === 'function') {
                    return {
                        ...props,
                        ...mapToComponentProperties(props)
                    };
                }
                return props;
            },
            sourceProperty,
            invokeOnComponentErrorProperty,
            invokeOnComponentLoadProperty,
            sourceMapper: (url) => {
                if (store) {
                    return store.get(url);
                }
                return null;
            },
            onSourceMapped: (url, local) => {
                if (store) {
                    store.set(url, local);
                }
            },
            onRequestError: (url, code, message) => {
                if (store) {
                    store.error(url, code, message);
                }
            }
        }
    );
}
