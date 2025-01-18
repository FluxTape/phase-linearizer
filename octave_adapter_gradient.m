clear all
close all
pkg('load', 'optim');
pkg('load', 'control');

data_str   = fread( stdin, 'char' );
data_str   = char( data_str.' );
str_tokens = strsplit( data_str );
tokens     = cellfun( @str2double, str_tokens );
if isnan(tokens(end))
    tokens = tokens(1:end-1);
endif
err_at = find(isnan(tokens));
if !isempty(err_at)
    disp("failed to parse input at index:");
    err_at
    return
endif
w_start              = tokens(1)
w_end                = tokens(2)
w_points_internal    = round(tokens(3))
order                = round(tokens(4))
show_graph           = (tokens(5) > 0)
algo                 = round(tokens(6))
iterations           = round(tokens(7))
includes_err_weights = round(tokens(8))
length_data          = round(tokens(9))
length_weights       = round(tokens(10))
data_start = 11
data_end = data_start+length_data-1
weights_start = data_end+1
weights_end = weights_start+length_weights-1
data_p = tokens(data_start:data_end);
weights_p = tokens(weights_start:weights_end);

w_points = numel(data_p)
if (includes_err_weights > 0)
    gradient_ref = data_p;
    err_weights = weights_p;
else
    gradient_ref = data_p;
    err_weights  = ones(1, w_points);
endif

output_precision(16);
[opt, e_min] = octave_opt_ap(w_start, w_end, w_points_internal, order, algo, iterations, gradient_ref, err_weights, show_graph);
disp("final opt:");
disp([opt e_min]');
