function [mot_data,mot_header] = read_mot(file_path)
%Read an OpenSim compatible .mot file and return the full header + matrix form data
%ALSO WORKS FOR .sto FILES

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
    mot_header = [mot_header; this_line]; %IGNORE linting error, this is right way to do it
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
%(or have old version of MATLAB) - no promises this works though

%This is new way - can deal with \t\n at end of line
mot_data = readmatrix(file_path, 'FileType', 'text', ...
    'NumheaderLines', f_line, 'delimiter', '\t');

end


