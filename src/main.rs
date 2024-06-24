use clap::error::ErrorKind;
use clap::{Error, Parser};
use std::io::{stdin, BufWriter, Write};
use std::process::{Command, Stdio};

/*
modes:
gradient
gradient + err weights
transfer function
transfer function + err weights
transfer function + auto weights
impulse response
impulse response + err weigths
impulse response + auto weights
*/

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

    /// number of internal sampling points
    #[arg(short, long, default_value_t = 100)]
    points: u32,

    /// order of the linearization filter
    #[arg(short, long, default_value_t = 6)]
    order: u32,

    /// number of search points freq grid
    #[arg(short, long, default_value_t = 9)]
    splits: u32,

    /// whether the input data contains error weigths
    #[arg(short, long, default_value_t = false)]
    weights: bool,

    /// path to file with input data
    #[arg(short, long)]
    file: Option<String>,

    /// data
    data: Vec<f64>,
}

fn main() -> Result<(), Error> {
    let args = Args::parse();

    let data_str = if args.data.is_empty() {
        stdin()
            .lines()
            .collect::<Result<Vec<_>, _>>()?
            .iter()
            .flat_map(|s| s.split_whitespace())
            .map(|s| {
                dbg!(&s);
                s
            })
            .map(|s| {
                s.parse::<f64>()
                    .map_err(|_| Error::new(ErrorKind::InvalidValue))
            })
            .map(|f| f.map(|g| g.to_string()))
            .collect::<Result<Vec<_>, _>>()?
            .join(" ")
    } else {
        args.data
            .into_iter()
            .map(|f| f.to_string())
            .collect::<Vec<String>>()
            .join(" ")
    };

    let mut octave = Command::new("octave")
        .arg("--no-gui")
        .arg("--eval")
        .arg("run ./octave_adapter_gradient.m")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .expect("command failed to start");

    // needs to be scoped so stdin is flushed and closed at the end
    {
        let mut oct_stdin = octave.stdin.take().unwrap();
        let mut writer = BufWriter::new(&mut oct_stdin);
        let tmp = format!(
            "{wmin} {wmax} {wpoints} {order} {splits} {has_weights} {data}",
            wmin = args.wmin,
            wmax = args.wmax,
            wpoints = args.points,
            order = args.order,
            splits = args.splits,
            has_weights = if args.weights { 1 } else { 0 },
            data = data_str
        );
        let bytestring = tmp.as_bytes();
        writer.write_all(bytestring).unwrap();
    }
    println!("running octave...");
    let output = octave.wait_with_output().expect("wait failed");
    println!("stdout: {}", String::from_utf8_lossy(&output.stdout));
    Ok(())
}
