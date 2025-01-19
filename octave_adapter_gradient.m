clear all
close all
warning('off','Octave:shadowed-function')
pkg('load', 'optim');
pkg('load', 'control');


data_str   = fread( stdin, 'char' );
data_str   = char( data_str.' );
str_tokens = strsplit( data_str );
tokens     = cellfun( @str2double, str_tokens );
if isnan(tokens(end))
    tokens = tokens(1:end-1);
endif

w_start              = round(tokens(1))
w_end                = tokens(2)
w_points_internal    = round(tokens(3))
order                = round(tokens(4))
show_graph           = (tokens(5) > 0)
algo                 = round(tokens(6))
iterations           = round(tokens(7))
input_is_file        = (tokens(8) > 0)
includes_err_weights = round(tokens(9))
length_weights       = round(tokens(10))
weights_start = 11
weights_end   = weights_start + length_weights - 1
data_start    = weights_end + 1

err_at = find(isnan(tokens(1:weights_end)));
if !isempty(err_at)
    disp("failed to parse input at index:");
    err_at
    return
endif
weights_p = tokens(weights_start:weights_end);

data_p = [];
if (input_is_file)
    filename = [str_tokens(data_start:end)]{1}
    data_p = csvread(filename);
else
    data_p = tokens(data_start:end);
endif


err_at = find(isnan(data_p));
if !isempty(err_at)
    disp("failed to parse data section at index:");
    err_at
    return
endif

gradient_ref = data_p;
w_points = numel(data_p)
if (includes_err_weights > 0)
    err_weights = weights_p;
else
    err_weights  = ones(1, w_points);
endif

output_precision(16);
[opt, e_min] = octave_opt_ap(w_start, w_end, w_points_internal, order, algo, iterations, gradient_ref, err_weights, show_graph);
disp("final opt:");
disp([opt e_min]');
