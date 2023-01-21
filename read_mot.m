function [mot_data,mot_header] = read_mot(file_path)
%Read an OpenSim compatible .mot file and return the full header + matrix form data
%ALSO WORKS FOR .sto FILES

%file_path = 'C:\Users\johnj\Research\Dissertation\Data\P004v2\Processed TRC and MOT\Run\JDX_P004_run_001.mot'
%file_path = this_ik_file

if ~contains(file_path, '.mot') && ~ contains(file_path, '.sto')
    error('File is not a MOT or STO file!');
end

%Read header
fid = fopen(file_path);
mot_header = {};  
f_line = 1;
end_header = 0;

while ~end_header
    %use fgets to retain newline character at end of each line (important!!!)
    this_line = fgets(fid);
    mot_header = [mot_header; this_line]; %Yeah yeah...
    f_line = f_line+1;
    if matches(strip(this_line), 'endheader')
        end_header = 1;
    end
end

%Get one more line after endheader for the columns
this_line = fgets(fid);
mot_header = [mot_header; this_line]; 


fclose(fid);
%Read data
%mot_data = dlmread(file_path, '\t', f_line,0); %Uncomment if you get funny results

%This is new way - can deal with \t\n at end of line
mot_data = readmatrix(file_path, 'FileType', 'text', ...
    'NumheaderLines', f_line, 'delimiter', '\t');

end


