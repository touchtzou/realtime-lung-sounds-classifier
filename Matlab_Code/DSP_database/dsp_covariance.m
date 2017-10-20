function dsp_covariance;

% This function is used to produce the mean feature vectors and inverse
% covariance matrices that are going to be used with the Mahalanobis
% distance based minimum distance classifier. It can also be used to test
% the performance of the same classifier using the leave-one-out method.

while (1),
   class_name=input('Press 1 for HEALTHY, or 2 for PATHOLOGICAL covariance matrices:\n');
      if class_name>2|class_name<1
         ('Wrong number, please change your selection.')
      else
         break;
      end	%%% Refers to class_name>..
end	%%% Refers to while(1)..


if	class_name==1
   
   s=['Enter the number of healthy subject you want to exclude?\n'...
     	,'0. Exclude None\n','1.alper1','\n2.ba_ke1','\n3.burtecin1'...
     	,'\n4.en_de2','\n5.er_ac3','\n6.erhan1','\n7.fu_ca3'...
     	,'\n8.gokhan_ertas3','\n9.gokhan2','\n10.hisham2','\n11.hus1'...
     	,'\n12.ip_se2','\n13.is_ce3','\n14.me_do3','\n15.me_gu3'...
     	,'\n16.nez2','\n17.og_ka4','\n18.om_oz3','\n19.sameer1'...
     	,'\n20.ugur4','\n21.ya_ya4\n'];
   
   load healthy_lpc.mat;	
   
   total_sub_features=[alper1;ba_ke1;burtecin1;en_de2;er_ac3;erhan1...
     	;fu_ca3;gokhan_ertas3;gokhan2;hisham2;hus1;ip_se2;is_ce3...
     	;me_do3;me_gu3;nez2;og_ka4;om_oz3;sameer1;ugur4;ya_ya4];
   
   subject_number=21;
      
   else
   
      s=['Enter the number of pathological subject you want to exclude?\n'...
     	,'0. Exclude None\n','1.ad_sa4','\n2.ali_du2','\n3.ar_kul1'...
     	,'\n4.ay_ak4','\n5.ca_sa3','\n6.do_bi4','\n7.fa_sa1'...
     	,'\n8.ga_ka5','\n9.gu_il3','\n10.ha_ay3','\n11.ha_de4'...
     	,'\n12.ha_oz4','\n13.ha_sa2','\n14.ha_yi5','\n15.is_co2'...
     	,'\n16.lu_uz2','\n17.me_al3','\n18.mu_ay4','\n19.os_di3'...
     	,'\n20.ru_ba3','\n21.saf_oz2\n'];
   
   load pathological_lpc.mat;
   
   total_sub_features=[ad_sa4;ali_du2;ar_kul1;ay_ak4;ca_sa3;...
         ;do_bi4;fa_sa1;ga_ka5;gu_il3;ha_ay3;ha_de4;ha_oz4;...
         ;ha_sa2;ha_yi5;is_co2;lu_uz2;me_al3;mu_ay4;os_di3;...
         ;ru_ba3;saf_oz2];
   
   subject_number=21;
   
end	%%% Refers to if class_name==...

while (1),
   user_select=input(s);
   if user_select>subject_number|user_select<0
      ('Wrong number, please change your selection.')    
   else
      break;
   end	%%% Refers to if user_select>
end	%%% Refers to while(1)

lpc_order=6;
scale_amount=1/8;
starting=1;
ending=starting+lpc_order+1;

for	hhh=1:(60*subject_number)	% Compensate for the scaled LPCs found by DSP (exclude modeling error).
	total_sub_features(starting:ending)=[(1/scale_amount)*total_sub_features(starting:(ending-1));total_sub_features(ending)];
   starting=ending+1;
   ending=starting+lpc_order+1;
end	%%% Refers to hhh=1:...
%%%%%%%%%%%%%%%%
if	user_select==0	
   subject_features=total_sub_features;	% Select all subjects.
else
   subject_number=subject_number-1;	% Exclude one of the subjects.
   subject_start=1;
   subject_end=subject_start+(60*(lpc_order+2))-1;
   not_selected_sub=((user_select-1)*60*(lpc_order+2))+1;
   
   %********************************************************   
   subject_features=zeros(60*(lpc_order+2)*subject_number,1);
   selected_start=1;
   selected_end=selected_start+(60*(lpc_order+2))-1;
   
   for	counter=1:subject_number	% Here subject_number is less than the original number by one.
      
      	if	subject_start==not_selected_sub	% Executed if the excluded subject is reached..
      		subject_start=subject_end+1;	% if it is excluded skip over it
            subject_end=subject_start+(60*(lpc_order+2))-1;
         end	%%% Refers to if subject_start==not...
      
      subject_features(selected_start:selected_end)=total_sub_features(subject_start:subject_end);
            subject_start=subject_end+1;
      subject_end=subject_start+(60*(lpc_order+2))-1;
           
      selected_start=selected_end+1;
      selected_end=selected_start+(60*(lpc_order+2))-1;
      
	% At the end of this 'for' loop, subject_features will include all the features except the excluded one.
   end	%%% Refers to for 1:subject_number
   
   %********************************************************
   
end	%%% Refers to if user_select


%****************************************************************
% From now on, subject_features will be used only, which contains
% the subject features except the excluded one.
%****************************************************************
subject_start=1;
subject_end=subject_start+(60*(lpc_order+2))-1;
mean_lpc=zeros(60*(lpc_order+2),1);
for	h=1:subject_number
   mean_lpc=mean_lpc+subject_features(subject_start:subject_end);
	subject_start=subject_end+1;
	subject_end=subject_start+(60*(lpc_order+2))-1;
end
mean_lpc=(1/subject_number)*mean_lpc;	% Contains the 60 LPC vectors
													% averaged over all the subjects
													% (except the excluded one).

%--------------------------------------------------------------------
% Now, let us find the average LPC coeffs. over the ten segments of
% each sub-phase of the 60 averaged LPC vectors.
%--------------------------------------------------------------------
early_insp_feature=zeros(lpc_order+2,1);
ending=0;
for   early_insp=1:10,
 starting=ending+1;
 ending=starting+lpc_order+1;
 early_insp_feature=early_insp_feature+mean_lpc(starting:ending);
end


mid_insp_feature=zeros(lpc_order+2,1);
for   mid_insp=1:10,
 starting=ending+1;
 ending=starting+lpc_order+1;
 mid_insp_feature=mid_insp_feature+mean_lpc(starting:ending);
end
late_insp_feature=zeros(lpc_order+2,1);

for   late_insp=1:10,
 starting=ending+1;
 ending=starting+lpc_order+1;
late_insp_feature=late_insp_feature+mean_lpc(starting:ending);
end
early_exp_feature=zeros(lpc_order+2,1);

for   early_exp=1:10,
 starting=ending+1;
 ending=starting+lpc_order+1;
early_exp_feature=early_exp_feature+mean_lpc(starting:ending);
end
mid_exp_feature=zeros(lpc_order+2,1);


for   mid_exp=1:10,
 starting=ending+1;
 ending=starting+lpc_order+1;
mid_exp_feature=mid_exp_feature+mean_lpc(starting:ending);
end
late_exp_feature=zeros(lpc_order+2,1);


for   late_exp=1:10,
 starting=ending+1;
 ending=starting+lpc_order+1;
late_exp_feature=late_exp_feature+mean_lpc(starting:ending);
end
early_insp_feature=(1/10)*early_insp_feature;
mid_insp_feature=(1/10)*mid_insp_feature;
late_insp_feature=(1/10)*late_insp_feature;
early_exp_feature=(1/10)*early_exp_feature;
mid_exp_feature=(1/10)*mid_exp_feature;
late_exp_feature=(1/10)*late_exp_feature;

%('THE CALCULATED MEAN FEATURE VECTORS CORRESPONDING TO EACH
% RESPIRATION SUB-PHASE ARE:')

% Scale these features to values that could be represented on the DSP.
mean_early_insp_feature=[scale_amount*early_insp_feature(2:lpc_order+1);early_insp_feature(lpc_order+2)];
mean_mid_insp_feature=[scale_amount*mid_insp_feature(2:lpc_order+1);mid_insp_feature(lpc_order+2)];
mean_late_insp_feature=[scale_amount*late_insp_feature(2:lpc_order+1);late_insp_feature(lpc_order+2)];
mean_early_exp_feature=[scale_amount*early_exp_feature(2:lpc_order+1);early_exp_feature(lpc_order+2)];
mean_mid_exp_feature=[scale_amount*mid_exp_feature(2:lpc_order+1);mid_exp_feature(lpc_order+2)];
mean_late_exp_feature=[scale_amount*late_exp_feature(2:lpc_order+1);late_exp_feature(lpc_order+2)];


%****************************************************************
%	Now, let us find the Inverse Covariance Matrices.
%****************************************************************

% Initialize the covariance matrices with zero.
early_insp_covar=zeros(lpc_order+1,lpc_order+1);
mid_insp_covar=zeros(lpc_order+1,lpc_order+1);
late_insp_covar=zeros(lpc_order+1,lpc_order+1);
early_exp_covar=zeros(lpc_order+1,lpc_order+1);
mid_exp_covar=zeros(lpc_order+1,lpc_order+1);
late_exp_covar=zeros(lpc_order+1,lpc_order+1);

next_subject_features=2;
subject_end=lpc_order+2;

% The following loop calculates the covariance matrices.
for   outer_loop=1:subject_number,
subject_start=next_subject_features;
temp_matrix=zeros(lpc_order+1,lpc_order+1);
early_insp_temp=zeros(lpc_order+1,lpc_order+1);
for   kk=1:10, % Each phase consists of ten segments.
  differ_vector=subject_features(subject_start:subject_end)-early_insp_feature(2:lpc_order+2);
  temp_matrix=differ_vector*differ_vector';
  early_insp_temp=early_insp_temp+temp_matrix;
  subject_start=subject_end+2;
  subject_end=subject_start+lpc_order;
end
% Average the following matrix over ten segments.
early_insp_temp=0.1*early_insp_temp;
early_insp_covar=early_insp_covar+early_insp_temp;

temp_matrix=zeros(lpc_order+1,lpc_order+1);
mid_insp_temp=zeros(lpc_order+1,lpc_order+1);
for   ll=1:10,
  differ_vector=subject_features(subject_start:subject_end)-mid_insp_feature(2:lpc_order+2);
  temp_matrix=differ_vector*differ_vector';
  mid_insp_temp=mid_insp_temp+temp_matrix;
  subject_start=subject_end+2;
  subject_end=subject_start+lpc_order;
end
mid_insp_temp=0.1*mid_insp_temp;
mid_insp_covar=mid_insp_covar+mid_insp_temp;
temp_matrix=zeros(lpc_order+1,lpc_order+1);
late_insp_temp=zeros(lpc_order+1,lpc_order+1);
for   mm=1:10,
  differ_vector=subject_features(subject_start:subject_end)-late_insp_feature(2:lpc_order+2);
  temp_matrix=differ_vector*differ_vector';
  late_insp_temp=late_insp_temp+temp_matrix;
  subject_start=subject_end+2;
  subject_end=subject_start+lpc_order;
end
late_insp_temp=0.1*late_insp_temp;
late_insp_covar=late_insp_covar+late_insp_temp;


temp_matrix=zeros(lpc_order+1,lpc_order+1);
early_exp_temp=zeros(lpc_order+1,lpc_order+1);
for   qq=1:10,
  differ_vector=subject_features(subject_start:subject_end)-early_exp_feature(2:lpc_order+2);
  temp_matrix=differ_vector*differ_vector';
  early_exp_temp=early_exp_temp+temp_matrix;
  subject_start=subject_end+2;
  subject_end=subject_start+lpc_order;
end
early_exp_temp=0.1*early_exp_temp;
early_exp_covar=early_exp_covar+early_exp_temp;



temp_matrix=zeros(lpc_order+1,lpc_order+1);
mid_exp_temp=zeros(lpc_order+1,lpc_order+1);
for   uu=1:10,
  differ_vector=subject_features(subject_start:subject_end)-mid_exp_feature(2:lpc_order+2);
  temp_matrix=differ_vector*differ_vector';
  mid_exp_temp=mid_exp_temp+temp_matrix;
  subject_start=subject_end+2;
  subject_end=subject_start+lpc_order;
end
mid_exp_temp=0.1*mid_exp_temp;
mid_exp_covar=mid_exp_covar+mid_exp_temp;



temp_matrix=zeros(lpc_order+1,lpc_order+1);
late_exp_temp=zeros(lpc_order+1,lpc_order+1);
for   tt=1:10,
  differ_vector=subject_features(subject_start:subject_end)-late_exp_feature(2:lpc_order+2);
  temp_matrix=differ_vector*differ_vector';
  late_exp_temp=late_exp_temp+temp_matrix;
  subject_start=subject_end+2;
  subject_end=subject_start+lpc_order;
end
late_exp_temp=0.1*late_exp_temp;
late_exp_covar=late_exp_covar+late_exp_temp;

next_subject_features=next_subject_features+60*(lpc_order+2);
end   %%% Refers to "for   outer_loop=1:subject_number"


% Find the inverse covariance matrices.
early_insp_covar=inv((1/subject_number)*(early_insp_covar));
mid_insp_covar=inv((1/subject_number)*(mid_insp_covar));
late_insp_covar=inv((1/subject_number)*(late_insp_covar));
early_exp_covar=inv((1/subject_number)*(early_exp_covar));
mid_exp_covar=inv((1/subject_number)*(mid_exp_covar));
late_exp_covar=inv((1/subject_number)*(late_exp_covar));

% Find the max. value in each inverse covariance matrix.
aa=max(early_insp_covar);
aa_max=max(aa);
bb=max(mid_insp_covar);
bb_max=max(bb);
cc=max(late_insp_covar);
cc_max=max(cc);
dd=max(early_exp_covar);
dd_max=max(dd);
ee=max(mid_exp_covar);
ee_max=max(ee);
ff=max(late_exp_covar);
ff_max=max(ff);

% Scale down the inverse covariance matrices so as to make them compatibe
% with the fractional number representation used on Motorola DSP.
%('THE INVERSE COVARIANCE MATRICES OF EACH RESPIRATION SUB-PHASE WERE 
%FOUND AS FOLLOWS:')
early_insp_covar=(1/aa_max)*early_insp_covar;
mid_insp_covar=(1/bb_max)*mid_insp_covar;
late_insp_covar=(1/cc_max)*late_insp_covar;
early_exp_covar=(1/dd_max)*early_exp_covar;
mid_exp_covar=(1/ee_max)*mid_exp_covar;
late_exp_covar=(1/ff_max)*late_exp_covar;

% Output the calculated matrices row after row because these values are
% going to be stored in this order in the DSP memory.
inverse_of_early_insp_covariance=early_insp_covar(1:(lpc_order+1)*(lpc_order+1))';
inverse_of_mid_insp_covariance=mid_insp_covar(1:(lpc_order+1)*(lpc_order+1))';
inverse_of_late_insp_covariance=late_insp_covar(1:(lpc_order+1)*(lpc_order+1))';
inverse_of_early_exp_covariance=early_exp_covar(1:(lpc_order+1)*(lpc_order+1))';
inverse_of_mid_exp_covariance=mid_exp_covar(1:(lpc_order+1)*(lpc_order+1))';
inverse_of_late_exp_covariance=late_exp_covar(1:(lpc_order+1)*(lpc_order+1))';

% Output the calculated inverse covariance matrices and mean feature
% vectors belonging to the 6 respiratory sub-phases to 2 separate files.
if	class_name==1
   fid=fopen('c:\windows\desktop\healthy_covariances.asm','wt');
else
   fid=fopen('c:\windows\desktop\pathological_covariances.asm','wt');
end
fprintf(fid,'; (1) inverse_of_early_insp_covariance =\n\n');
fprintf(fid,'   dc    %16.14f\n',inverse_of_early_insp_covariance);
fprintf(fid,'\n\n\n');
fprintf(fid,'; (2) inverse_of_mid_insp_covariance =\n\n');
fprintf(fid,'   dc    %16.14f\n',inverse_of_mid_insp_covariance);
fprintf(fid,'\n\n\n');
fprintf(fid,'; (3) inverse_of_late_insp_covariance =\n\n');
fprintf(fid,'   dc    %16.14f\n',inverse_of_late_insp_covariance);
fprintf(fid,'\n\n\n');
fprintf(fid,'; (4) inverse_of_early_exp_covariance =\n\n');
fprintf(fid,'   dc    %16.14f\n',inverse_of_early_exp_covariance);
fprintf(fid,'\n\n\n');
fprintf(fid,'; (5) inverse_of_mid_exp_covariance =\n\n');
fprintf(fid,'   dc    %16.14f\n',inverse_of_mid_exp_covariance);
fprintf(fid,'\n\n\n');
fprintf(fid,'; (6) inverse_of_late_exp_covariance =\n\n');
fprintf(fid,'   dc    %16.14f\n',inverse_of_late_exp_covariance);
fclose(fid);  



if	class_name==1
   fid=fopen('c:\windows\desktop\healthy_mean_lpcs.asm','wt');
else
   fid=fopen('c:\windows\desktop\pathological_mean_lpcs.asm','wt');
end

fprintf(fid,'; (1) mean_early_insp_feature =\n\n');
fprintf(fid,'   dc    %16.14f\n',mean_early_insp_feature);
fprintf(fid,'\n\n\n');
fprintf(fid,'; (2) mean_mid_insp_feature =\n\n');
fprintf(fid,'   dc    %16.14f\n',mean_mid_insp_feature);
fprintf(fid,'\n\n\n');
fprintf(fid,'; (3) mean_late_insp_feature =\n\n');
fprintf(fid,'   dc    %16.14f\n',mean_late_insp_feature);
fprintf(fid,'\n\n\n');
fprintf(fid,'; (4) mean_early_exp_feature =\n\n');
fprintf(fid,'   dc    %16.14f\n',mean_early_exp_feature);
fprintf(fid,'\n\n\n');
fprintf(fid,'; (5) mean_mid_exp_feature =\n\n');
fprintf(fid,'   dc    %16.14f\n',mean_mid_exp_feature);
fprintf(fid,'\n\n\n');
fprintf(fid,'; (6) mean_late_exp_feature =\n\n');
fprintf(fid,'   dc    %16.14f\n',mean_late_exp_feature);

fclose(fid);