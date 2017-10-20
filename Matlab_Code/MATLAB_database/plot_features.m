function plot_features

% This function is used to plot the LPC coefficients of the selected
% respiratory cycle, changing with each segment of each respiratory
% sub-phase.

window_length=input('DETERMINE THE HAMMING WINDOW LENGTH:');
lpc_order=input('DETERMINE THE LPC MODELING ORDER:');
I='***************************************************************************************';
II='SPECIFY THE INFORMATION RELATED TO SUBJECT                                             ';
CONTINUE='n';
while CONTINUE~='y',
   
NOW=[I;II]
start='***************************************************************************************'
file_name=input('Input the Name of the Text File Containing Data of this Subjcet (without .txt extension):','s');
while (1),
mic_no=input('Enter 1 To Choose The Right Lung Microphone Or 2 For The Left One:');
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

% It is assumed that the respiratory data in the original file is
% sampled @ a rate of 6 kHz. So, resample these data @ 8kHz.
lung=resample(lung,4,3);
flow=resample(flow,4,3);

all_flow=length(flow);
figure(2)
subplot(2,1,1);plot(flow(:))
title('Flow Signal Recorded Using a Flowmeter')
xlabel('Sample Index')
ylabel('Flow Value')  
grid  on
hold  on
subplot(2,1,2);plot(lung(:))
title('Lung Sound Recorded Using an Air-coupled Microphone')
xlabel('Sample Index')
ylabel('Lung Sound Value')
grid  on
hold  off
g=1;

% More than one resp. cycle can be chosen, and the averaged LPC coefficients over these cycles can be obtained.
resp_cycles_no=input('By Examining This Figure, Determine The Number Of Respiratory Cycles To Be Averaged:');

phase_info=zeros(4*resp_cycles_no,1);
for   jj=1:resp_cycles_no,
   Next='Specify The Starting And Ending Points Of The Respiratory Cycle    '
   number=jj
   phase_info(g)=input('Enter The Start Index Of This Cycle''s Inspiration Phase:');
   phase_info(g+1)=input('Enter The End Index Of This cycle''s Inspiration Phase:');
   phase_info(g+2)=input('Enter The Start Index Of This Cycle''s Expiration Phase:');
  	phase_info(g+3)=input('Enter The End Index Of This Cycle''s Expiration Phase:');
   selected_start=phase_info(g);
   selected_end=phase_info(g+3);
   max_flow=max(flow(phase_info(g):phase_info(g+3)));
   threshold=0.1*max_flow;
   uu=0;
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
plot(flow(phase_info(g):phase_info(g+1)))
hold  on
plot(insp_length+1:insp_length+exp_length+1,flow(phase_info(g+2):phase_info(g+3)))
title('The Selected Flow Signal After Applying a Threshold')

xlabel('Sample Index')
ylabel('Flow Value')   
plot(threshold*ones((phase_info(g+3)-phase_info(g)),1),'r');
text(insp_length+(exp_length/4),0.3*max_flow,'Positive Threshold')

plot(-1*threshold*ones((phase_info(g+3)-phase_info(g)),1),'r');
text(insp_length/3,-0.3*max_flow,'Negative Threshold')
grid  on

hold  off
g=g+4;   
end

CONTINUE=input('Press ''y'' If You Selected The Correct Cycle, Otherwise Press ''n'' To Reselect a New Cycle:','s');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
temp_sum=zeros(60*(lpc_order+1),1);
gg=1;
for   count=1:resp_cycles_no,


phase_end=zeros(7,1);
m=1;
cycle_start=phase_info(gg);
cycle_end=phase_info(gg+1);

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
lpc_start=1;
lpc_end=lpc_order+1;
start_index=phase_info(gg);
end_index=phase_end(1);
result=zeros(60*(lpc_order+1),1);
window=hamming(window_length);
gg=gg+4;
for   k=1:6,
   segment_length=fix((end_index-start_index)/8);
   overlap_length=fix(segment_length/4);
   segment_start=start_index;
   segment_end=segment_start+segment_length;

   for   i=1:9,
      vector_in=zeros(window_length,1);
    
      if (segment_length>=window_length)
         
         vector_in(1:window_length)=lung(segment_start:(segment_start+window_length-1));
      else

         vector_in(1:segment_length)=lung(segment_start:segment_start+segment_length-1);
      end
      vector_out=window.*vector_in;
      result(lpc_start:lpc_end)=modified_aryule(vector_out,lpc_order);
      lpc_start=lpc_start+lpc_order+1;
      lpc_end=lpc_end+lpc_order+1;
      
      segment_start=segment_end-overlap_length;
      segment_end=segment_start+segment_length;
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
   result(lpc_start:lpc_end)=modified_aryule(vector_out,lpc_order);
   lpc_start=lpc_start+lpc_order+1;
   lpc_end=lpc_end+lpc_order+1;         
   start_index=phase_end(k)+1;
   end_index=phase_end(k+1);                         
end    

if count==1
   plot_color='-k';
elseif   count==2
   plot_color='-k';
else  plot_color='-k';
end

figure(8);
ar_1=zeros(60,1);
h=2;

for   p=1:60,
   ar_1(p)=result(h);   
   h=h+lpc_order+1;
end
plot(1:60,ar_1,plot_color)
xlabel('Segment Number')
ylabel('LPC(1) Value')
axis([1 60 -3.5 0])
grid  on
hold  on;
   
   figure(9);   
   ar_2=zeros(60,1);
   h=3;
   for   p=1:60,
      ar_2(p)=result(h);
      h=h+lpc_order+1;
      
   end
   
plot(1:60,ar_2,plot_color)
xlabel('Segment Number')
ylabel('LPC(2) Value')
axis([1 60 0 5])

grid  on
hold  on
   
         
   figure(10);
   ar_3=zeros(60,1);
   h=4;
   for   p=1:60,
      ar_3(p)=result(h);
      h=h+lpc_order+1;
      
   end
   plot(1:60,ar_3,plot_color)
      
xlabel('Segment Number')
ylabel('LPC(3) Value')
axis([1 60 -4 4])

grid  on
   hold on
   figure(11);
   ar_4=zeros(60,1);
   h=5;
   for   p=1:60,
      ar_4(p)=result(h);
      h=h+lpc_order+1;
      
   end
   
plot(1:60,ar_4,plot_color)
xlabel('Segment Number')
ylabel('LPC(4) Value')
axis([1 60 -4 4])

grid  on
   hold  on
   figure(12);
   ar_5=zeros(60,1);
   h=6;
   for   p=1:60,
      ar_5(p)=result(h);
      h=h+lpc_order+1;
      
   end
   
plot(1:60,ar_5,plot_color)
xlabel('Segment Number')
ylabel('LPC(5) Value')
axis([1 60 -2 2])
grid  on
hold  on
figure(13);
ar_6=zeros(60,1);
h=7;
for   p=1:60,
   ar_6(p)=result(h);
   h=h+lpc_order+1;
      
   end
   
plot(1:60,ar_6,plot_color)  
xlabel('Segment Number')
ylabel('LPC(6) Value')
axis([1 60 -1 1])
grid  on
hold  on

temp_sum=temp_sum+result;

end      %%% Refers to resp_cyle_no loop
mean_lpc=(1/resp_cycles_no)*temp_sum;