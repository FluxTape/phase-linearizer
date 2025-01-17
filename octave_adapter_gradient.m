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
algo                 = round(tokens(5))
iterations           = round(tokens(6))
includes_err_weights = round(tokens(7))
show_graph = (tokens(8) > 0)
data_p = tokens(9:end);

if (includes_err_weights > 0)
    w_points = idivide(numel(data_p), int32(2), "fix")
    gradient_ref = data_p(1:w_points)
    err_weights  = data_p(w_points+1:end)
    if numel(gradient_ref) != numel(err_weights)
        disp("gradient and err weights have mismatched length");
        return
    endif
else
    w_points = numel(data_p)
    gradient_ref = data_p
    err_weights  = ones(1, w_points)
endif

output_precision(16);
[opt, e_min] = octave_opt_ap(w_start, w_end, w_points_internal, order, algo, iterations, gradient_ref, err_weights, show_graph);
disp("final opt:");
disp([opt e_min]');
