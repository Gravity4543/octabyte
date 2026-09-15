// These tests exercise the REAL application exported from index.js.
// DB_MOCK=true (set by the npm test script) swaps the Postgres layer for an
// in-memory store so tests run in CI without a live database.
process.env.DB_MOCK = "true";

const request = require("supertest");
const app = require("./index");

describe("todo app", function () {
    it("GET / returns 200 and renders seeded tasks", async function () {
        const res = await request(app).get("/");
        expect(res.status).toBe(200);
        // seeded open task should appear in the rendered HTML
        expect(res.text).toContain("practise with kubernetes");
    });

    it("GET /health returns 200 when the database is reachable", async function () {
        const res = await request(app).get("/health");
        expect(res.status).toBe(200);
        expect(res.body.status).toBe("ok");
        expect(res.body.database).toBe("up");
    });

    it("POST /addtask adds a task and redirects", async function () {
        const res = await request(app)
            .post("/addtask")
            .type("form")
            .send({ newtask: "write terraform modules" });
        expect(res.status).toBe(302); // redirect back to /

        const home = await request(app).get("/");
        expect(home.text).toContain("write terraform modules");
    });

    it("POST /removetask moves a task to completed", async function () {
        // add then complete it
        await request(app).post("/addtask").type("form").send({ newtask: "temp task" });
        const res = await request(app)
            .post("/removetask")
            .type("form")
            .send({ check: "temp task" });
        expect(res.status).toBe(302);
    });
});
