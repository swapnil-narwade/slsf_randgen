classdef simple_generator < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant = true)
       DEBUG = true;
    end
    
    properties
        NUM_BLOCKS = 5;
        
        slb;                        % Object of class slblocks
        
        sys = 'sampleModel';
        
        candi_blocks;               % Candidate Blocks
        
        a = 2;
    end
    
    methods
        function obj = simple_generator(num_blocks, model_name)
            % Constructor for simple_generator
            obj.NUM_BLOCKS = num_blocks;
            obj.sys = model_name;
        end
        
        
        
        function obj = go(obj)
            obj.p('--- Starting ---');
            
            obj.init();
                        
            obj.get_candidate_blocks();
            obj.draw_blocks();
            obj.connect_blocks();
            
            fprintf('--Done Connecting!--\n');
            sim(obj.sys);    
            
            fprintf('-- END --\n');
        end
        
        
        
        function obj = init(obj)
            % Perform Initialization
            
            obj.a = 1;
                        
            obj.slb = slblocks(obj.NUM_BLOCKS);
            
            new_system(obj.sys);
            open_system(obj.sys);
        end
        
        
        
        function obj = p(obj, str)
            % Prints str if Debug Mode.
            if obj.DEBUG
                display(str);
            end
        end
        
        
        
        function obj = get_candidate_blocks(obj)
            all = obj.get_all_simulink_blocks();  
            obj.candi_blocks = cell(1, obj.NUM_BLOCKS);
            rand_vals = randi([1, numel(all)], 1, obj.NUM_BLOCKS);
            
            for index = 1:obj.NUM_BLOCKS
                obj.candi_blocks{index} = all{rand_vals(index)};
            end
        end
        
        
        
        function ret = get_all_simulink_blocks(obj)
            ret = {'simulink/Sources/Constant', 'simulink/Sinks/Scope', 'simulink/Sources/Constant', 'simulink/Sinks/Display', 'simulink/Math Operations/Add'};
        end
        
        
        
        function obj = connect_blocks(obj)
            % CONNECT BLOCKS
            
            num_inp_ports = obj.slb.num_inp_ports;
            num_oup_ports = obj.slb.num_oup_ports;
            
            inp_blocks = obj.slb.inp.blocks;
            num_inp_blocks = obj.slb.inp.len;
            
            oup_blocks = obj.slb.oup.blocks;
            num_oup_blocks = obj.slb.oup.len;
            
            while_it = 0;
            
            while num_inp_ports > 0 || num_oup_ports > 0
                
                fprintf('-----\n');
                
                while_it = while_it + 1;
    
                fprintf('Num Input port: %d; num output port: %d\n', num_inp_ports, num_oup_ports);
                
                r_i_blk = 0;
                r_i_port = 0;
                
                r_o_blk = 0;
                r_o_port = 0;
                
                new_inp_used = false;
                new_oup_used = false;

                if num_inp_ports > 0
                   % choose an input port
                   fprintf('(d) num_inp_blk: %d\n', num_inp_blocks);
                   [r_i_blk, r_i_port] = obj.choose_bp(num_inp_blocks, inp_blocks, obj.slb.inp_ports);
                   
                   new_inp_used = true;
                   
                   
%                    rand_num = randi([1, num_inp_blocks], 1, 1);
%                    r_i_blk = inp_blocks{rand_num(1)};
% 
%                    % get a port of this input block
%                    t_all_ports = obj.slb.inp_ports{r_i_blk};
% 
%                    r_i_port = 0;
% 
%                    for t_i = t_all_ports
%                        r_i_port = r_i_port + 1;
% 
%                        if t_i{1} == 0
%                            break;
%                        end
%                    end

                end

                if num_oup_ports > 0
                    % Choose output port
                    
                    % Choose block not already taken for input.
                    
                    fprintf('(d) num_oup_blk: %d\n', num_oup_blocks);  
                    
%                     if r_i_blk > 0
%                         [op_blk_len, op_blk] = obj.del_from_cell(r_i_blk, num_oup_blocks, oup_blocks);
%                     else
%                         op_blk_len = num_oup_blocks;
%                         op_blk = oup_blocks;
%                     end
%                     
%                     [r_o_blk, r_o_port] = obj.choose_bp(op_blk_len, op_blk, obj.slb.oup_ports);
                    try
                        [r_o_blk, r_o_port] = obj.choose_bp_without_chosen(num_oup_blocks, oup_blocks, obj.slb.oup_ports, r_i_blk);
                    catch e
                        % Possible clause: only one output block available
                        % and it's same as the chosen input block for this
                        % iteration.
                        
                        if num_inp_blocks > 1
                            fprintf('SKIPPING THIS ITERATION...');
                            continue;
                        else
                            % Can not use this output block. pick another
                            % in later code
                            
                        end
                    end
                        
                    new_oup_used = true;

%                    rand_num = randi([1, num_oup_blocks], 1, 1);
%                    r_o_blk = oup_blocks{rand_num(1)};
% 
%                    % get a port of this output block
%                    t_all_ports = obj.slb.oup_ports{r_o_blk};
% 
%                    r_o_port = 0;
% 
%                    for t_i = t_all_ports
%                        r_o_port = r_o_port + 1;
% 
%                        if t_i{1} == 0
%                            break;
%                        end
%                    end

                end
                
                if r_i_port == 0 || r_i_blk == 0
                    fprintf('No new inputs available!\n');
                    [r_i_blk, r_i_port] = obj.choose_bp(obj.slb.inp.len, obj.slb.inp.blocks, obj.slb.inp_ports);
                end
                
                if r_o_port == 0 || r_o_blk == 0
                    fprintf('No new outputs available!\n');
                    [r_o_blk, r_o_port] = obj.choose_bp_without_chosen(obj.slb.oup.len, obj.slb.oup.blocks, obj.slb.oup_ports, r_i_blk);
                end
                
                fprintf('Input: Blk %d Port %d chosen.\n', r_i_blk, r_i_port);
                fprintf('Output: Blk %d Port %d chosen.\n', r_o_blk, r_o_port);

                % Add line
                t_i = strcat(obj.slb.all{r_i_blk}, '/', int2str(r_i_port));
                t_o = strcat(obj.slb.all{r_o_blk}, '/', int2str(r_o_port));
%                 disp(t_i);

                try
                    add_line(obj.sys, t_o, t_i, 'autorouting','on')
                catch e
                    fprintf('Error: %s', e.identifier);
                    fprintf('[!] RETURNGING FROM BLOCK CONNECTION...');
                    break;
                end
                
                % Mark used blocks/ports
                
                if new_inp_used
                    obj.slb.inp_ports{r_i_blk}{r_i_port} = 1;
                    
                    if obj.is_all_ports_used(obj.slb.inp_ports{r_i_blk})
                        fprintf('ALL inp PORTS OF BLOCK IS USED: %d\n', r_i_blk);
                        [num_inp_blocks, inp_blocks] = obj.del_from_cell(r_i_blk, num_inp_blocks, inp_blocks);
                    end
                    
                    num_inp_ports = num_inp_ports - 1;
                end
                
                if new_oup_used
                    obj.slb.oup_ports{r_o_blk}{r_o_port} = 1;
                    
                    if obj.is_all_ports_used(obj.slb.oup_ports{r_o_blk})
                        fprintf('ALL oup PORTS OF BLOCK IS USED: %d\n', r_o_blk);
                        [num_oup_blocks, oup_blocks] = obj.del_from_cell(r_o_blk, num_oup_blocks, oup_blocks);
                    end
                    
                    num_oup_ports = num_oup_ports - 1;
                end
                
              
%                 if while_it >= 2                
%                     break;  % After one iteration
%                 end


            end
           
        end
        
        
        
        function [ret_len, ret_cell] = del_from_cell(obj, sub, num_target, target)
            % If `sub` is one of the elements of the cell `target`, then
            % it is removed.
            
            is_found = false;
            
            for inx = 1 : num_target
                if target{inx} == sub
                    is_found = true;
                    target{inx} = [];
                    break;
                end
            end
            
            if is_found
                ret_cell = target(~cellfun(@isempty, target));    % Removes empty cell
                ret_len = num_target - 1;
            else
                ret_cell = target;
                ret_len = num_target;
            end
            
        end
        
        
        
        function ret = is_all_ports_used(obj, ports)
            ret = true;
            
            for i_p = ports
                if i_p{1} == 0
                    ret = false;
                    break;
                end
            end
        end
        
        
        
        function [r_blk, r_port] = choose_bp(obj, num_blocks, blocks, ports)
            % Choose a block and pointer
            
            % choose a block
           rand_num = randi([1, num_blocks], 1, 1);
           r_blk = blocks{rand_num(1)};

           % get a (unused prefered, else last) port of this block
           t_all_ports = ports{r_blk};

           r_port = 0;

           for t_i = t_all_ports
               r_port = r_port + 1;

               if t_i{1} == 0
                   break;
               end
           end
            
        end
        
        
        
        
        
        function [r_blk, r_port] = choose_bp_without_chosen(obj, num_blocks, blocks, ports, chosen)
            % Choose a block except `chosen`, then choose a port from it.
            
            if chosen > 0
                [blk_len, blk] = obj.del_from_cell(chosen, num_blocks, blocks);
            else
                blk_len = num_blocks;
                blk = blocks;
            end

            [r_blk, r_port] = obj.choose_bp(blk_len, blk, ports);
            
        end
        
        
        
        function obj = draw_blocks(obj)
            % Draw blocks in the screen
            
            obj.p('DRAWING BLOCKS...');
            
            pos_x = 30;
            pos_y = 30;

            width = 60;
            height = 60;

            hz_space = 100;
            vt_space = 150;

            blk_in_line = 3;

            cur_blk = 0;

            x = pos_x;
            y = pos_y;
            
            disp('Candidate Blocks:');
            disp(obj.candi_blocks);

            for block_name = obj.candi_blocks
                cur_blk = cur_blk + 1;          % Create block name
                
                h_len = x + width;

                pos = [x, y, h_len, y + height];

                this_blk_name = strcat('bl', num2str(cur_blk));

                % Add this block name to list of all added blocks
                obj.slb.all{cur_blk} = this_blk_name;

                this_blk_name = strcat('/', this_blk_name);

                h = add_block(block_name{1}, [obj.sys, this_blk_name], 'Position', pos);
                

                % Get its inputs and outputs
                ports = get_param(h, 'Ports');

                obj.slb.new_block_added(cur_blk, ports);

                % Update x
                x = h_len;

                % Update y
                if rem(cur_blk, blk_in_line) == 0
                    y = y + vt_space;
                    x = pos_x;
                else
                    x = x + hz_space;
                end

            end
            
        end
        
        
    end
    
end


