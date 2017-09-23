"use strict";

const vm = require("vm");
const app = require("express")();

app.use(require("body-parser").json());

app.post("/eval", (req, res) => {
    try {
        res.json({success: new vm.Script(req.body.code).runInThisContext()});
    } catch (err) {
        res.json({error: err.stack});
    }
});

const server = app.listen(0, "localhost", () => {
    console.log(server.address().port)
});
