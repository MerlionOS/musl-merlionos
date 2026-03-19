// Hello World — Node.js on MerlionOS.
// Run: run-user node hello.js

console.log("Hello from Node.js on MerlionOS!");
console.log(`Node.js ${process.version}`);
console.log(`PID: ${process.pid}`);

// Promises + async
async function main() {
    // Array methods
    const nums = [1, 2, 3, 4, 5];
    const squares = nums.map(n => n * n);
    console.log(`Squares: ${squares}`);

    // Object destructuring
    const info = { os: "MerlionOS", lang: "JavaScript", year: 2026 };
    const { os, lang } = info;
    console.log(`Running ${lang} on ${os}`);

    // Timer
    const start = Date.now();
    await new Promise(resolve => setTimeout(resolve, 100));
    console.log(`Slept ${Date.now() - start}ms`);

    console.log("All Node.js tests passed!");
}

main().catch(console.error);
