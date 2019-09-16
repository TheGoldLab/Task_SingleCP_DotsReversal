function h = getSubjectCode()
% ask for subject's info to generate hash code
% requires DataHash
confirmed = false;
while ~confirmed
    subjInfo = struct();
    subjInfo.first = strtrim(...
        input('Enter subject first name (e.g. Robert): ', 's'));
    subjInfo.middle = strtrim(...
        input('Enter subject middle name(s) (e.g. Matthew Oscar): ', 's'));
    subjInfo.last = strtrim(...
        input('Enter subject last name (can be several words): ', 's'));
    subjInfo.dob = strtrim(...
        input('Enter subject DOB as YYYYMMDD, e.g. (19941224): ', 's'));
    
    disp('')
    disp('Entered subject info')
    disp(subjInfo)
    confirmSubjData = input('is the above info correct? (y/n) ', 's');
    if strcmp(confirmSubjData, 'y')
        h = matlab.lang.makeValidName(DataHash(subjInfo));
        confirmed = true;
    end
end
end