import csv
import statistics
import traceback

def wrap_in_numprint(s: str) -> str:
    return "\\numprint{" + s + "}"

def get_timing(algo: str, test_function: str) -> str:
    time = ""
    try:
        with open(f"{algo}/{test_function}_timing.csv", newline='') as csvfile:
            csvreader = csv.reader(csvfile, delimiter=",", quotechar='"')
            csviter = iter(csvreader)
            _titles = next(csviter)
            timings = next(csviter)
            t_avg = f"{float(timings[1]):.1f}"
            t_sig = f"{float(timings[2]):.2f}"
            time = "\\numprint{" + t_avg + "}" + " \\numprint{\\pm " + t_sig + "}s"
    except Exception:
        pass
    return time

def get_err_vals(algo: str, test_function: str) -> (str, str, str, str):
    max_error = ""
    avg_error = ""
    med_error = ""
    min_error = ""
    try:
        with open(f"{algo}/{test_function}.csv", newline='') as csvfile:
            csvreader = csv.reader(csvfile, delimiter=",", quotechar='"')
            e_min = []
            for row in csvreader:
                e_min.append(float(row[0]))
            #print(e_min)
            max_error = f"{max(e_min):.6f}"
            avg_error = f"{statistics.mean(e_min):.6f}"
            med_error = f"{statistics.median(e_min):.6f}"
            min_error = f"{min(e_min):.6f}"
    except Exception as err:
        #print(traceback.format_exc())
        pass
    return (max_error, avg_error, med_error, min_error)

def main():
    algorithms = ["grid", "random-unc", "random-con", "pso-m"]
    test_functions = {
        "cheby_lp": "Cheby LP",
        "cheby_hp": "Cheby HP",
        "cheby_bp": "Cheby BP",
        "peak_dip": "Peak \\& Dip",
        "stop_lp": "Stop \\& LP"
    }
    columns = ["Test function", "Algorithm", "Time", "max error", "average error", "median error", "min error"]

    columns = [
        "\\multicolumn{1}{|c|}{" + columns[0] + "}",
        *["\\multicolumn{1}{c|}{" + c + "}" for c in columns[1:]]
    ]
    print("\\hline")
    print(" & ".join(columns), "\\\\")
    for test_function in test_functions.keys():
        print("\\hline")
        tf = "\\multirow{4}{4em}{" + test_functions[test_function] + "}"
        for algo in algorithms:
            time = get_timing(algo, test_function)
            (max_error, avg_error, med_error, min_error) = get_err_vals(algo, test_function)
            row = [
                tf, 
                algo, 
                time, 
                wrap_in_numprint(max_error), 
                wrap_in_numprint(avg_error), 
                wrap_in_numprint(med_error),
                wrap_in_numprint(min_error)
            ]
            print(" & ".join(row), "\\\\")
            tf = ""
    print("\\hline")

if __name__ == "__main__":
    main()
