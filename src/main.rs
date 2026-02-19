use anyhow::{anyhow, Context, Result};
use clap::{Args, Parser};
use serde::Serialize;
//use std::fs;
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

fn range_0_to_1(s: &str) -> Result<f64, String> {
    let val = s.parse::<f64>().map_err(|e| e.to_string())?;
    if val < 0.0 {
        return Err(format!("{} is less than 0.0", val));
    }
    if val > 1.0 {
        return Err(format!("{} is greater than 1.0", val));
    }
    Ok(val)
}

/// program for generating phase linearization filters
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Cli {
    /// output results to file
    #[arg(short = 'f', long)]
    output: Option<String>,

    /// minimum frequency (normalised 0.0 to 1.0)
    #[arg(short = 'n', long, default_value_t = 0.0, value_parser=range_0_to_1, allow_negative_numbers=true)]
    wmin: f64,

    /// maximum frequency (normalised 0.0 to 1.0)
    #[arg(short = 'x', long, default_value_t = 1.0, value_parser=range_0_to_1, allow_negative_numbers=true)]
    wmax: f64,

    /// number of internal sampling points
    #[arg(short, long, default_value_t = 150)]
    points: u32,

    /// order of the linearization filter
    #[arg(short, long, default_value_t = 6)]
    order: u32,

    /// if added shows a graph of the results
    #[arg(short, long, default_value_t = false)]
    graph: bool,

    /// algorithm to use
    #[arg(short, long, value_enum, default_value_t)]
    algo: Algo,

    /// number of optimization iterations to run
    #[arg(short, long, default_value_t = 300)]
    iterations: u32,

    /// type of input data
    #[command(subcommand)]
    mode: Mode,
}

#[derive(Args, Clone, Default, Debug, PartialEq, Serialize)]
#[group(multiple = false)]
struct WeightsFCA {
    #[clap(long, default_value_t = false)]
    /// flat error weights (default)
    flat: bool,
    /// error weights based on amplitude
    #[clap(long, default_value_t = false, visible_alias = "amp")]
    amplitude: bool,
    /// custom user provided error weights
    #[clap(long, value_parser, num_args = 1.., value_delimiter = ' ')]
    custom: Option<Vec<f64>>,
}

impl WeightsFCA {
    fn to_usize(&self) -> usize {
        match (self.flat, self.amplitude, self.custom.is_some()) {
            (true, _, _) => 0,
            (_, true, _) => 1,
            (_, _, true) => 2,
            _ => 0,
        }
    }

    fn custom_weights(&self) -> Option<&Vec<f64>> {
        self.custom.as_ref()
    }
}

#[derive(Args, Clone, Default, Debug, PartialEq, Serialize)]
#[group(multiple = false)]
struct WeightsFC {
    #[clap(long, default_value_t = false)]
    /// flat error weights (default)
    flat: bool,
    /// custom user provided error weights
    #[clap(long, value_parser, num_args = 1.., value_delimiter = ' ')]
    custom: Option<Vec<f64>>,
}

impl WeightsFC {
    fn to_usize(&self) -> usize {
        match (self.flat, self.custom.is_some()) {
            (true, _) => 0,
            (_, true) => 2,
            _ => 0,
        }
    }

    fn custom_weights(&self) -> Option<&Vec<f64>> {
        self.custom.as_ref()
    }
}

#[derive(clap::ValueEnum, Clone, Default, Debug, PartialEq, Serialize)]
#[serde(rename_all = "kebab-case")]
enum Algo {
    /// basic Grid based starting values + fminunc
    Grid,
    /// random starting positions + fminunc
    #[default]
    RandomUnc,
    /// random starting positions + fmincon
    RandomCon,
    /// particle swarm optimization
    Pso,
    /// alternative particle swarm optimization - experiment
    PsoK,
    /// particle swarm optimization - minimum of 10 runs
    PsoM,
}

impl Algo {
    fn to_usize(&self) -> usize {
        match self {
            Algo::Grid => 0,
            Algo::RandomUnc => 1,
            Algo::RandomCon => 2,
            Algo::Pso => 3,
            Algo::PsoK => 4,
            Algo::PsoM => 5
        }
    }
}

enum DataSource<'a> {
    Stdin,
    Arg(Box<dyn Iterator<Item = &'a str> + 'a>),
    File(&'a String),
}

#[derive(clap::ValueEnum, Clone, Default, Debug, PartialEq, Serialize)]
#[serde(rename_all = "kebab-case")]
enum WindowFunction {
    #[default]
    /// no window function, aka. box/rectangle
    None,
    /// Hamming window
    Hamming,
    /// Hanning window
    Hanning,
    /// Blackman window
    Blackman,
    /// Chebyshev window
    ChebWin,
    /// Kaiser window
    Kaiser
}

impl WindowFunction {
    fn to_usize(&self) -> usize {
        match self {
            WindowFunction::None => 0,
            WindowFunction::Hamming => 1,
            WindowFunction::Hanning => 2,
            WindowFunction::Blackman => 3,
            WindowFunction::ChebWin => 4,
            WindowFunction::Kaiser => 5,
        }
    }
}

#[derive(clap::Subcommand, Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "kebab-case")]
enum Mode {
    /// gradient values
    #[clap(visible_alias = "grd")]
    Gradient {
        /// whether the input data contains error weigths
        #[command(flatten)]
        weights: WeightsFC,

        /// path to file with input data
        #[arg(short, long)]
        file: Option<String>,

        /// data as a string of space separated values
        data: String,
    },
    /// numerator followed by denominator
    #[clap(visible_alias = "tf")]
    TransferFunction {
        /// whether the input data contains error weigths
        #[command(flatten)]
        weights: WeightsFCA,

        /// numerator coefficients as a string of space separated values
        #[clap(long, required = true, visible_alias = "num")]
        numerator: String,

        /// denominator coefficients as a string of space separated values
        #[clap(long, required = true, visible_alias = "den")]
        denominator: String,
    },
    /// impulse response sample points
    #[clap(visible_alias = "imp")]
    ImpulseResponse {
        /// whether the input data contains error weigths
        //#[arg(short, long, value_enum, default_value_t)]
        #[command(flatten)]
        weights: WeightsFCA,

        /// path to impulse response file. If the file has multiple
        /// audio channels only the first one will be used
        #[arg(short, long)]
        file: Option<String>,

        /// sample rate followed by raw data as a string of space separated values
        data: String,
    },
    #[clap(visible_alias = "tf-fir")]
    TransferFunctionFIR {
        /// whether the input data contains error weigths
        #[command(flatten)]
        weights: WeightsFCA,

        /// numerator coefficients as a string of space separated values
        #[clap(long, required = true, visible_alias = "num")]
        numerator: String,

        /// denominator coefficients as a string of space separated values
        #[clap(long, required = true, visible_alias = "den")]
        denominator: String,

        /// window function to use, default is none
        #[arg(long, value_enum, default_value_t, visible_alias = "wf")]
        window: WindowFunction,
    },
}

impl Mode {
    fn adapter_path(&self) -> &'static str {
        match self {
            Mode::Gradient { .. } => "./octave_adapter_gradient.m",
            Mode::TransferFunction { .. } => "./octave_adapter_tf.m",
            Mode::ImpulseResponse { .. } => "./octave_adapter_imp.m",
            Mode::TransferFunctionFIR { .. } => "./octave_adapter_tf_fir.m"
        }
    }

    fn data_source(&self) -> DataSource<'_> {
        match self {
            Mode::Gradient { file, data, .. } => match (file, !data.is_empty()) {
                (Some(file), _) => DataSource::File(file),
                (_, true) => DataSource::Arg(Box::new(data.split_whitespace())),
                _ => DataSource::Stdin,
            },
            Mode::TransferFunction {
                numerator,
                denominator,
                ..
            } => DataSource::Arg(Box::new(
                numerator
                    .split_whitespace()
                    .chain(denominator.split_whitespace()),
            )),
            Mode::ImpulseResponse { file, data, .. } => match (file, !data.is_empty()) {
                (Some(file), _) => DataSource::File(file),
                (_, true) => DataSource::Arg(Box::new(data.split_whitespace())),
                _ => DataSource::Stdin,
            },
            Mode::TransferFunctionFIR {
                numerator,
                denominator,
                ..
            } => DataSource::Arg(Box::new(
                numerator
                    .split_whitespace()
                    .chain(denominator.split_whitespace()),
            )),
        }
    }

    fn input_is_file(&self) -> bool {
        matches!(self.data_source(), DataSource::File(..))
    }

    fn weights_mode(&self) -> usize {
        match self {
            Mode::Gradient { weights, .. } => weights.to_usize(),
            Mode::TransferFunction { weights, .. } => weights.to_usize(),
            Mode::ImpulseResponse { weights, .. } => weights.to_usize(),
            Mode::TransferFunctionFIR { weights, .. } => weights.to_usize(),
        }
    }

    fn custom_weights(&self) -> Option<&Vec<f64>> {
        match self {
            Mode::Gradient { weights, .. } => weights.custom_weights(),
            Mode::TransferFunction { weights, .. } => weights.custom_weights(),
            Mode::ImpulseResponse { weights, .. } => weights.custom_weights(),
            Mode::TransferFunctionFIR { weights, .. } => weights.custom_weights(),
        }
    }
}

fn main() -> Result<()> {
    let args = Cli::parse();

    let data_in = match args.mode.data_source() {
        DataSource::Stdin => stdin()
            .lines()
            .collect::<Result<Vec<_>, _>>()?
            .iter()
            .flat_map(|s| s.split_whitespace())
            .inspect(|s| {
                dbg!(s);
            })
            .map(str::parse::<f64>)
            .map(|f| f.map(|g| g.to_string()))
            .collect::<Result<Vec<_>, _>>()?,
        DataSource::Arg(data) => data
            .map(str::parse::<f64>)
            .map(|f| f.map(|g| g.to_string()))
            .collect::<Result<Vec<_>, _>>()?,
        DataSource::File(file) => [file.clone()].into(),
    };
    let weights = if args.mode.weights_mode() == 2 {
        let custom_weights = args
            .mode
            .custom_weights()
            .expect("should be some since custom mode is set");
        assert!(
            !custom_weights.is_empty(),
            "custom weights should contain at least one element"
        );
        debug_assert!(
            !custom_weights.iter().any(|&f| f < 0.0),
            "it should not be possible for custom weights to contain negative values"
        );
        custom_weights
    } else {
        &Vec::<f64>::new()
    };

    let mut octave = Command::new("octave")
        //.arg("--no-gui")
        .arg("--eval")
        .arg(format!("run {}", args.mode.adapter_path()))
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .context("command failed to start")?;

    // needs to be scoped so stdin is flushed and closed at the end
    {
        let mut oct_stdin = octave.stdin.take().ok_or(anyhow!("failed to get stdin"))?;
        let mut writer = BufWriter::new(&mut oct_stdin);
        let algo_field = match &args.mode {
            Mode::TransferFunctionFIR {  window, .. } => {
                if args.algo != Algo::default() {
                    println!("Warning: algo option will be ignored in FIR mode")
                }
                window.to_usize()
            },
            _ => args.algo.to_usize(),
        };
        let octave_args = [
            /* 00 */ args.output.unwrap_or_else(|| "none".to_string()),
            /* 01 */ args.wmin.to_string(),
            /* 02 */ args.wmax.to_string(),
            /* 03 */ args.points.to_string(),
            /* 04 */ args.order.to_string(),
            /* 05 */ (if args.graph { 1 } else { 0 }).to_string(),
            /* 06 */ algo_field.to_string(),
            /* 07 */ args.iterations.to_string(),
            /* 08 */ (if args.mode.input_is_file() { 1 } else { 0 }).to_string(),
            /* 09 */ args.mode.weights_mode().to_string(),
            /* 10 */ weights.len().to_string(),
            /* 11.. */
            weights
                .iter()
                .map(f64::to_string)
                .collect::<Vec<String>>()
                .join(" "),
            data_in.join(" "),
        ]
        .join(" ");
        println!("octave args: {}", octave_args);
        let bytestring = octave_args.as_bytes();
        writer.write_all(bytestring)?;
    }
    println!("running octave...");
    let output = octave
        .wait_with_output()
        .context("failed to wait for output")?;
    let output_string = String::from_utf8_lossy(&output.stdout);
    println!("stdout: {}", &output_string);
    let octave_err = String::from_utf8_lossy(&output.stderr);
    if !octave_err.is_empty() {
        println!("stderr: {}", octave_err);
    }
    let mut res = output_string
        .lines()
        .skip_while(|&s| !s.contains("final opt"))
        .skip(1) // skip "final opt" string
        .map(str::trim_start)
        .map(str::parse::<f64>)
        .collect::<Result<Vec<_>, _>>()
        .expect("failed to parse octave output");
    let e_min = res
        .pop()
        .expect("res should always contain at least one element");

    match args.mode {
        Mode::TransferFunctionFIR { .. } => {
            println!("minimum error: {}", e_min);
            println!("FIR coefficients:");
            for coef in res{
                println!("{:.16}", coef)
            }
        },
        _ => {
            if res.len() & 1 == 1 {
                // is odd
                return Err(anyhow!("result parsing error: length is not even"));
            }
            //dbg!(&res);
            let mut res_iter = res.into_iter();
            let mut res_tuple = Vec::new();
            while let (Some(r), Some(theta)) = (res_iter.next(), res_iter.next()) {
                res_tuple.push((r, theta));
            }
            res_tuple.sort_by(|(_r1, t1), (_r2, t2)| t1.partial_cmp(t2).expect("should not contain NANs"));

            println!("minimum error: {}", e_min);
            for (r, theta) in res_tuple {
                println!("r: {:.16} theta: {:.16}", r, theta);
            }
        }
    }
    Ok(())
}
