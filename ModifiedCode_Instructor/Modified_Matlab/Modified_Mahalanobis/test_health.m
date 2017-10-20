function test_health;

% This function was used to test the performance of the Mahalanobis
% distance based minimum distance classifier while classifying the
% healthy subjects using the leave-one-out method. The feature vectors
% of the healthy lung sounds are organized, according to the order
% listed below in the vector named 's', in a MAT file named 'healthy.mat'.

class_name=1;
   
   s=['Enter the number of healthy subject you want to classify:\n'...
     	,'1.alper1','\n2.ba_ke1','\n3.burtecin1'...
     	,'\n4.en_de2','\n5.er_ac3','\n6.erhan1','\n7.fu_ca3'...
     	,'\n8.gokhan_ertas3','\n9.gokhan2','\n10.hisham2','\n11.hus1'...
     	,'\n12.ip_se2','\n13.is_ce3','\n14.me_do3','\n15.me_gu3'...
     	,'\n16.nez2','\n17.og_ka4','\n18.om_oz3','\n19.sameer1'...
     	,'\n20.ugur4','\n21.ya_ya4\n'];
   
   load healthy.mat; % Load feature vectors corresponding to the healthy class.
   total_sub_features=subject_features;
   subject_number=21; % A total of 21 resp. cycles.
      

% Now, select the number of the subject to be excluded from the reference library.
while (1),
   user_select=input(s);
   if user_select>subject_number|user_select<0
      ('Wrong number, please change your selection.')    
   else
      break;
   end	%%% Refers to if user_select>
end	%%% Refers to while(1)

lpc_order=6;
scale_amount=(1/8);
starting=1;
ending=starting+lpc_order+1;

%%%%%%%%%%%%%%%%%
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
   
   subject_2be_classified=total_sub_features(not_selected_sub:(not_selected_sub+(60*(lpc_order+2)-1)));   
      
   for	counter=1:subject_number	% Here subject_number is less than the original number by one.
      
      	if	subject_start==not_selected_sub	% Executed if the excluded subject is reached..
      		subject_start=subject_end+1;	% if it is excluded skip over it.
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
% the healthy subject features except the excluded one.
%****************************************************************
subject_start=1;
subject_end=subject_start+(60*(lpc_order+2))-1;
mean_lpc=zeros(60*(lpc_order+2),1);
for	h=1:subject_number
   mean_lpc=mean_lpc+subject_features(subject_start:subject_end);
	subject_start=subject_end+1;
	subject_end=subject_start+(60*(lpc_order+2))-1;
end
mean_lpc=(1/subject_number)*mean_lpc;	% Contains the 60 lpc vectors
													% averaged over all the subjects
													% (except the excluded one).

%--------------------------------------------------------------------
% Now, let us find the average LPC coeffs. over the ten segments of
% each sub-phase of the 60 averaged LPC vectors (belonging to the
% healthy subjects).
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

% These features are the ones to be used to represent the healthy class
% after excluding the one subject to be classified.
beta_early_insp_hlt=[early_insp_feature(2:lpc_order+1);early_insp_feature(lpc_order+2)];
beta_mid_insp_hlt=[mid_insp_feature(2:lpc_order+1);mid_insp_feature(lpc_order+2)];
beta_late_insp_hlt=[late_insp_feature(2:lpc_order+1);late_insp_feature(lpc_order+2)];
beta_early_exp_hlt=[early_exp_feature(2:lpc_order+1);early_exp_feature(lpc_order+2)];
beta_mid_exp_hlt=[mid_exp_feature(2:lpc_order+1);mid_exp_feature(lpc_order+2)];
beta_late_exp_hlt=[late_exp_feature(2:lpc_order+1);late_exp_feature(lpc_order+2)];



%*****************************************************************
%	Now, let us find the Inverse Covariance Matrices that represent
%  the healthy class after excluding the subject to be classified.
%*****************************************************************

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
% with the fractional number representation used on Motorola DSP
W_early_insp_hlt=(1/aa_max)*early_insp_covar;
W_mid_insp_hlt=(1/bb_max)*mid_insp_covar;
W_late_insp_hlt=(1/cc_max)*late_insp_covar;
W_early_exp_hlt=(1/dd_max)*early_exp_covar;
W_mid_exp_hlt=(1/ee_max)*mid_exp_covar;
W_late_exp_hlt=(1/ff_max)*late_exp_covar;



%*****************************************************************
% From now on find the mean feature vectors and inverse covariance
% matrices that represent the 'pathlogical class'.
%*****************************************************************

user_select=0;
   load pathology.mat; % Load workspace variables.
   total_sub_features=subject_features;
   subject_number=21; % A total of 21 pathological resp. cycles.
starting=1;
ending=starting+lpc_order+1;
subject_features=total_sub_features;	% Select all subjects.


subject_start=1;
subject_end=subject_start+(60*(lpc_order+2))-1;
mean_lpc=zeros(60*(lpc_order+2),1);
for	h=1:subject_number
   mean_lpc=mean_lpc+subject_features(subject_start:subject_end);
	subject_start=subject_end+1;
	subject_end=subject_start+(60*(lpc_order+2))-1;
end
mean_lpc=(1/subject_number)*mean_lpc;	% Contains the 60 lpc vectors
													% averaged over all the subjects.

%--------------------------------------------------------------------
% Now, let us find the average LPC coeffs. over the ten segments of
% each sub-phase of the 60 averaged LPC vectors (belonging to the 
% pathological class).
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

% These features are the scaled ones that represent the pathological class and that are
% going to be used by the DSP in the classification process.
beta_early_insp_pat=[early_insp_feature(2:lpc_order+1);early_insp_feature(lpc_order+2)];
beta_mid_insp_pat=[mid_insp_feature(2:lpc_order+1);mid_insp_feature(lpc_order+2)];
beta_late_insp_pat=[late_insp_feature(2:lpc_order+1);late_insp_feature(lpc_order+2)];
beta_early_exp_pat=[early_exp_feature(2:lpc_order+1);early_exp_feature(lpc_order+2)];
beta_mid_exp_pat=[mid_exp_feature(2:lpc_order+1);mid_exp_feature(lpc_order+2)];
beta_late_exp_pat=[late_exp_feature(2:lpc_order+1);late_exp_feature(lpc_order+2)];


%*****************************************************************
%	Now, let us find the Inverse Covariance Matrices that represent
%  the pathological class.
%*****************************************************************

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
% with the fractional number representation used on Motorola DSP
W_early_insp_pat=(1/aa_max)*early_insp_covar;
W_mid_insp_pat=(1/bb_max)*mid_insp_covar;
W_late_insp_pat=(1/cc_max)*late_insp_covar;
W_early_exp_pat=(1/dd_max)*early_exp_covar;
W_mid_exp_pat=(1/ee_max)*mid_exp_covar;
W_late_exp_pat=(1/ff_max)*late_exp_covar;

%*******************************************************************
% Output the mean LPC coeffs. that belong to the pathological class
%*******************************************************************
%beta_early_insp_pat
%beta_mid_insp_pat
%beta_late_insp_pat
%beta_early_exp_pat
%beta_mid_exp_pat
%beta_late_exp_pat

%*******************************************************************
% Output the calculated matrices row after row because these values
% are going to be stored in this order in the DSP's memory.
%*******************************************************************
%PATHOLOGY_inverse_of_early_insp_covariance=W_early_insp_pat(1:(lpc_order+1)*(lpc_order+1))'
%PATHOLOGY_inverse_of_mid_insp_covariance=W_mid_insp_pat(1:(lpc_order+1)*(lpc_order+1))'
%PATHOLOGY_inverse_of_late_insp_covariance=W_late_insp_pat(1:(lpc_order+1)*(lpc_order+1))'
%PATHOLOGY_inverse_of_early_exp_covariance=W_early_exp_pat(1:(lpc_order+1)*(lpc_order+1))'
%PATHOLOGY_inverse_of_mid_exp_covariance=W_mid_exp_pat(1:(lpc_order+1)*(lpc_order+1))'
%PATHOLOGY_inverse_of_late_exp_covariance=W_late_exp_pat(1:(lpc_order+1)*(lpc_order+1))'

count_hlt=0; % Counters for storing the votes
count_pat=0; % of both classes.

start_vec=2;
end_vec=start_vec+lpc_order;

%*********************************************************************
% Now, calculate tha Mahalanobis distances between the feature vectors
% of the subject to be classified and the templates representing both
% classes for each respiratory sub-phase.
%*********************************************************************

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%sub_phase1_start
for i=1:10

   beta=subject_2be_classified(start_vec:end_vec);
   d1=((beta_early_insp_hlt-beta)'*W_early_insp_hlt*(beta_early_insp_hlt-beta));
	d2=(beta_early_insp_pat-beta)'*W_early_insp_pat*(beta_early_insp_pat-beta);
   
   if	d1<d2
      count_hlt=count_hlt+1;
   else
      count_pat=count_pat+1;
   end;
   
   start_vec=end_vec+2;
   end_vec=start_vec+lpc_order;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%sub_phase2_start
for i=1:10
   beta=subject_2be_classified(start_vec:end_vec);
   d1=(beta_mid_insp_hlt-beta)'*W_mid_insp_hlt*(beta_mid_insp_hlt-beta);
	d2=(beta_mid_insp_pat-beta)'*W_mid_insp_pat*(beta_mid_insp_pat-beta);
   
   if	d1<d2
      count_hlt=count_hlt+1;
   else
      count_pat=count_pat+1;
   end;
   
   start_vec=end_vec+2;
   end_vec=start_vec+lpc_order;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%sub_phase3_start
for i=1:10
   beta=subject_2be_classified(start_vec:end_vec);
   d1=(beta_late_insp_hlt-beta)'*W_late_insp_hlt*(beta_late_insp_hlt-beta);
	d2=(beta_late_insp_pat-beta)'*W_late_insp_pat*(beta_late_insp_pat-beta);
   
   if	d1<d2
      count_hlt=count_hlt+1;
   else
      count_pat=count_pat+1;
   end;
   
   start_vec=end_vec+2;
   end_vec=start_vec+lpc_order;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%sub_phase4_start
for i=1:10
   beta=subject_2be_classified(start_vec:end_vec);
   d1=(beta_early_exp_hlt-beta)'*W_early_exp_hlt*(beta_early_exp_hlt-beta);
	d2=(beta_early_exp_pat-beta)'*W_early_exp_pat*(beta_early_exp_pat-beta);
   
   if	d1<d2
      count_hlt=count_hlt+1;
   else
      count_pat=count_pat+1;
   end;
   
   start_vec=end_vec+2;
   end_vec=start_vec+lpc_order;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%sub_phase5_start
for i=1:10
   beta=subject_2be_classified(start_vec:end_vec);
   d1=(beta_mid_exp_hlt-beta)'*W_mid_exp_hlt*(beta_mid_exp_hlt-beta);
	d2=(beta_mid_exp_pat-beta)'*W_mid_exp_pat*(beta_mid_exp_pat-beta);
   
   if	d1<d2
      count_hlt=count_hlt+1;
   else
      count_pat=count_pat+1;
   end;
   
   start_vec=end_vec+2;
   end_vec=start_vec+lpc_order;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%sub_phase6_start
for i=1:10
   beta=subject_2be_classified(start_vec:end_vec);
   d1=(beta_late_exp_hlt-beta)'*W_late_exp_hlt*(beta_late_exp_hlt-beta);
	d2=(beta_late_exp_pat-beta)'*W_late_exp_pat*(beta_late_exp_pat-beta);
   
   if	d1<d2
      count_hlt=count_hlt+1;
   else
      count_pat=count_pat+1;
   end;
   
   start_vec=end_vec+2;
   end_vec=start_vec+lpc_order;
end;


%************************************************************
%  Now, classify the whole respiratory cycle according to the
%  votes calculated for both of the classes.
%************************************************************

if count_hlt>count_pat
   ('HEALTHY subject')
   count_hlt	% Output the votes of the winner class.
elseif	count_hlt<count_pat
   ('PATHOLOGICAL subject')
   count_pat
else
   ('NOT KNOWN SITUATION')
end;
