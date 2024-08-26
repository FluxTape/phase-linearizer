use anyhow::{anyhow, Context, Result};
use clap::Parser;
use core::fmt::Display;
use serde::Serialize;
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

#[derive(clap::ValueEnum, Clone, Default, Debug, PartialEq, Serialize)]
#[serde(rename_all = "kebab-case")]
enum Weights {
    /// flat error weights
    #[default]
    Flat,
    /// custom user provided error weights
    Custom,
    /// error weights based on amplitude
    Amplitude,
}

impl Display for Weights {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let octave_val = match self {
            Weights::Flat => 0,
            Weights::Custom => 1,
            Weights::Amplitude => 2,
        };
        write!(f, "{}", octave_val)
    }
}

/// program for generating phase linearization filters
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
    #[arg(short, long, value_enum, default_value_t)]
    weights: Weights,

    /// path to file with input data
    #[arg(short, long)]
    file: Option<String>,

    /// data
    data: Vec<f64>,
}

fn main() -> Result<()> {
    let args = Args::parse();

    let data_in = if args.data.is_empty() {
        stdin()
            .lines()
            .collect::<Result<Vec<_>, _>>()?
            .iter()
            .flat_map(|s| s.split_whitespace())
            .inspect(|s| {
                dbg!(s);
            })
            .map(|s| s.parse::<f64>())
            .map(|f| f.map(|g| g.to_string()))
            .collect::<Result<Vec<_>, _>>()?
    } else {
        args.data
            .into_iter()
            .map(|f| f.to_string())
            .collect::<Vec<String>>()
    };
    if args.weights == Weights::Custom && data_in.len() & 1 == 1 {
        return Err(anyhow!(
            "number of data values and number of weights does not match: {} is odd",
            data_in.len()
        ));
    }
    let data_str = data_in.join(" ");

    let mut octave = Command::new("octave")
        .arg("--no-gui")
        .arg("--eval")
        .arg("run ./octave_adapter_gradient.m")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .context("command failed to start")?;

    // needs to be scoped so stdin is flushed and closed at the end
    {
        let mut oct_stdin = octave.stdin.take().ok_or(anyhow!("failed to get stdin"))?;
        let mut writer = BufWriter::new(&mut oct_stdin);
        let tmp = format!(
            "{wmin} {wmax} {wpoints} {order} {splits} {weights} {data}",
            wmin = args.wmin,
            wmax = args.wmax,
            wpoints = args.points,
            order = args.order,
            splits = args.splits,
            weights = args.weights,
            data = data_str
        );
        let bytestring = tmp.as_bytes();
        writer.write_all(bytestring)?;
    }
    println!("running octave...");
    let output = octave
        .wait_with_output()
        .context("failed to wait for output")?;
    println!("stdout: {}", String::from_utf8_lossy(&output.stdout));
    Ok(())
}
