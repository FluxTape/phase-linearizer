import csv
#import statistics
import traceback

def wrap_in_numprint(s: str) -> str:
    return "\\numprint{" + s + "}"

def get_fir_data(algo: str, test_function: str) -> (str, str, str, str, str):
    try:
        with open(f"fir/{test_function}.csv", newline='') as csvfile:
            csvreader = csv.reader(csvfile, delimiter=",", quotechar='"')
            for row in csvreader:
                weighted_error = f"{float(row[2]):.6f}"
                max_mag_err = f"{float(row[4]):.3f}" #cropped
                order_param = f"{int(row[5])}"
                order_real = f"{int(row[6])}"
                mean_weighted_grd = f"{float(row[7]):.1f}"
                if "rect" in algo and row[0] == "0":
                    return (order_param, order_real, max_mag_err, mean_weighted_grd, weighted_error)
                if "hamming" in algo and row[0] == "1":
                    return (order_param, order_real, max_mag_err, mean_weighted_grd, weighted_error)
    except Exception:
        print(traceback.format_exc())
        pass
    return ("", "", "", "", "")

def get_iir_data(algo: str, test_function: str) -> (str, str, str, str, str):
    try:
        with open(f"{algo}/{test_function}.csv", newline='') as csvfile:
            rows = list(csv.reader(csvfile, delimiter=",", quotechar='"'))
            e_min_i = []
            for row in rows:
                e_min_i.append(float(row[0]))
            (e_min, e_min_idx) = min([(j, i) for i, j in enumerate(e_min_i)])
            min_error = f"{e_min:.6f}"

            order_real = int(rows[e_min_idx][2])
            order_param = order_real//2

            # TODO: write to csv data and get target grd from there instead of manually here
            mean_weighted_grd = 0
            match test_function:
                case "cheby_lp":
                    mean_weighted_grd = 22.72202140149497
                case "cheby_hp":
                    mean_weighted_grd = 41.71154290037063
                case "cheby_bp":
                    mean_weighted_grd = 39.86503370928028
                case "peak_dip":
                    mean_weighted_grd = 10.00178885744946
                case "stop_lp":
                    mean_weighted_grd = 24.34155912097887
            mean_weighted_grd = f"{mean_weighted_grd:.1f}"
            max_mag_err = "0"
            return (str(order_param), str(order_real), max_mag_err, mean_weighted_grd, min_error)
    except Exception:
        print(traceback.format_exc())
        pass
    return ("", "", "", "", "")

def main():
    algorithms = ["random-unc", "fir (hamming)", "fir (rect)"]
    test_functions = {
        "cheby_lp": "Cheby LP",
        "cheby_hp": "Cheby HP",
        "cheby_bp": "Cheby BP",
        "peak_dip": "Peak \\& Dip",
        "stop_lp": "Stop \\& LP"
    }
    columns = ["Test function", "Algorithm", "ord. (param)", "ord.", "mean grd.", "mag err", "min error"]

    columns = [
        "\\multicolumn{1}{|c|}{" + columns[0] + "}",
        *["\\multicolumn{1}{c|}{" + c + "}" for c in columns[1:]]
    ]
    print("\\hline")
    print(" & ".join(columns), "\\\\")
    for test_function in test_functions.keys():
        print("\\hline")
        tf = "\\multirow{3}{3em}{" + test_functions[test_function] + "}"
        for algo in algorithms:
            if algo == "random-unc":
                (order_param, order_real, max_mag_err, mean_weighted_grd, weighted_error) = get_iir_data(algo, test_function)
            else:
                (order_param, order_real, max_mag_err, mean_weighted_grd, weighted_error) = get_fir_data(algo, test_function)
            row = [
                tf, 
                algo,
                order_param, 
                order_real, 
                wrap_in_numprint(mean_weighted_grd), 
                f"{wrap_in_numprint(max_mag_err)} dB", 
                wrap_in_numprint(weighted_error)
            ]
            print(" & ".join(row), "\\\\")
            tf = ""
    print("\\hline")

if __name__ == "__main__":
    main()
