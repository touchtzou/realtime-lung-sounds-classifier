function	test_data;

% This function produces the scaled flow and lung sound samples
% that can bu used directly with the DSP to produce the LPC coeffs.
% for forming the training vectors.

CONTINUE='n';
while CONTINUE~='y',

file_name=input('Input The Name of The Text File Containing Data of This Subjcet:','s');
while (1),
mic_no=input('Enter 1 To Choose The Left Lung Microphone (mic1) Or 2 For The Right One (mic2):');
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
title('Flow Signal recorded using a Flowmeter')
xlabel('Sample Index')
ylabel('Flow Value')  
grid  on
hold  on

subplot(2,1,2);plot(lung(:))
title('Lung Sound recorded using an air-coupled microphone')
xlabel('Sample Index')
ylabel('Lung Sound Value')
grid  on
hold  off
g=1;
phase_info=zeros(4,1);

   Next='Specify The Starting And Ending Points Of The Respiratory Cycle    '

   phase_info(g)=input('Enter The Start Index Of This Cycle''s Inspiration Phase:');
   phase_info(g+1)=input('Enter The End Index Of This cycle''s Inspiration Phase:');
   phase_info(g+2)=input('Enter The Start Index Of This Cycle''s Expiration Phase:');
   phase_info(g+3)=input('Enter The End Index Of This Cycle''s Expiration Phase:');
   selected_start=phase_info(g);
   selected_end=phase_info(g+3);
   
   % Find the points of inspiratory phase that lasts for at least
   % 0.6 second (5000 sammples).
   cross_zero=find(flow(phase_info(g):phase_info(g+1))<=0); % The points @ which flow changes polarity.
   
   for	count_cross=1:length(cross_zero)-1
      duration=cross_zero(count_cross+1)-cross_zero(count_cross);
      if	duration>=5000
         phase_info(g)=phase_info(g)+cross_zero(count_cross);
         phase_info(g+1)=phase_info(g)+cross_zero(count_cross+1)-cross_zero(count_cross)-2;
      end
   end
   
   
% Now find the expiratory phase limits.
   cross_zero=find(flow(phase_info(g+2):phase_info(g+3))>=0);
   
   for	count_cross=1:length(cross_zero)-1
      duration=cross_zero(count_cross+1)-cross_zero(count_cross);
      if	duration>=5000
         phase_info(g+2)=phase_info(g+2)+cross_zero(count_cross);
         phase_info(g+3)=phase_info(g+2)+cross_zero(count_cross+1)-cross_zero(count_cross)-2;
      end
   end
         
   threshold=0;
   uu=0;
   
   % Find the exact boundaries of the resp. cycle according to the
   % specified threshold value.
   while (flow(uu+phase_info(g))<=threshold),
      uu=uu+1;
   end
   phase_info(g)=phase_info(g)+uu;
   uu=0;
   while (flow(phase_info(g+1)-uu)<=threshold),
      uu=uu+1;
   end
   phase_info(g+1)=phase_info(g+1)-uu;
   uu=0;
   while (flow(uu+phase_info(g+2))>=(-1*threshold)),
    uu=uu+1;
   end
   phase_info(g+2)=phase_info(g+2)+uu;
   uu=0;
   while (flow(phase_info(g+3)-uu)>=(-1*threshold)),
      uu=uu+1;
   end
   phase_info(g+3)=phase_info(g+3)-uu;
   
	thresholded_flow=[flow(phase_info(g):phase_info(g+1));flow(phase_info(g+2):phase_info(g+3))];
   thresholded_lung=[lung(phase_info(g):phase_info(g+1));lung(phase_info(g+2):phase_info(g+3))];
   
   flow_scale_factor=max(abs(thresholded_flow));
   lung_scale_factor=max(abs(thresholded_lung));
   
   % flow and lung samples should be scaled down so that they could be
   % represented on a fractional fixed point DSP.
   thresholded_flow=(1/256)*(1-(2^(-23)))*(1/flow_scale_factor)*thresholded_flow;

   if	lung_scale_factor>1	% Scale lung samples only if they exceed 1
      thresholded_lung=(1-(2^(-23)))*(1/lung_scale_factor)*thresholded_lung;
   end
   
% Downsample the flow from 8kHz to 125 Hz by a decimation factor of 64
   ii=1;
   next_sample=64;
   
   while (next_sample)<=length(thresholded_flow),
   downsampled_flow(ii)=thresholded_flow(next_sample);
   next_sample=next_sample+64;
   ii=ii+1;
	end

   
figure(2)
subplot(2,1,1);plot(downsampled_flow)
title('Flow Signal to be used for the classification process')
xlabel('Sample Index')
ylabel('Flow Value')  
grid  on

hold  on

subplot(2,1,2);plot(thresholded_lung)
title('Lung Sound samples to be classified')
xlabel('Sample Index')
ylabel('Lung Sound Value')
grid  on
hold  off


CONTINUE=input('Press ''y'' If You Selected The Correct Cycle, Otherwise Press ''n'' To Reselect a New Cycle:','s');

end
fid=fopen('c:\windows\desktop\lung_samples.asm','wt');
fprintf(fid,'   dc    %16.14f\n',thresholded_lung);
fclose(fid);


fid=fopen('c:\windows\desktop\flow_samples.asm','wt');
fprintf(fid,'   dc    %16.14f\n',downsampled_flow);
fclose(fid);


hh=1;	% Determine the number of insp. flow samples.
while	downsampled_flow(hh)>threshold,
   hh=hh+1;
end

inspirtion_flow_samples_number=hh-1
expirtion_flow_samples_number=length(downsampled_flow)-hh+1

inspirtion_lung_samples_number=phase_info(g+1)-phase_info(g)+1
expirtion_lung_samples_number=phase_info(g+3)-phase_info(g+2)+1
format long g
minimum_flow_value=min(abs(downsampled_flow))