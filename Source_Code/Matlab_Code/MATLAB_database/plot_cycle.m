function	plot_cycle;

% This function is used to plot the flow rate signal superimposed on the respiratory
% sounds of the selected respiratory cycle

CONTINUE='n';
while CONTINUE~='y',

file_name=input('Input the Name of the Text File Containing Data of this Subjcet (without .txt extension):','s');
while (1),
mic_no=input('Enter 1 to Choose the Left Lung Microphone (mic1) or 2 for the Right One (mic2):');
if mic_no==1
   [flow,lung]=textread([file_name '.txt'] ,'%f %*f %f %*f ');
   break;   
elseif   mic_no==2
   [flow,lung]=textread([file_name '.txt'],'%f %*f %*f %f ');
   break;
else
   ('Wrong microphone number, please change your selection.')
   
 end     
end

% Convert sampling rate from 6kHz to 8kHz.
lung=resample(lung,4,3);
flow=resample(flow,4,3);
all_flow=length(flow);


figure(1)
subplot(2,1,1);plot(flow(:))
title('Flow Signal Recorded Using a Flowmeter')
xlabel('Sample Index')
ylabel('Flow Value')  
grid  on
hold  on

subplot(2,1,2);plot(lung(:))
title('Lung Sound Recorded Using an Air-Coupled Microphone')
xlabel('Sample Index')
ylabel('Lung Sound Value')
grid  on
hold  off

% Determine the sample indexes of the selected respiratory cycle.
phase_info=zeros(4,1);
   Next='Specify The Starting And Ending Points Of The Respiratory Cycle    '
   number=1
   phase_info(1)=input('Enter The Start Index Of This Cycle''s Inspiration Phase:');
   phase_info(2)=input('Enter The End Index Of This cycle''s Inspiration Phase:');
   phase_info(3)=input('Enter The Start Index Of This Cycle''s Expiration Phase:');
   phase_info(4)=input('Enter The End Index Of This Cycle''s Expiration Phase:');
   selected_start=phase_info(1);
   selected_end=phase_info(4);
   max_flow=max(flow(phase_info(1):phase_info(4)));
   %%threshold=0.1*max_flow;
   threshold=0; % Could be changed as desired.
   
   uu=0;
   % Find the exact boundaries of the resp. cycle according to the
   % specified threshold value.
   while (flow(uu+phase_info(1))<threshold),
      uu=uu+1;
   end
   phase_info(1)=phase_info(1)+uu;
   uu=0;
   while (flow(phase_info(2)-uu)<threshold),
      uu=uu+1;
   end
   phase_info(2)=phase_info(2)-uu;
   uu=0;
   while (flow(uu+phase_info(3))>(-1*threshold)),
    uu=uu+1;
   end
   phase_info(3)=phase_info(3)+uu;
   uu=0;
   while (flow(phase_info(4)-uu)>(-1*threshold)),
      uu=uu+1;
   end
   phase_info(4)=phase_info(4)-uu;
   
   flow_scale_factor=max(abs(flow(phase_info(1):phase_info(4))));
   lung_scale_factor=max(abs(lung(phase_info(1):phase_info(4))));

%new_flow=(1.7/flow_scale_factor)*flow(phase_info(g):phase_info(g+3));   
%new_lung=(1/lung_scale_factor)*lung(phase_info(g):phase_info(g+3));

new_flow=flow(phase_info(1):phase_info(4));   
new_lung=(2)*lung(phase_info(1):phase_info(4)); % Scale down or up as needed.

figure(2)
plot((1/8000)*(1:length(new_flow)),new_flow,'k')
xlabel('Time (seconds)')
ylabel('Sound Amp. *2 (volts), Flow Amp. (l/s)') % The applied scale factor should
																 % be mentioned (Here, it is 2).
grid  on
hold  on

plot((1/8000)*(1:length(new_lung)),new_lung,'k')
grid  on
hold  off
   
CONTINUE=input('Press ''y'' If Your Selected The Correct Cycle, Otherwise Press ''n'' To Reselect a New Cycle:','s');

end


