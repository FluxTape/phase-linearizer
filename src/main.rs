use clap::Parser;
use std::io::{BufRead, BufReader, BufWriter, Write};
use std::process::{Command, Stdio};

/// Simple program to greet a person
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// minimum frequency (normalised 0.0 to 1.0)
    #[arg(short = 'i', long, default_value_t = 0.0)]
    wmin: f32,

    /// maximum frequency (normalised 0.0 to 1.0)
    #[arg(short = 'm', long, default_value_t = 1.0)]
    wmax: f32,
}

fn main() {
    let args = Args::parse();

    println!("Hello {}-{}!", args.wmin, args.wmax);

    let mut octave = Command::new("octave")
        .arg("--no-gui")
        .arg("--eval")
        .arg("run ./octave_adapter.m")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .expect("command failed to start");
    // let mut octave = Command::new("cat")
    //     .stdin(Stdio::piped())
    //     .stdout(Stdio::piped())
    //     .spawn()
    //     .expect("command failed to start");
    // Create a handle and writer for the stdin of the second process
    let mut oct_stdin = octave.stdin.take().unwrap();
    let mut writer = BufWriter::new(&mut oct_stdin);
    let tmp = "0.0 0.45 50 6 9 1 15 16 17 20 11 0.1 0.11 0.2 0.05 0.01";
    let bytestring = tmp.as_bytes();
    writer.write_all(bytestring).unwrap();
    writer.flush().expect("failed to flush stdin writer");
    drop(writer);
    drop(oct_stdin);

    let oct_stdout = octave.stdout.take().unwrap();
    let lines = BufReader::new(oct_stdout).lines();
    for line in lines {
        let l: String = line.unwrap();
        println!("{}", l)
    }
    println!("yoyo");
    // let out = octave.wait_with_output().expect("wait failed");
    // println!("stdout: {}", String::from_utf8_lossy(&out.stdout));
    octave.wait().expect("wait failed");
}
