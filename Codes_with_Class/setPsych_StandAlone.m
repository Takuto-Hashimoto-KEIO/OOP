%% setpara_key
% The avaliable keys to press
try
    escapeKey = KbName('ESCAPE');
catch
    escapeKey = KbName('esc');
end
RI = KbName('u');
LI = KbName('r');
RM = KbName('8*');
LM = KbName('4$');

timeLim     = dur;
size_Buffer = timeLim*10000;
num_key     = 1;

tbl_keylist = [LM,LI,RI,RM]; %based on Aramaki 2006
kind_key    = numel(tbl_keylist);

tbl_sec     = ones(size_Buffer,1);
tbl_key     = ones(size_Buffer,1);

tbl_sec     = repmat(tbl_sec,[1,kind_key,num_trl]);
tbl_key     = repmat(tbl_key,[1,kind_key,num_trl]);

tbl_num_key = zeros(kind_key,num_trl);
start_trl   = zeros(num_trl,1);
finish_trl  = zeros(num_trl,1);
time_trans  = zeros(num_trl,1);
%% setPara_Psych
% colorPalette;
% psych_default_colormode = PsychDefaultSetup_StandAlone(2);
% PsychDefaultSetup(2);
%{
screens         = Screen('Screens');
screenNumber    = 0; %home (sigleDisp)
screenNumber    = 1; %Experimenter (this cross will not be shown)
screenNumber    = 2; %Participant
white           = WhiteIndex(screenNumber);
black           = BlackIndex(screenNumber);

[window, windowRect]           = PsychImaging('OpenWindow', screenNumber, black);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
ifi = Screen('GetFlipInterval', window);
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);
Screen('TextFont', window, 'Arial');
Screen('TextSize', window, 36);

[xCenter, yCenter] = RectCenter(windowRect);

fixCrossDimPix     = 40;
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];
lineWidthPix = 4;
Screen('DrawLines', window, allCoords,...
    lineWidthPix, white, [xCenter yCenter], 2);
%Screen('DrawLines', windowPtr, xy [,width] [,colors] [,center] [,smooth][,lenient]);
Screen('Flip', window);
%}
%% setSound
%%% loadSound
[y_caution,Fs_caution] = audioread('cautionBeep.wav');
[y_start]              = audioread('startSound.wav');

Fs_beep                = 8192;
time_beep              = 1/Fs_beep : 1/Fs_beep : dur;
flag_success           = [];

tbl_y                  = zeros(dur*Fs_beep,num_trl+1);
tbl_fs_tap             = zeros(num_trl,1);
tbl_flag_success       = zeros(num_trl,1);
tbl_fs_tap(1)          = initialFreq;

y                   = BiTap_psych.generateBeep(Fs_beep,tbl_fs_tap(1),dur); % first trl
tbl_y(:,1)          = y;
fs                  = tbl_fs_tap(1);
fs_diff_success     = 0.5;
fs_diff_failure     = 0;
y_ready             = BiTap_psych.generateBeep(Fs_beep,2/0.2,0.2);

time_waitQue_ready  = zeros(num_trl,2);
flag_slow           = zeros(num_trl,1);