%% Use this to check NS event output and proper timestamps for events 
DAC_IP = '10.0.0.42';
NetStation('Connect', DAC_IP);
NetStation('Synchronize');
NetStation('StartRecording');
    pause(1);
for J = 1:10
    s = GetSecs();
    NetStation('Event','stm+', s, 0.001, 'obs#', J);
    WaitSecs(1);
end;
NetStation('Synchronize');
NetStation('StopRecording');
NetStation('Disconnect', DAC_IP);