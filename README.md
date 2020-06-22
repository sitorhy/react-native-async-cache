# react-native-async-cache

## Getting started

`$ npm install react-native-async-cache --save`

### Mostly automatic installation

`$ react-native link react-native-async-cache`

## API

### Promise select(options)

The only method need to know, return a promise resolves an object containing url. 
If the file downloaded, resolve the url as local path, otherwise resolve the request given.

+ Request Options

| Option | Optional | Type | Description |
| :-----| ----: | ----: | :----: |
| url | NO | String | the network resource url |
| headers | YES | Map<String,String> | request headers |
| subDir | YES | String | name of directory where the file save to |
| extension | YES | String | file extension, may be important for some components |

+ Thenable Object

| Param | Type | Description |
| :-----| ----: | :----: |
| success | Boolean | whether the file is cached |
| url | String | the url from given request or the file path  prefix with `file://` that been cached |
| statusCode | Integer | it's nonzero and nonnull if request failed |
| message | String | the failure description |

+ Usage example
```js
import RNAsyncCache from 'react-native-async-cache';

RNAsyncCache.select({
    url: "https://static.zerochan.net/Kouyafu.full.2927619.jpg"
}).then((res) => {
    const {url, statusCode, message} = res;
    this.setState(
        {img: url, statusCode, message}
    );
});

// Component initial state

state = {
    img:"",
    statusCode:0,
    message:""
};


// Component render

const {img, statusCode, message} = this.state;

if(statusCode || message){
    // request failed
    return <Text>{statusCode} {message}</Text>
}

return img ? <Loading /> : <Image source={{uri: img}}/>
```

<br>

### Promise<Void> trash(options)

Empty the cache directory.

+ Request Options

| Option | Optional | Type | Description |
| :-----| ----: | ----: | :----: |
| subDir | YES | String | name of directory be emptied |

<br>

### Promise accessible(options)

Try to check http status code of the url is 200 OK.

+ Request Options

| Option | Optional | Type | Description |
| :-----| ----: | ----: | :----: |
| url | NO | String | network resource url |
| statusCodeLeft | YES | Integer | min valid status code |
| statusCodeRight | YES | Integer | max valid status code |

+ Thenable Object

| Param | Type | Description |
| :-----| ----: | :----: |
| accessible | Boolean | whether the file is cached |
| statusCode | String | http status code or -1 if runtime exception occurred  |
| message | String | description of failure |
| size | Number | total bytes of resource, may be -1 if server not support `Content-Length`|
| url | String | request url |

<br>

### Promise check(options)

Confirm whether the cache file exists.

+ Request Options

| Option | Optional | Type |
| :-----| ----: | ----: |
| url | NO | String |
| subDir | YES | String |
| extension  | YES | String |

+ Thenable Object

| Param | Type | Description |
| :-----| ----: | :----: |
| path | String | not empty if the file exists |
| exists | Boolean | whether the file exists |
| url | String | request url |

<br>

### Promise remove(options)

Delete the cache file specified.

+ Request Options

| Option | Optional | Type |
| :-----| ----: | ----: |
| url | NO | String |
| subDir | YES | String |
| extension  | YES | String |

+ Thenable Object

| Param | Type | Description |
| :-----| ----: | :----: |
| success | String | whether the file was deleted successfully |
| path | Boolean | path of the file be deleted, it's not empty if successfully removed |
| url | String | request url |

<br>

### Promise download(options, onProgress)

Cache a file manually.

+ Request Options

| Option | Optional | Type |
| :-----| ----: | ----: |
| url | NO | String |
| subDir | YES | String |
| extension  | YES | String |

+ onProgress Callback

| Param | Type | Description |
| :-----| ----: | :----: |
| progress | Number | -1 if server not support `Content-Length`  |
| total | Boolean | Content-Length, may be -1 |
| current | String | bytes of written |
| url | String | request url |

+ Thenable Object

| Param | Type | Description |
| :-----| ----: | :----: |
| size | Number | the size of the file been downloaded |
| path | Boolean | path of the file |
| url | String | request url |

<br>

### Promise clean(options)

Android only, clean all temp files. 

+ Request Options

| Option | Optional | Type |
| :-----| ----: | ----: |
| subDir | YES | String |

<br>


### void post(options)

Execute method `select()` ignore the return value.

+ Request Options

| Option | Optional | Type |
| :-----| ----: | ----: |
| url | NO | String |
| headers | YES | Map<String,String> |
| subDir | YES | String |
| extension  | YES | String |

## Cache Component

| Option | Optional | Type | Description |
| :-----| ----: | ----: | ----: |
| Component | NO | Component | render component with url |
| PendingComponent | YES | Component | render component during select() execution |
| mapToRequestOptions | YES | Function | map component props to request options |
| mapToComponentProperties | YES | Function | map select() result to component props |
| sourceProperty | YES | String | the component receive url, default 'source' |
| invokeOnComponentErrorProperty | YES | String | name of the callback function invoked on load error |
| invokeOnComponentLoadProperty | YES | String | name of the callback function invoked on load success |
| sourceMapper | YES | Function | map url to local path |
| onSourceMapped | YES | Function | invoked on url accepted |
| onRequestError | YES | Function | invoked on url has been checked not accessible |

### Usage

```js
import {CacheComponent} from '../react-native-async-cache';
import {Image} from 'react-native';

const CacheImage =  CacheComponent(
    {
        Component: Image,
        PendingComponent: Image,
        invokeOnComponentErrorProperty: 'onError',
        invokeOnComponentLoadProperty: 'onLoad',
        mapToRequestOptions: () => {
            return {
                subDir: 'images'
            };
        },
        mapToComponentProperties: (props) => {
            return {
                source: typeof props.source === 'number' ? props.source : {uri: props.source},
                errorMessage: (props.statusCode || props.message) ? props.statusCode + ' ' + (props.message || '') : null
            };
        }
    }
);

// render component

return (
    <View style={{flex: 1, alignItems: "center"}}>
        <CacheImage source={"https://static.zerochan.net/Kouyafu.full.2792022.jpg"} style={{
            width : Dimensions.get("window").width - 30,
            height : Dimensions.get("window").height
        }}/>
    </View>
)
```

### CacheStoreComponent

create a `CacheComponent` with a memory store to reduce `select()` calls.

```js
import {CacheStoreComponent} from '../react-native-async-cache';
import {Image} from 'react-native';

const CacheStoreImage =  CacheStoreComponent(
    {
        Component: Image,
        PendingComponent: ()=>{
            return <View><Text>Loading...</Text></View>;
        },
        invokeOnComponentErrorProperty: 'onError',
        invokeOnComponentLoadProperty: 'onLoad',
        mapToRequestOptions: () => {
            return {
                subDir: 'images'
            };
        },
        mapToComponentProperties: (props) => {
            return {
                source: typeof props.source === 'number' ? props.source : {uri: props.source},
                errorMessage: (props.statusCode || props.message) ? props.statusCode + ' ' + (props.message || '') : null
            };
        }
    }
);

// render component

return (
    <View style={{flex: 1, alignItems: "center"}}>
       <CacheStoreImage source={"https://static.zerochan.net/Fuji.Choko.full.2920380.jpg"} style={{
           width : Dimensions.get("window").width - 30,
           height : Dimensions.get("window").height
       }}/>
   </View>
)
```
