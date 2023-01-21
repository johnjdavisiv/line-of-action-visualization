% Plot muscle forces and lines of action at their origins on a mesh
% John J Davis
% john@johnjdavis.io

%Load our model's femur (converted from vtp to stl using online tool)
% at https://www.weiy.city/tools__trashed/3d-files-converter/
femur_mesh_file = 'r_femur.stl';
femur_mesh = stlread(femur_mesh_file);

%Flip axes to align with OpenSim conventions
x_old = femur_mesh.Points(:,1);
y_old = femur_mesh.Points(:,2);
z_old = femur_mesh.Points(:,3);
y_new = -1*z_old;
z_new = y_old;

%New mesh in OpenSim coordinates
femur_mesh_rotated = triangulation(femur_mesh.ConnectivityList, [x_old, y_new, z_new]);

% Read result files
so_results_file = 'subject_scale_run_StaticOptimization_force.sto'; %Static optimization muscle forces
mfd_run_points_file = 'line_of_action_results/muscle_line_of_action_local_MuscleForceDirection_attachments.sto'; %Muscle force direction points
mfd_run_vectors_file = 'line_of_action_results/muscle_line_of_action_local_MuscleForceDirection_vectors.sto'; %Muscle force direction vectors

[so_data, so_header] = read_mot(so_results_file); %read_mot() works on .sto too
so_cols = strip(strsplit(so_header{end}, '\t'));

[point_data, point_header] = read_mot(mfd_run_points_file);
point_cols = strip(strsplit(point_header{end}, '\t'));

[vector_data, vector_header] = read_mot(mfd_run_vectors_file);
vector_cols = strip(strsplit(vector_header{end}, '\t'));

time_col = so_data(:,1);

%% Combine forces and vectors

%Ugly regexp to get all muscles (can hand-code your own list if short)
%Could also load your model and use OpenSim API to loop through and get muscles that attach on bone
%of interest.
all_muscles = unique(regexprep(vector_cols(2:end), '_[X|Y|Z][1|2].*', ''))';

%Bone we care about (hard-coded for demo)
bone_name = 'femur_r';

%Offload the heavy lifting to a helper function
force_struct = get_bone_forces_and_points_for_plot(point_data, point_cols, ...
    vector_data, vector_cols, so_data, so_cols, all_muscles, bone_name); 
%Forces/vectors are returned in the struct with a field for each muscle


%% Plot! 

% --- Some hardcoded things for the plot
f_color_max = 4500; %Max force in Newtons on the colormap (adjust as needed)
force_colors = hot(100); %Hot colormap looks nice - add more number if you want finer grained colors
force_colors = force_colors(10:85,:); %Avid blacks and whites at either ends
force_mag_index = linspace(0, f_color_max, size(force_colors,1)); %For indexing into
%Make a nice scaled colormap

%    Set plot params
alf = 0.3; %Force line transparency
line_width = 3;
colorbar_text_size = 28;

% ----- 

n_muscles = length(all_muscles);
plot_timerange = [0.863, 1.546]; %Just plot one gait cycle
%Inclusive [a, b]

%Plot just this step
time_ix = find(time_col >= plot_timerange(1) & time_col <= plot_timerange(2));


f = figure('units', 'normalized', 'position', [0.05 0.05 0.85 0.85]);

%A splash of color...
new_cmap = bone(100); %A happy coincidence of a colormap name
colormap(new_cmap(60:90,:)); %Take middle ~60% of the "bone" colormap 
axis equal;
%If you don't provide the C matrix Matlab literally sets C=Z when plotting
%Therefore C is a matrix the same size as your heights matrix (Z) so bone changes color as height
%increases, which can look odd with extreme color scales

hold on;
xlabel('x axis');
ylabel('y axis');
zlabel('z axis');


%Plot the bone! 
tsurf = trisurf(femur_mesh_rotated, 'facealpha', 1, 'edgecolor', '#808080');
%Can set edgecolor to 'black' to see bone mesh easier or 'none' for smooth-shaded bone

%Orient camera
campos([2.9021, -2.6507, 1.0394]);
biggest_f = 0; %For scaling colormap after the fact
scale_factor = 1e4; %Scale muscle forces by arbitrary amount for plotting
%10e4 looks nice for running
%Alternatively can try log or sqrt scaling for visualization 

%For this demo, plot all muscles attaching to the femur
all_muscles = fieldnames(force_struct);


for t=1:length(time_ix)
    t_ix = time_ix(t);

    %Get points/vectors for muscles at this timepoint (farm out to function)
    [x,y,z,u,v,w] = force_struct_to_xyz_uvw(force_struct, t_ix, 'force', all_muscles);
    
    %Plot each muscle at this timepoint
    for m=1:length(all_muscles)
        f_mag = sqrt(u(m).^2 + v(m).^2 + w(m).^2);
        %Carpentry function for fine tuning colormap
        if f_mag > biggest_f
                biggest_f = f_mag;
                %Uncomment to print for tuning colormap
                %fprintf('Fmax: %.0f N\n', biggest_f);
        end
        %What color should this line be? Per colormap/force relationship
        [~, color_index] = min(abs(f_mag - force_mag_index));
        line_color = [force_colors(color_index,:), alf]; %Tack on transparency
        
        %Want to draw line segments as two-element sets of X, Y, Z where X(1) is the x coord of
        %attachment point and X(2) is X(1) + x component of direction of arrow (or force),
        % divided by our scale factor (arbitrary, choose one that looks nice)
        
        line_x = [x(m), x(m) + u(m)/scale_factor];
        %Notice changes!!! Coordinate system swap!
        line_y = -1*[z(m), z(m) + w(m)/scale_factor];
        line_z = [y(m), y(m) + v(m)/scale_factor];
        
        plot3(line_x, line_y, line_z, 'color', line_color, 'LineWidth',line_width);
    end
end


%Note! Some forces will "float" in mindair if you have the effective origin points enabled in the
%Line of Action plugin. Depending on your application this might be a good idea or a bad idea.
%See here for more: https://www.youtube.com/watch?v=0e6vQV_ioCI&t=15m42s


%Add colorbar
ax1 = gca;
%uncomment to hide the 3D axis (eg for nice images for presentations)
%ax1.Visible = 'off';

hold on;
ax2 = axes('Position',ax1.Position,...
  'XColor',[1 1 1],...
  'YColor',[1 1 1],...
  'Color','none',...
  'XTick',[],...
  'YTick',[], 'visible', 'off');


colormap(ax2, force_colors)
cb = colorbar(ax2);
cb.Limits = [0 1]; %"fake" limits, we just relabel them with the forces.
%Must relabel...

real_ticks = 0:1000:f_color_max;
map_ticks = real_ticks/f_color_max;
%Real slick trick right here
tick_string = arrayfun(@(x)sprintf('%i N',x), real_ticks, 'uniformoutput', false);

cb.Ticks = map_ticks;
cb.TickLabels = tick_string;
cb.FontSize = colorbar_text_size;
cb.Location = 'east';
orig_cb_position = cb.Position;

%First element of the added vector movesit to the left, third element makes it fatter (more negative
%for wider bar);
cb.Position = orig_cb_position - [0.05 -0.05 -0.007 0.1];

