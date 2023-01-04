function estimate_L(design_id, band, smooth)

    % get design
    design = yaml.loadFile(fullfile( ...
        'simulation', 'designs', sprintf('%s.yml', design_id) ...
        ));
    
    % get configs
    d = dir(fullfile('simulation', 'data', design_id));
    dfolders = d([d(:).isdir]);
    config_ids = dfolders(~ismember({dfolders(:).name},{'.','..'}));
    
    % estimate Ls
    disp("----- START L ESTIMATION -----")
    start = tic;
    parfor i = 1:length(config_ids)
        config_id = config_ids(i).name;
        fprintf("\t%s\n", config_id)
        estimate_L_for_config(config_id, design_id, band, smooth, design.scratch_root);
    end
    comp_time = toc(start);
    disp("----- END L ESTIMATION -----")
    fprintf("Elapsed Time: %.03f s\n", comp_time)

end


