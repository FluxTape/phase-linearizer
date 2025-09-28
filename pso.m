% based on https://github.com/mschof/ParticleSwarmOptimization/blob/master/PSO1.m
function [ret, ret_start, ret_best_costs] = pso(cf, nr_variables, var_min, var_max, max_iterations)

    %% Problem Definition
    % nr_variables                          % Number of variables unknown (part of the decision)
    variable_size = [1 nr_variables];       % Vector representation
    % var_min                               % Lower bound of decision space
    % var_max                               % Upper bound of decision space
  
    %% Parameter Adjustment
    swarm_size = 250;                       % Swarm size (number of particles)
    w = 1;                                  % Inertia coefficient                      
    w_damp = 0.98;                          % damping of inertia coefficient, lower = faster damping
    c1 = 2;                                 % Cognitive acceleration coefficient (c1 + c2 = 4)
    c2 = 2;                                 % Social acceleration coefficient (c1 + c2 = 4)
  
    %% Init
    template_particle.position = [];
    template_particle.velocity = [];
    template_particle.cost = 0;
    template_particle.best.position = [];   % Local best
    template_particle.best.cost = inf;       % Local best
  
    % Copy and put the particle into a matrix
    particles = repmat(template_particle, swarm_size, 1);
  
    % Initialize global best (current worst value, inf for minimization, -inf for maximization)
    global_best.cost = inf;
  
    for i=1:swarm_size
  
      % Initialize all particles with random position inside the search space
      position = [];
      for k = 1:nr_variables
        d = var_max(k) - var_min(k);
        position(k) = var_min(k) + d*rand(1);
      endfor
      particles(i).position = position;
  
      % Initiliaze velocity to the 0 vector
      particles(i).velocity = zeros(variable_size);
  
      % Evaluate the current cost
      particles(i).cost = cf(particles(i).position);
  
      % Update the local best to the current location
      particles(i).best.position = particles(i).position;
      particles(i).best.cost = particles(i).cost;
  
      % Update global best
      if (particles(i).best.cost < global_best.cost)
        global_best.position = particles(i).best.position;
        global_best.cost = particles(i).best.cost;
      endif
  
    endfor
  
    % Best cost at each iteration
    best_costs = zeros(max_iterations, 1);
  
  
    %% PSO Loop
  
    for iteration=1:max_iterations
  
      for i=1:swarm_size
  
        % Initialize two random vectors
        r1 = rand(variable_size);
        r2 = rand(variable_size);
  
        % Update velocity
        particles(i).velocity = (w * particles(i).velocity) ...
          + (c1 * r1 .* (particles(i).best.position - particles(i).position)) ...
          + (c2 * r2 .* (global_best.position - particles(i).position));
  
        % Update position
        particles(i).position = particles(i).position + particles(i).velocity;

        % Clamp position to limits
        for k = 1:nr_variables
          if (particles(i).position(k) < var_min(k))
            particles(i).position(k) = var_min(k);
            particles(i).velocity(k) = -particles(i).velocity(k); 
          elseif (particles(i).position(k) > var_max(k))
            particles(i).position(k) = var_max(k);
            particles(i).velocity(k) = -particles(i).velocity(k); 
          endif
        endfor
  
        % Update cost
        particles(i).cost = cf(particles(i).position);
  
        % Update local best (and maybe global best) if current cost is better
        if (particles(i).cost < particles(i).best.cost)
          particles(i).best.position = particles(i).position;
          particles(i).best.cost = particles(i).cost;
  
          % Update global best
          if (particles(i).best.cost < global_best.cost)
            global_best.position = particles(i).best.position;
            global_best.cost = particles(i).best.cost;
          endif
  
        endif
  
      endfor
  
      % Get best value
      best_costs(iteration) = global_best.cost;
  
      % Display information for this iteration
      % disp(["Iteration " num2str(iteration) ": best cost = " num2str(best_costs(iteration))]);
  
      % Damp w
      w = w * w_damp;

      if (iteration == 1)
        ret_start = global_best.position;
      endif
  
    endfor
  
    %% Print results
    ["Best cost: " num2str(global_best.cost)]

    ret = global_best.position;
    ret_best_costs = best_costs';
  
  endfunction