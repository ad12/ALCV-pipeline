function [path] = check_and_create_dir(path)

if (exist(path, 'dir') ~= 7)
    mkdir(path);
end

end
