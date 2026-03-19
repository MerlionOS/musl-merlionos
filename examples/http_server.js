// HTTP server — Node.js on MerlionOS.
// Run: run-user node http_server.js

const http = require("http");

const server = http.createServer((req, res) => {
    if (req.url === "/") {
        res.writeHead(200, { "Content-Type": "text/plain" });
        res.end("Hello from Node.js on MerlionOS!\n");
    } else if (req.url === "/status") {
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({
            os: "MerlionOS",
            runtime: "Node.js",
            version: process.version,
            pid: process.pid,
            uptime: process.uptime(),
        }, null, 2) + "\n");
    } else {
        res.writeHead(404);
        res.end("Not Found\n");
    }
});

server.listen(8080, "0.0.0.0", () => {
    console.log("Node.js HTTP server on :8080");
});
