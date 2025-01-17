use anyhow::{anyhow, Context, Result};
use clap::Parser;
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
struct Args {
    /// minimum frequency (normalised 0.0 to 1.0)
    #[arg(short = 'n', long, default_value_t = 0.0, value_parser=range_0_to_1, allow_hyphen_values=true)]
    wmin: f64,

    /// maximum frequency (normalised 0.0 to 1.0)
    #[arg(short = 'x', long, default_value_t = 1.0, value_parser=range_0_to_1, allow_hyphen_values=true)]
    wmax: f64,

    /// number of internal sampling points
    #[arg(short, long, default_value_t = 100)]
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

#[derive(clap::ValueEnum, Clone, Default, Debug, PartialEq, Serialize)]
#[serde(rename_all = "kebab-case")]
enum WeightsFCA {
    /// flat error weights
    Flat,
    /// custom user provided error weights
    Custom,
    /// error weights based on amplitude
    #[default]
    Amplitude,
}

impl WeightsFCA {
    fn to_usize(&self) -> usize {
        match self {
            WeightsFCA::Flat => 0,
            WeightsFCA::Custom => 1,
            WeightsFCA::Amplitude => 2,
        }
    }
}

#[derive(clap::ValueEnum, Clone, Default, Debug, PartialEq, Serialize)]
#[serde(rename_all = "kebab-case")]
enum WeightsFC {
    /// flat error weights
    #[default]
    Flat,
    /// custom user provided error weights
    Custom,
}

impl WeightsFC {
    fn to_usize(&self) -> usize {
        match self {
            WeightsFC::Flat => 0,
            WeightsFC::Custom => 1,
        }
    }
}

#[derive(clap::ValueEnum, Clone, Default, Debug, PartialEq, Serialize)]
#[serde(rename_all = "kebab-case")]
enum Algo {
    /// basic Grid based starting values + fminunc
    Grid,
    /// random starting positions + fminunc
    RandomUnc,
    /// random starting positions + fmincon
    RandomCon,
    /// particle swarm optimization
    #[default]
    Pso,
}

impl Algo {
    fn to_usize(&self) -> usize {
        match self {
            Algo::Grid => 0,
            Algo::RandomUnc => 1,
            Algo::RandomCon => 2,
            Algo::Pso => 3,
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
        #[arg(short, long, value_enum, default_value_t)]
        weights: WeightsFC,

        /// path to file with input data
        #[arg(short, long)]
        file: Option<String>,

        /// data
        data: Vec<f64>,
    },
    /// numerator followed by denominator
    #[clap(visible_alias = "tf")]
    TransferFunction {
        /// whether the input data contains error weigths
        #[arg(short, long, value_enum, default_value_t)]
        weights: WeightsFCA,

        /// path to file with input data
        #[arg(short, long)]
        file: Option<String>,

        /// data
        data: Vec<f64>,
    },
    /// impulse response sample points
    #[clap(visible_alias = "imp")]
    ImpulseResponse {
        /// whether the input data contains error weigths
        #[arg(short, long, value_enum, default_value_t)]
        weights: WeightsFCA,

        /// path to file with input data
        #[arg(short, long)]
        file: Option<String>,

        /// data
        data: Vec<f64>,
    },
}

impl Mode {
    fn adapter_path(&self) -> &'static str {
        match self {
            Mode::Gradient { .. } => "./octave_adapter_gradient.m",
            Mode::TransferFunction { .. } => "./octave_adapter_tf.m",
            Mode::ImpulseResponse { .. } => "./octave_adapter_impulse",
        }
    }

    fn has_input(&self) -> bool {
        let (file, data) = match self {
            Mode::Gradient { file, data, .. } => (file, data),
            Mode::TransferFunction { file, data, .. } => (file, data),
            Mode::ImpulseResponse { file, data, .. } => (file, data),
        };
        file.is_some() || !data.is_empty()
    }

    fn get_input(&self) -> Result<&Vec<f64>> {
        let (file, data) = match self {
            Mode::Gradient { file, data, .. } => (file, data),
            Mode::TransferFunction { file, data, .. } => (file, data),
            Mode::ImpulseResponse { file, data, .. } => (file, data),
        };
        // TODO: implement file input. It may be best to read and parse the file within octave
        if file.is_some() {
            todo!()
        }
        Ok(data)
    }

    fn weights_mode(&self) -> usize {
        match self {
            Mode::Gradient { weights, .. } => weights.to_usize(),
            Mode::TransferFunction { weights, .. } => weights.to_usize(),
            Mode::ImpulseResponse { weights, .. } => weights.to_usize(),
        }
    }
}

fn main() -> Result<()> {
    let args = Args::parse();

    let data_in = if !args.mode.has_input() {
        stdin()
            .lines()
            .collect::<Result<Vec<_>, _>>()?
            .iter()
            .flat_map(|s| s.split_whitespace())
            .inspect(|s| {
                dbg!(s);
            })
            .map(str::parse::<f64>)
            .map(|f| f.map(|g| g.to_string()))
            .collect::<Result<Vec<_>, _>>()?
    } else {
        args.mode
            .get_input()?
            .iter()
            .map(f64::to_string)
            .collect::<Vec<String>>()
    };
    /*if args.weights == Weights::Custom && data_in.len() & 1 == 1 {
        return Err(anyhow!(
            "number of data values and number of weights does not match: {} is odd",
            data_in.len()
        ));
    }*/
    let data_str = data_in.join(" ");

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
        let tmp = format!(
            "{wmin} {wmax} {wpoints} {order} {algo} {iterations} {weights} {graph} {data}",
            wmin = args.wmin,
            wmax = args.wmax,
            wpoints = args.points,
            order = args.order,
            algo = args.algo.to_usize(),
            iterations = args.iterations,
            weights = args.mode.weights_mode(), //TODO add field for number of weight values and number of data values
            graph = if args.graph { 1 } else { 0 },
            data = data_str,
        );
        println!("octave args: {}", tmp);
        let bytestring = tmp.as_bytes();
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
        println!("r: {} theta: {}", r, theta);
    }

    Ok(())
}
