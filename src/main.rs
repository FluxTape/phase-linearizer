use clap::Parser;
use std::process::Command;

/// Simple program to greet a person
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Name of the person to greet
    #[arg(short, long)]
    name: String,

    /// Number of times to greet
    #[arg(short, long, default_value_t = 1)]
    count: u8,
}

fn main() {
    let args = Args::parse();

    for _ in 0..args.count {
        println!("Hello {}!", args.name)
    }

    let output = Command::new("octave")
        .arg("--eval")
        .arg("run ./octave_main.m")
        .output()
        .expect("ls command failed to start");
    println!("stdout: {}", String::from_utf8_lossy(&output.stdout));
}
