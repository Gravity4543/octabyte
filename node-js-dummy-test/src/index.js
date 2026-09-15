var express = require("express");
var bodyParser = require("body-parser");
var path = require("path");
var db = require("./db");

var app = express();
var port = process.env.PORT || 3000;

app.use(bodyParser.urlencoded({ extended: true }));
app.set("view engine", "ejs");
// views + public are one level up from src/
app.set("views", path.join(__dirname, "..", "views"));
app.use(express.static(path.join(__dirname, "..", "public")));

// home page - open + completed tasks
app.get("/", async function (req, res) {
    try {
        var task = await db.getTasks(false);
        var complete = await db.getTasks(true);
        res.render("index", { task: task, complete: complete });
    } catch (err) {
        console.error("Failed to load tasks:", err.message);
        res.status(500).send("Could not load tasks");
    }
});

// add a task
app.post("/addtask", async function (req, res) {
    try {
        var newTask = req.body.newtask;
        if (newTask) {
            await db.addTask(newTask);
        }
        res.redirect("/");
    } catch (err) {
        console.error("Failed to add task:", err.message);
        res.status(500).send("Could not add task");
    }
});

// mark task(s) done - checkbox can send one value or an array
app.post("/removetask", async function (req, res) {
    try {
        var completeTask = req.body.check;
        if (typeof completeTask === "string") {
            await db.completeTask(completeTask);
        } else if (Array.isArray(completeTask)) {
            for (var i = 0; i < completeTask.length; i++) {
                await db.completeTask(completeTask[i]);
            }
        }
        res.redirect("/");
    } catch (err) {
        console.error("Failed to remove task:", err.message);
        res.status(500).send("Could not remove task");
    }
});

// health check for the ALB - 200 if we can reach the db, 503 otherwise
app.get("/health", async function (req, res) {
    try {
        await db.ping();
        res.status(200).json({ status: "ok", database: "up" });
    } catch (err) {
        res.status(503).json({ status: "degraded", database: "down", error: err.message });
    }
});

// only listen when run directly - tests just import the app
if (require.main === module) {
    db.init()
        .catch(function (err) {
            // don't die on boot if the db is briefly down, /health will show it
            console.error("Database init failed (continuing):", err.message);
        })
        .finally(function () {
            app.listen(port, function () {
                console.log("server is running on http://localhost:" + port);
            });
        });
}

module.exports = app;
