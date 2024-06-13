data_str   = fread( stdin, 'char' );
data_str   = char( data_str.' );
str_tokens = strsplit( data_str ); 
tokens     = cellfun( @str2double, str_tokens );
w_start              = tokens(1)
w_end                = tokens(2)
w_points_internal    = round(tokens(3))
order                = round(tokens(4))
divs_search_grid     = round(tokens(5))
includes_err_weights = round(tokens(6))
data_p = tokens(7:end-1)
if (includes_err_weights > 0)
    w_points = numel(data_p)/2
    gradient_ref = data_p(1:w_points)
    err_weights  = data_p(w_points:end)
else
    w_points = numel(data_p)
    gradient_ref = data_p
    err_weights  = ones(1, w_points)
endif

opt = octave_opt_ap(w_start, w_end, w_points_internal, order, divs_search_grid, gradient_ref, err_weights)

