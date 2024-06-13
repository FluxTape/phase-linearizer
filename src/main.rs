use clap::Parser;
use std::process::Command;

/// Simple program to greet a person
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Name of the person to greet
    #[arg(short, long)]
    name: String,

    /// minimum frequency (normalised 0.0 to 1.0)
    #[arg(short = 'i', long, default_value_t = 0.0)]
    wmin: f32,

    /// maximum frequency (normalised 0.0 to 1.0)
    #[arg(short = 'm', long, default_value_t = 1.0)]
    wmax: f32,
}

fn main() {
    let args = Args::parse();

    println!("Hello {} {}-{}!", args.name, args.wmin, args.wmax);

    let output = Command::new("octave")
        .arg("--eval")
        .arg("run ./octave_main.m")
        .output()
        .expect("ls command failed to start");
    println!("stdout: {}", String::from_utf8_lossy(&output.stdout));
}
