// db layer. everything comes from env vars so the same image runs everywhere.
// set DB_MOCK=true to use an in-memory store (used by the tests, no live pg needed).

var useMock = String(process.env.DB_MOCK).toLowerCase() === "true";

var pool = null;

function getPool() {
    if (pool) return pool;
    var Pool = require("pg").Pool;
    pool = new Pool({
        host: process.env.DB_HOST || "localhost",
        port: parseInt(process.env.DB_PORT || "5432", 10),
        user: process.env.DB_USER || "postgres",
        password: process.env.DB_PASSWORD || "postgres",
        database: process.env.DB_NAME || "appdb",
        // small pool, single instance per env
        max: parseInt(process.env.DB_POOL_MAX || "5", 10),
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 5000,
        // RDS needs TLS, off locally
        ssl: String(process.env.DB_SSL).toLowerCase() === "true"
            ? { rejectUnauthorized: false }
            : false,
    });
    return pool;
}

// in-memory version for tests
var mockTasks = [
    { title: "buy a new udemy course", done: false },
    { title: "practise with kubernetes", done: false },
    { title: "finish reading the book", done: true },
];

var mock = {
    init: function () { return Promise.resolve(); },
    ping: function () { return Promise.resolve(); },
    getTasks: function (done) {
        return Promise.resolve(
            mockTasks.filter(function (t) { return t.done === done; })
                .map(function (t) { return t.title; })
        );
    },
    addTask: function (title) {
        mockTasks.push({ title: title, done: false });
        return Promise.resolve();
    },
    completeTask: function (title) {
        var t = mockTasks.find(function (x) { return x.title === title && !x.done; });
        if (t) t.done = true;
        return Promise.resolve();
    },
};

// real postgres
var real = {
    // make the table if needed and seed a few rows the first time
    init: async function () {
        var p = getPool();
        await p.query(
            "CREATE TABLE IF NOT EXISTS tasks (" +
            "  id SERIAL PRIMARY KEY," +
            "  title TEXT NOT NULL," +
            "  done BOOLEAN NOT NULL DEFAULT FALSE," +
            "  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()" +
            ")"
        );
        var count = await p.query("SELECT COUNT(*)::int AS c FROM tasks");
        if (count.rows[0].c === 0) {
            await p.query(
                "INSERT INTO tasks (title, done) VALUES ($1, $2), ($3, $4), ($5, $6)",
                ["buy a new udemy course", false, "practise with kubernetes", false, "finish reading the book", true]
            );
        }
    },
    ping: async function () {
        await getPool().query("SELECT 1");
    },
    getTasks: async function (done) {
        var r = await getPool().query(
            "SELECT title FROM tasks WHERE done = $1 ORDER BY id",
            [done]
        );
        return r.rows.map(function (row) { return row.title; });
    },
    addTask: async function (title) {
        await getPool().query("INSERT INTO tasks (title, done) VALUES ($1, FALSE)", [title]);
    },
    completeTask: async function (title) {
        // complete the oldest matching open task
        await getPool().query(
            "UPDATE tasks SET done = TRUE WHERE id = (" +
            "  SELECT id FROM tasks WHERE title = $1 AND done = FALSE ORDER BY id LIMIT 1" +
            ")",
            [title]
        );
    },
};

module.exports = useMock ? mock : real;
