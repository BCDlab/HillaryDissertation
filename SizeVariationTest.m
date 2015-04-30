Screen('Preference', 'SkipSyncTests', 1);
screennum = 0;
white = WhiteIndex(screennum);
grey = white/2;
[w, wRect] = Screen('OpenWindow',screennum,grey);
xsize = 400;
ysize = 512;
x = 0; % Drawing position relative to center
y = 0;
x0 = wRect(3)/2; % Screen center
y0 = wRect(4)/2;

sizevary = [.95,.97,.99,1.01,1.03,1.05];

trials = 5;
for i = 1:trials
    sizepick = sizevary(randi(numel(sizevary)));
    s = sizepick;
    destrect = [x0-s*xsize/2+x,y0-s*ysize/2+y,x0+s*xsize/2+x,y0+s*ysize/2+y];
    filename = 'Images/Macaques/Grey/1.bmp';
    imdata = imread(char(filename));
    mytex = Screen('MakeTexture',w,imdata);
    Screen('DrawTexture',w,mytex,[],destrect);
    Screen('Flip',w);
    WaitSecs(.3);
    Screen('Flip',w);
end
Screen('CloseAll');