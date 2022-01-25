function nkvp=trimkvpairs(kvPairs, bseq)
% removes the key-value pairs from kvPairs whose keys are not in bseq

numOldKeys = length(kvPairs)/2;
numNewKeys = length(bseq);

while numOldKeys > numNewKeys
    for i=1:numOldKeys
        kidx = 2*i-1;
        if ~ismember(kvPairs{kidx}, bseq)
            kvPairs(kidx:kidx+1)=[];
            break
        end
    end
    numOldKeys = length(kvPairs)/2;
end
nkvp=kvPairs;
end