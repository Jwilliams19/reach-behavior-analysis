function tbt=plotCueTriggeredBehavior(data,nameOfCue,excludePawOnWheelTrials)

% nameOfCue should be 'cue' for real cue
% 'arduino_distractor' for distractor

% Get cue/data type for triggering trial-by-trial data
cue=data.(nameOfCue); 

% Get settings for this analysis
settings=plotCueTriggered_settings();
% In case of issues with aliasing of instantaneous cue
maxITI=settings.maxITI; % in seconds, maximal ITI
minITI=settings.minITI; % in seconds, minimal ITI

% Get time delay
timeIncs=diff(data.timesfromarduino(data.timesfromarduino~=0));
mo=mode(timeIncs);
timeIncs(timeIncs==mo)=nan;
bettermode=mode(timeIncs); % in ms
bettermode=bettermode/1000; % in seconds

% Fix aliasing issues with resampled data
[cue,cueInds,cueIndITIs]=fixAliasing(cue,maxITI,minITI,bettermode);
[data.pelletPresented,presentedInds]=fixAliasing(data.pelletPresented,maxITI,minITI,bettermode);

% Checking cue detection
figure();
plot(cue./nanmax(cue));
hold on;
plot(data.pelletPresented./nanmax(data.pelletPresented),'Color','k');
for i=1:length(cueInds)
    scatter(cueInds(i),1,[],'r');
end
for i=1:length(presentedInds)
    scatter(presentedInds(i),1,[],[0.5 0.5 0.5]);
end
title('Checking cue selection');
legend({'Cue','Pellet presented','Cue detected','Pellet presented detected'});

data.timesfromarduino=data.timesfromarduino./1000; % convert from ms to seconds

% Turn pellet presented into events
pelletPresented=data.pelletPresented;
sigmax=max(max(pelletPresented));
sigthresh=sigmax/2;
temp=zeros(size(pelletPresented));
temp(pelletPresented>=sigthresh)=1;
data.pelletPresented=temp;

% Set up trial-by-trial, tbt
pointsFromPreviousTrial=settings.pointsFromPreviousTrial;
f=fieldnames(data);
for i=1:length(f)
    tbt.(f{i})=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
end
% Add times
tbt.times=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);

% Organize trial-by-trial data
for i=1:length(cueInds)
    if i==length(cueInds)
        theseInds=cueInds(i)-pointsFromPreviousTrial:length(cue);
    elseif i==1
        theseInds=1:cueInds(i+1)-1;
    else
        theseInds=cueInds(i)-pointsFromPreviousTrial:cueInds(i+1)-1;
    end
    for j=1:length(f)
        temp=tbt.(f{j});
        temp1=data.(f{j});
        temp(i,1:length(theseInds))=temp1(theseInds);
        tbt.(f{j})=temp;
    end
    % Get times
    tbt.times(i,1:length(theseInds))=data.movieframeinds(theseInds).*bettermode;
end

% Zero out nans
for i=1:length(f)
    temp=tbt.(f{i});
    temp(isnan(temp))=0;
    tbt.(f{i})=temp;
end

% Get times per trial
tbt.times=tbt.times-repmat(nanmin(tbt.times,[],2),1,size(tbt.times,2));
timespertrial=nanmean(tbt.times,1);

% Exclude trials where paw was on wheel while wheel turning
if excludePawOnWheelTrials==1
    % Find trials where paw was on wheel while wheel turning
    plot_cues=[];
    for i=1:size(tbt.cue,1)
        presentInd=find(tbt.pelletPresented(i,:)>0.5,1,'first');
        cueInd=find(tbt.cue(i,:)>0.5,1,'first');
        pawWasOnWheel=0;
        if any(tbt.pawOnWheel(i,presentInd:cueInd)>0.5)
            pawWasOnWheel=1;
        else
            plot_cues=[plot_cues i];
        end
    end
else
    plot_cues=1:size(tbt.cue,1);
end

% Plot trial-by-trial average
figure();
plotfields=settings.plotfields;
ha=tight_subplot(length(plotfields),1,[0.06 0.03],[0.05 0.05],[0.1 0.03]);
for i=1:length(plotfields)
    currha=ha(i);
    axes(currha);
    temp=tbt.(plotfields{i});
    plot(timespertrial,nanmean(temp(plot_cues,:),1));
    title(plotfields{i},'Interpreter','none');
end

% Also plot experiment as events in a scatter plot
figure();
k=1;
plotfields=settings.plotevents;
for i=plot_cues
    if ~isempty(settings.shading_type)
        % Shade some trials
        if ismember('ITI',settings.shading_type)
            % Shade trials according to ITI lengths
            shades=settings.shading_colors{find(ismember(settings.shading_type,'ITI'))};
            event_thresh=0.5;
            event_ind_cue=find(tbt.cue(i,:)>event_thresh,1,'first');
            event_ind_pellet=find(tbt.pelletPresented(i,:)>event_thresh);
            if event_ind_pellet(end)>length(timespertrial) || event_ind_cue>length(timespertrial)
            elseif (timespertrial(event_ind_pellet(end))-timespertrial(event_ind_cue))>settings.blockITIThresh
                % Slow block
                if strcmp(shades{1},'none')
                else
                    line([0 timespertrial(end)],[k k],'Color',shades{1},'LineWidth',10);
                end
            else
                % Fast block
                if strcmp(shades{2},'none')
                else
                    line([0 timespertrial(end)],[k k],'Color',shades{2},'LineWidth',10);
                end
            end
        end
    end
    for j=1:length(plotfields)
        currEvents=tbt.(plotfields{j});
        event_thresh=settings.eventThresh{j};
        event_ind=find(currEvents(i,:)>event_thresh);
        n=length(event_ind);
        if ischar(settings.firstN{j})
            if strcmp('all',settings.firstN{j})
                % plot all events
            end
        else
            % plot first n events
            n=settings.firstN{j};
        end    
        for l=1:n
            scatter([timespertrial(event_ind(l))-settings.shiftBack{j} timespertrial(event_ind(l))-settings.shiftBack{j}],[k k],[],'MarkerEdgeColor',settings.eventOutlines{j},...
                'MarkerFaceColor',settings.eventColors{j},...
                'LineWidth',settings.eventLineWidth);
            hold on; 
        end       
    end
    k=k+1;
end

% Plot overlap trial-by-trial average
figure();
plotfields=settings.histoplotfields;
for i=1:length(plotfields)
    temp=tbt.(plotfields{i});
    if i==1
        plot(timespertrial-settings.histoshiftBack{i},nansum(temp(plot_cues,:),1));
    else
        temp2=nansum(temp(plot_cues,:),1);
        plot(timespertrial-settings.histoshiftBack{i},temp2.*(ma/nanmax(temp2)));
    end
    hold all;
    if i==1
        ma=nanmax(nansum(temp(plot_cues,:),1));
    end
end
legend(plotfields);

end

function [cue,cueInds,cueIndITIs]=fixAliasing(cue,maxITI,minITI,bettermode)

cue=nonparamZscore(cue); % non-parametric Z score

settings=plotCueTriggered_settings();
peakHeight=nanmean(cue)+settings.nStdDevs*nanstd(cue);
relativePeakHeight=settings.nStdDevs*nanstd(cue);

[pks,locs]=findpeaks(cue);
cueInds=locs(pks>peakHeight);
% cueInds=[1 cueInds length(cue)]; % in case aliasing problem is at edges
cueIndITIs=diff(cueInds);
checkTheseIntervals=find(cueIndITIs*bettermode>(maxITI*1.5));
for i=1:length(checkTheseIntervals)
    indsIntoCue=cueInds(checkTheseIntervals(i))+floor((maxITI/2)./bettermode):cueInds(checkTheseIntervals(i)+1)-floor((maxITI/2)./bettermode);
    if any(cue(indsIntoCue)>0.001)
        [~,ma]=max(cue(indsIntoCue)); 
        cue(indsIntoCue(ma))=max(cue);
    end
end 

% [pks,locs]=findpeaks(cue);
[pks,locs]=findpeaks(cue,'MinPeakDistance',floor((minITI*0.75)/bettermode),'MinPeakProminence',relativePeakHeight);
cueInds=locs(pks>peakHeight);
cueIndITIs=diff(cueInds);
checkTheseIntervals=find(cueIndITIs*bettermode<(minITI*0.75));
if ~isempty(checkTheseIntervals)
    for i=1:length(checkTheseIntervals)
        cue(cueInds(checkTheseIntervals(i)))=0;
        cueInds(checkTheseIntervals(i))=nan; 
    end
end
cueInds=cueInds(~isnan(cueInds));
cueIndITIs=diff(cueInds);

cue=cue./nanmax(cue);
 
end
