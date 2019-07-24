function main(args) {
    const arrData = [];
    for (let i = 0; i < 10000000; i++) {
        arrData.push(i);
    }
    // es6
    for (const pVal of arrData) {}
    // for each
    arrData.forEach((pVal) => {});
    return {"result": "Done!!!" };
}

