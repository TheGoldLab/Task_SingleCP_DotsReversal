function nkvp=buildkvpairs(kvPairs, bseq)
% returns a cell of key-value pairs where all the keys are taken from bseq
% and all the matching pairs are taken from kvPairs
% Note: no ordering is performed
% Note2: all elements from bseq must be in kvPairs and no duplicates can
% exist in bseq

numOldKeys = length(kvPairs)/2;

% check whether all keys from kvPairs are already in bseq
allIn=true;
for i=1:numOldKeys
    kidx = 2*i-1;
    if ~ismember(kvPairs{kidx}, bseq)
        allIn = false;
        break
    end
end

if allIn
    nkvp = kvPairs;
else
    while ~allIn
        for i=1:numOldKeys
            kidx = 2*i-1;
            if ~ismember(kvPairs{kidx}, bseq)
                kvPairs(kidx:kidx+1)=[];
                break
            end
        end
        numOldKeys = length(kvPairs)/2;
        
        inCount = 0;
        % count number of valid keys
        for i=1:numOldKeys
            kidx = 2*i-1;
            if ~ismember(kvPairs{kidx}, bseq)
                break
            else
                inCount = inCount + 1;
            end
        end
        allIn = inCount == numOldKeys;
    end
    nkvp=kvPairs;
end
end