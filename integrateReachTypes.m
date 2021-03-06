function alignment=integrateReachTypes(reaches, alignment)

% Add events from reaches
movframes=alignment.movieframeinds;

alignment=reachInitiation(reaches, alignment, movframes);
alignment=reachEnding(reaches, alignment, movframes);
alignment=reachPelletPresent(reaches, alignment, movframes);
alignment=reachEatsPellet(reaches, alignment, movframes);
alignment=reachDrop(reaches, alignment, movframes);
alignment=reachMiss(reaches, alignment, movframes);
alignment=reachNoPellet(reaches, alignment, movframes);
alignment=eatTiming(reaches, alignment, movframes);
alignment=reachFromWheel(reaches, alignment, movframes);
alignment=successReachFromWheel(reaches, alignment, movframes);
alignment=dropReachFromWheel(reaches, alignment, movframes);
alignment=missReachFromWheel(reaches, alignment, movframes);
alignment=reachOngoing(reaches, alignment, movframes);
alignment=lickInitiation(reaches, alignment, movframes);
alignment=fidgetInitiation(reaches, alignment, movframes);

end

function alignment=fidgetInitiation(reaches, alignment, movframes)

% Initiation of fidget
alignment.reachFidgetBegins=restructureEvent(reaches.reachFidgetBegins, movframes);

end

function alignment=reachOngoing(reaches, alignment, movframes)

% Reach ongoing
alignment.reach_ongoing=zeros(1,length(movframes));
reachIsStarting=find(alignment.reachStarts>0.5);
reachIsEnding=find(alignment.reachEnds>0.5);
for i=1:length(reachIsStarting)
    currReachStarts=reachIsStarting(i);
    temp=reachIsEnding-currReachStarts;
    temp(temp<0)=max(temp)+10000;
    [~,mi]=min(temp);
    alignment.reach_ongoing(reachIsStarting(i):reachIsEnding(mi))=1;
end

end

function alignment=missReachFromWheel(reaches, alignment, movframes)

% Miss (paw never touches pellet) -- initiation of reach -- paw starts on
% wheel
alignment.miss_reachStarts_pawOnWheel=restructureEvent(reaches.reachStarts(reaches.pelletTouched==0 & reaches.pelletPresent==1 & reaches.pawStartsOnWheel==1), movframes);

end

function alignment=dropReachFromWheel(reaches, alignment, movframes)

% Drop (paw touches pellet, but mouse drops pellet before eating it) --
% initiation of reach -- paw starts on wheel
alignment.drop_reachStarts_pawOnWheel=restructureEvent(reaches.reachStarts(reaches.pelletTouched==1 & reaches.atePellet==0 & reaches.pelletPresent==1 & reaches.pawStartsOnWheel==1), movframes);

end

function alignment=successReachFromWheel(reaches, alignment, movframes)

% Successful reach (mouse eats pellet) -- initiation of successful reach --
% paw starts on wheel
alignment.success_reachStarts_pawOnWheel=restructureEvent(reaches.reachStarts(reaches.atePellet==1 & reaches.pelletPresent==1 & reaches.pawStartsOnWheel==1), movframes);

end

function alignment=reachFromWheel(reaches, alignment, movframes)

% Paw starts on wheel
alignment.pawOnWheel=restructureEvent(reaches.reachStarts(reaches.pawStartsOnWheel==1), movframes);

end

function alignment=eatTiming(reaches, alignment, movframes)

% Eat time
alignment.eating=restructureEvent(reaches.eatTime(reaches.atePellet==1 & reaches.pawStartsOnWheel==0), movframes);

end

function alignment=reachNoPellet(reaches, alignment, movframes)

% Reach despite no pellet -- initiation of reach
alignment.pelletmissingreach_reachStarts=restructureEvent(reaches.reachStarts(reaches.pelletPresent==0 & reaches.pawStartsOnWheel==0), movframes);

end

function alignment=reachMiss(reaches, alignment, movframes)

% Miss (paw never touches pellet) -- initiation of reach
alignment.miss_reachStarts=restructureEvent(reaches.reachStarts(reaches.pelletTouched==0 & reaches.pelletPresent==1 & reaches.pawStartsOnWheel==0), movframes);

end

function alignment=reachDrop(reaches, alignment, movframes)

% Drop (paw touches pellet, but mouse drops pellet before eating it) --
% initiation of reach
alignment.drop_reachStarts=restructureEvent(reaches.reachStarts(reaches.pelletTouched==1 & reaches.atePellet==0 & reaches.pelletPresent==1 & reaches.pawStartsOnWheel==0), movframes);

end

function alignment=reachEatsPellet(reaches, alignment, movframes)

% Successful reach (mouse eats pellet) -- initiation of successful reach
alignment.success_reachStarts=restructureEvent(reaches.reachStarts(reaches.atePellet==1 & reaches.pelletPresent==1 & reaches.pawStartsOnWheel==0), movframes);

end

function alignment=reachPelletPresent(reaches, alignment, movframes)

% Reach given that pellet was present
alignment.reachStarts_pelletPresent=restructureEvent(reaches.reachStarts(reaches.pelletPresent==1), movframes);

end

function alignment=reachEnding(reaches, alignment, movframes)

% End of reach
alignment.reachEnds=restructureEvent(reaches.pelletTime, movframes);

end

function alignment=reachInitiation(reaches, alignment, movframes)

% Initiation of reach
alignment.reachStarts=restructureEvent(reaches.reachStarts, movframes);

end

function alignment=lickInitiation(reaches, alignment, movframes)

% Initiation of lick
alignment.lickStarts=restructureEvent(reaches.lickStarts, movframes);

end

function eventVector=restructureEvent(eventFrames, movieFrames)

eventFrames=eventFrames(~isnan(eventFrames));
eventVector=zeros(1,length(movieFrames));
for i=1:length(eventFrames)
   temp=movieFrames-eventFrames(i);
   temp(temp<0)=max(temp)+10000;
   [~,mi]=min(temp); 
   eventVector(mi)=1;    
end

end
