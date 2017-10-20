
function [mean_lpc, subject_early_insp, subject_mid_insp, subject_late_insp, subject_early_exp, subject_mid_exp, subject_late_exp, corr_coeff]=mean_feature(subject_indx,filter_order,seg_length)

% This function applies a threshold to the selected resp. cycle, then it
% segments the lung sound signal into 6 sub-phases using the flow signal. 
% The LPC coefficients corresponding to each of these sup-phases are returned.

lpc_order=filter_order;
I='***************************************************************************************';
II='SPECIFY THE INFORMATION RELATED TO SUBJECT                                             ';
CONTINUE='n';
while CONTINUE~='y',
   
NOW=[I;II]
NUMBER=subject_indx
window_length=seg_length;
start='***************************************************************************************'
file_name=input('Input The Name of The Text File Containing Data of This Subjcet (without .txt extension):','s');
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

figure(subject_indx+1)
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

g=1;
resp_cycles_no=input('By Examining This Figure, Determine The Number Of Respiratory Cycles To Be Averaged:');
phase_info=zeros(4*resp_cycles_no,1);

% If the calculated LPC coeffs. are going to be averaged over more than
% one resp. cycle then the following loop is executed more than once.
for   jj=1:resp_cycles_no,
   Next='Specify The Starting And Ending Points Of The Respiratory Cycle    '
   number=jj
   phase_info(g)=input('Enter The Start Index Of This Cycle''s Inspiration Phase:');
   phase_info(g+1)=input('Enter The End Index Of This cycle''s Inspiration Phase:');
   phase_info(g+2)=input('Enter The Start Index Of This Cycle''s Expiration Phase:');
   phase_info(g+3)=input('Enter The End Index Of This Cycle''s Expiration Phase:');
   selected_start=phase_info(g);
   selected_end=phase_info(g+3);
   max_flow=max(flow(phase_info(g):phase_info(g+1)));
   threshold=0.1*max_flow;
   uu=0;
   
   % Find the exact boundaries of the resp. cycle according to the
   % specified threshold value.
   while (flow(uu+phase_info(g))<threshold),
      uu=uu+1;
   end
   phase_info(g)=phase_info(g)+uu;
   uu=0;
   while (flow(phase_info(g+1)-uu)<threshold),
      uu=uu+1;
   end
   phase_info(g+1)=phase_info(g+1)-uu;
   uu=0;
   while (flow(uu+phase_info(g+2))>(-1*threshold)),
    uu=uu+1;
   end
   phase_info(g+2)=phase_info(g+2)+uu;
   uu=0;
   while (flow(phase_info(g+3)-uu)>(-1*threshold)),
      uu=uu+1;
   end
   phase_info(g+3)=phase_info(g+3)-uu;
   
   
figure(1)
insp_length=phase_info(g+1)-phase_info(g);
exp_length=phase_info(g+3)-phase_info(g+2);
subplot(2,1,1);plot(flow(selected_start:selected_end))
title('The Original Selected Flow Cycle')
xlabel('Sample Index')
ylabel('Flow Value')
grid  on
subplot(2,1,2);plot(flow(phase_info(g):phase_info(g+1)))
hold  on
subplot(2,1,2);plot(insp_length+1:insp_length+exp_length+1,flow(phase_info(g+2):phase_info(g+3)))
title('Flow Signal After Applying a Threshold')
xlabel('Sample Index')
ylabel('Flow Value')   
subplot(2,1,2);plot(threshold*ones((phase_info(g+3)-phase_info(g)),1),'r');
text(insp_length+(exp_length/4),0.3*max_flow,'Positive Threshold')
subplot(2,1,2);plot(-1*threshold*ones((phase_info(g+3)-phase_info(g)),1),'r');
text(insp_length/3,-0.3*max_flow,'Negative Threshold')
grid  on
hold  off
g=g+4;   
end

CONTINUE=input('Press ''y'' If You Selected The Correct Cycle, Otherwise Press ''n'' To Reselect a New Cycle:','s');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

temp_sum=zeros(60*(lpc_order+2),1);
gg=1;
for   count=1:resp_cycles_no,
phase_end=zeros(7,1);
m=1;
cycle_start=phase_info(gg);
cycle_end=phase_info(gg+1);

% Divide the insp. and exp. phases into 6 sub-phases according 
% to the volume corresponding to the insp. and exp. cycles 
% separately.
for   cycle_no=1:2,   
   cycle_flow=flow(cycle_start:cycle_end);
   cycle_vol=sum(cycle_flow);
   cycle_vol=abs(cycle_vol); 
   temp_vol=0;
   i=1;
   
   while abs(temp_vol)<(0.3*cycle_vol);
    temp_vol=temp_vol+cycle_flow(i);
    i=i+1;
   end
   
   phase_end(m)=i;
   m=m+1;
   while abs(temp_vol)<(0.7*cycle_vol);
      temp_vol=temp_vol+cycle_flow(i);
      i=i+1;
   end
   phase_end(m)=i;
   m=4;
   
   cycle_start=phase_info(gg+2);
   cycle_end=phase_info(gg+3);
end
phase_end(1)=phase_end(1)+phase_info(gg);
phase_end(2)=phase_end(2)+phase_info(gg);
phase_end(3)=phase_info(gg+1);
phase_end(4)=phase_end(4)+phase_info(gg+2);
phase_end(5)=phase_end(5)+phase_info(gg+2);
phase_end(6)=phase_info(gg+3);

%----------------------------------------------------------------------------
% The following portion of code can be used to calculate roughly the address
% boundaries of the respiratory sub-phases by just using the number of the
% inspiratory/expiratory lung sound samples.
%----------------------------------------------------------------------------
%phase_end(1)=phase_info(gg)+round(0.3*(phase_info(gg+1)-phase_info(gg)));
%phase_end(2)=phase_info(gg)+round(0.7*(phase_info(gg+1)-phase_info(gg)));
%phase_end(3)=phase_info(gg+1);
%phase_end(4)=phase_info(gg+2)+round(0.3*(phase_info(gg+3)-phase_info(gg+2)));
%phase_end(5)=phase_info(gg+2)+round(0.7*(phase_info(gg+3)-phase_info(gg+2)));
%phase_end(6)=phase_info(gg+3);
%----------------------------------------------------------------------------


lpc_start=1;
lpc_end=lpc_order+1;

corr_start=1;
corr_end=lpc_order+1;

start_index=phase_info(gg);
end_index=phase_end(1);
result=zeros(60*(lpc_order+2),1);
window=hamming(window_length);
gg=gg+4;
for   k=1:6,
   segment_length=fix((end_index-start_index)/8);
   overlap_length=fix(segment_length/4);
   segment_start=start_index;
   segment_end=segment_start+segment_length;
   
% Divide each sub-phase into ten 25% overlapping segments each of length
% specified by the value of window_length. Use zero padding if necessary,
% then apply a Hamming window on each segment. The LPC coefficients of each
% segment are calculated using the modified_aryule() function.
   for   i=1:9,
      vector_in=zeros(window_length,1);
    
      if (segment_length>=window_length)
         
         vector_in(1:window_length)=lung(segment_start:(segment_start+window_length-1));
      else

         vector_in(1:segment_length)=lung(segment_start:segment_start+segment_length-1);
      end
      vector_out=window.*vector_in;
      [result(lpc_start:lpc_end),result(lpc_end+1)]=modified_aryule(vector_out,lpc_order);
      
      % The following autocorrelation values are used only only to generate test vectors for K-nn with
      % Itakura distance measure.
		autocorr_values=xcorr(vector_out,lpc_order,'coeff'); 
      corr_coeff(corr_start:corr_end)=autocorr_values(lpc_order+1:2*lpc_order+1);
      
      lpc_start=lpc_start+lpc_order+2;
      lpc_end=lpc_end+lpc_order+2;
      
      segment_start=segment_end-overlap_length;
      segment_end=segment_start+segment_length;
      corr_start=corr_end+1;
      corr_end=corr_start+lpc_order;
   end   
   
        segment_end=phase_end(k);
        segment_length=segment_end-segment_start;
      vector_in=zeros(window_length,1);

   if ((segment_length)>=window_length)      
      vector_in(1:window_length)=lung(segment_start:(segment_start+window_length-1));
   else
      vector_in(1:segment_length)=lung(segment_start:segment_start+segment_length-1);
   end
      
   vector_out=window.*vector_in;
   [result(lpc_start:lpc_end),result(lpc_end+1)]=modified_aryule(vector_out,lpc_order);
   
    autocorr_values=xcorr(vector_out,lpc_order,'coeff');
    corr_coeff(corr_start:corr_end)=autocorr_values(lpc_order+1:2*lpc_order+1);
   
   lpc_start=lpc_start+lpc_order+2;
   lpc_end=lpc_end+lpc_order+2;         
   start_index=phase_end(k)+1;
   end_index=phase_end(k+1);                         
end    
temp_sum=temp_sum+result;

end      %%% Refers to resp_cyle_no loop
mean_lpc=(1/resp_cycles_no)*temp_sum;
ending=0;
subject_early_insp=zeros(lpc_order+2,1);

%----------------------------------------------------------------------
% Find the average LPC coeffs. over the ten segments of each sub-phase.
%----------------------------------------------------------------------
for   early_insp=1:10,
 starting=ending+1;
 ending=starting+lpc_order+1;
 subject_early_insp=subject_early_insp+mean_lpc(starting:ending);
end


subject_mid_insp=zeros(lpc_order+2,1);
for   mid_insp=1:10,
 starting=ending+1;
 ending=starting+lpc_order+1;
 subject_mid_insp=subject_mid_insp+mean_lpc(starting:ending);
end
subject_late_insp=zeros(lpc_order+2,1);


for   late_insp=1:10,
 starting=ending+1;
 ending=starting+lpc_order+1;
 subject_late_insp=subject_late_insp+mean_lpc(starting:ending);
end
subject_early_exp=zeros(lpc_order+2,1);


for   early_exp=1:10,
 starting=ending+1;
 ending=starting+lpc_order+1;
 subject_early_exp=subject_early_exp+mean_lpc(starting:ending);
end
subject_mid_exp=zeros(lpc_order+2,1);


for   mid_exp=1:10,
 starting=ending+1;
 ending=starting+lpc_order+1;
 subject_mid_exp=subject_mid_exp+mean_lpc(starting:ending);
end
subject_late_exp=zeros(lpc_order+2,1);


for   late_exp=1:10,
 starting=ending+1;
 ending=starting+lpc_order+1;
 subject_late_exp=subject_late_exp+mean_lpc(starting:ending);
end

subject_early_insp=(1/10)*subject_early_insp; % Averaged over the ten segments.
subject_mid_insp=(1/10)*subject_mid_insp;
subject_late_insp=(1/10)*subject_late_insp;
subject_early_exp=(1/10)*subject_early_exp;
subject_mid_exp=(1/10)*subject_mid_exp;
subject_late_exp=(1/10)*subject_late_exp;