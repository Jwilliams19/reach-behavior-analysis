function alignment=markOptoOnlyNoCueTrials(alignment)

% enters trials where opto only turned on (no cue) into 'optoOnly'

event_thresh=0.5;
max_time_between_cue_and_opto=0.5; % in seconds
opto_duration=1; % in seconds
% convert to ms
max_time_between_cue_and_opto=max_time_between_cue_and_opto*1000;
opto_duration=opto_duration*1000;
temp=abs(diff(alignment.timesfromarduino));
temp=temp(temp~=0);
max_inds=floor(max_time_between_cue_and_opto./mode(temp));
duration_inds=floor(opto_duration./mode(temp));

alignment.optoOnly=zeros(size(alignment.cue));

alignment.falseCueOn=zeros(size(alignment.cue));
pelletPresented=alignment.pelletPresented;
pelletLoaded=alignment.pelletLoaded;
optoOn=alignment.optoOn;
cue=alignment.cue;
[~,loads]=findpeaks(pelletLoaded,'MinPeakProminence',event_thresh);
[~,presents]=findpeaks(pelletPresented,'MinPeakProminence',event_thresh);
[~,cues]=findpeaks(cue,'MinPeakProminence',event_thresh);
[~,optos]=findpeaks(optoOn,'MinPeakProminence',event_thresh);
% find presents just preceding cues
presents_preceding=nan(1,length(cues));
for i=1:length(cues)
    currcue=cues(i);
    temp=currcue-presents;
    temp(temp<0)=nan;
    [~,mind]=nanmin(temp);
    presents_preceding(i)=presents(mind);
end
presentToCueDelay=mode(cues-presents_preceding);
% for trials where pellet was presented but cue did not go off, add false
% cue
didload=nan(1,length(presents));
for i=1:length(presents)-5
    % iterate through each wheel turn
    currpresent=presents(i);
    nextpresent=presents(i+1);
    % did load this trial?
    if any(loads>currpresent & loads<nextpresent)
        didload(i)=1;
    else
        didload(i)=0;
    end
end
didcue=nan(1,length(presents));
for i=6:length(presents)
    % iterate through each wheel turn
    currpresent=presents(i);
    if i+1>length(presents)
        nextpresent=length(pelletPresented);
    else
        nextpresent=presents(i+1);
    end
    if any(cues>currpresent & cues<nextpresent)
        didcue(i)=1;
    else
        didcue(i)=0;
    end
end
trialsWithPelletWithoutCue=didcue(6:end)-didload(1:end-5);
% mark these trials as false cues
temp=6:length(presents);
presentIndsForFalseCues=temp(trialsWithPelletWithoutCue~=0);
presentsForFalseCues=presents(presentIndsForFalseCues);
alignment.falseCueOn(presentsForFalseCues+presentToCueDelay)=1;
for i=1:length(presentsForFalseCues)
    % check whether there was an opto during this false cue
    [mi,mind]=min(abs(presentsForFalseCues(i)+presentToCueDelay-optos)); % find distance of closest opto
    if mi<=max_inds
        alignment.optoOnly(optos(mind):optos(mind)+duration_inds)=1;
    end
end
figure();
plot(alignment.pelletPresented,'Color','k'); 
hold on; 
plot(alignment.cue,'Color','b');
plot(alignment.falseCueOn,'Color','c');
plot(alignment.optoOn,'Color','y');
plot(alignment.optoOnly,'Color','r');
leg={'pellet presented','cue','false cue','opto on','opto only'};
xlabel('indices');
ylabel('events');
legend(leg);
title('detecting opto without cue');