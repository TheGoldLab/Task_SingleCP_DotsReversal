function th=plotCurve(topnode)
task=topnode.children{1};
psiParamsIndex = qpListMaxArg(task.quest.posterior);
psiParamsQuest = task.quest.psiParamsDomain(psiParamsIndex,:);
th=psiParamsQuest(1);
p=.5:.01:1;
y=zeros(1,1);
for pidx=1:length(p)
    test=task.getQuestCoh(p(pidx));
    if isreal(test)
        y(pidx)=test;
    end
end
p=p(1:length(y));
plot(y*100,p*100,'linewidth',3)
hold on
plot([th,th],[50,100],'-r')
hold off
title('your psychophysical curve!')
xlabel('coherence')
ylabel('percent correct')
xlim([0,100])
ylim([50,100])
ax=gca;
ax.FontSize=20;

end