//! Hello Rust — demonstrates Rust std on MerlionOS via libmerlion.
//!
//! Compile:
//!   cd /path/to/libmerlion
//!   cargo build --example hello --target ../merlion-kernel/target-specs/x86_64-unknown-merlionos.json
//!
//! Or with the rustc fork:
//!   rustc +merlionos --target x86_64-unknown-merlionos hello_rust.rs
//!
//! Run on MerlionOS:
//!   run-user hello_rust

// This file is a conceptual example. In practice, you'd use
// libmerlion as a dependency in Cargo.toml. Shown here for reference.

fn main() {
    println!("Hello from Rust on MerlionOS!");

    // HashMap
    use std::collections::HashMap;
    let mut map = HashMap::new();
    map.insert("os", "MerlionOS");
    map.insert("language", "Rust");
    println!("Running on: {}", map["os"]);

    // Networking
    use std::net::TcpListener;
    match TcpListener::bind("0.0.0.0:9090") {
        Ok(listener) => println!("Listening on :9090"),
        Err(e) => println!("bind failed: {}", e),
    }

    // Threads
    use std::thread;
    let handle = thread::spawn(|| {
        println!("Hello from a spawned thread!");
    });
    let _ = handle.join();

    // Timing
    use std::time::Instant;
    let start = Instant::now();
    thread::sleep(std::time::Duration::from_millis(50));
    println!("Slept for {:?}", start.elapsed());

    // File I/O
    use std::fs;
    if let Ok(version) = fs::read_to_string("/proc/version") {
        println!("Kernel: {}", version.trim());
    }

    println!("All Rust std features work on MerlionOS!");
}
