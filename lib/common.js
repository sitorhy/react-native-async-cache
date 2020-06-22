export function isNull(value) {
    return value === null || value === undefined;
}

export function randomNum(minNum, maxNum) {
    switch (arguments.length) {
        case 1:
            return parseInt(Math.random() * minNum + 1, 10);
        case 2:
            return parseInt(Math.random() * ( maxNum - minNum + 1 ) + minNum, 10);
        default:
            return 0;
    }
}

export function getUrlExtension(url = "", dot = false) {
    if (!url) {
        return "";
    }
    let s = url;
    const iQue = url.lastIndexOf("?");
    if (iQue >= 0) {
        s = url.substring(0, iQue);
    }
    const iSep = s.lastIndexOf("/");
    if (iSep >= 0) {
        s = s.substring(iSep + 1);
    }
    const iDot = s.lastIndexOf(".");
    if (iDot >= 0) {
        const ext = s.substring(iDot);
        return dot ? ext : ext.substring(1);
    }
    return "";
}