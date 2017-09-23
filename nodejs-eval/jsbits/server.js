"use strict";

const vm = require("vm");
const app = require("express")();

app.use(require("body-parser").json());

const context = vm.createContext({
    require: require,
    console: console
});

app.post("/eval", (req, res) => {
    try {
        res.json({success: vm.runInContext(req.body.code, context, {displayErrors: true})})
    } catch (err) {
        res.json({error: err.stack});
    }
});

const server = app.listen(0, "localhost", () => console.log(server.address().port));
