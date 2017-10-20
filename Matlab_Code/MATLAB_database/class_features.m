function class_features

% According to the user's selection,this function either calculates the
% LPC coefficients of the selected respiration cycle or calculates the
% mean feature vectors and the inverse covariance matrices for each of
% the six sub-phases corresponding to the selected resp. cycle.

user_choice=input('Press 1 To Find The LPC Array, 2 To Find The Inverse Covariance Matrix, or Any Number to Exit:');

if user_choice==2 % If true, calculate the mean feature vectors first.
win_length=input('DETERMINE THE HAMMING WINDOW LENGTH:');% Should be 512 @ sampling rate of 8kHz.
lpc_order=input('DETERMINE THE LPC MODELING ORDER:');% Sixth order is adequate.
scale_amount=input('DETERMINE THE SCALE AMOUNT TO BE APPLIED TO THE RESULTS:');% Should be 1/8 (DSP's fractional number format).
all_subjects=input('How Many Subjects Are There In This Class?');
early_insp_feature=zeros(lpc_order+2,1);
mid_insp_feature=zeros(lpc_order+2,1);
late_insp_feature=zeros(lpc_order+2,1);
early_exp_feature=zeros(lpc_order+2,1);
mid_exp_feature=zeros(lpc_order+2,1);
late_exp_feature=zeros(lpc_order+2,1);
subject_features=zeros(all_subjects*60*(lpc_order+2),1);
feature_start=1;
feature_end=60*(lpc_order+2);

% First find the lpc coefficients for all the subjects.
for   mm=1:all_subjects,
   [a,b,c,d,e,f,g]=mean_feature(mm,lpc_order,win_length);
   early_insp_feature=early_insp_feature+b;
   mid_insp_feature=mid_insp_feature+c;
   late_insp_feature=late_insp_feature+d;
   early_exp_feature=early_exp_feature+e;
   mid_exp_feature=mid_exp_feature+f;
   late_exp_feature=late_exp_feature+g;
   subject_features(feature_start:feature_end)=a;
   feature_start=feature_end+1;
   feature_end=feature_start+(60*(lpc_order+2))-1;
end

% Now find the mean of the calculated feature vectors for each of the
% six sub-phases.

('THE CALCULATED MEAN FEATURE VECTORS CORRESPONDING TO EACH RESPIRATION SUB-PHASE ARE:')
early_insp_feature=early_insp_feature/all_subjects;
mid_insp_feature=mid_insp_feature/all_subjects;
late_insp_feature=late_insp_feature/all_subjects;
early_exp_feature=early_exp_feature/all_subjects;
mid_exp_feature=mid_exp_feature/all_subjects;
late_exp_feature=late_exp_feature/all_subjects;  

% Scale these features to values that could be represented on the DSP.
mean_early_insp_feature=[scale_amount*early_insp_feature(2:lpc_order+1);early_insp_feature(lpc_order+2)]
mean_mid_insp_feature=[scale_amount*mid_insp_feature(2:lpc_order+1);mid_insp_feature(lpc_order+2)]
mean_late_insp_feature=[scale_amount*late_insp_feature(2:lpc_order+1);late_insp_feature(lpc_order+2)]
mean_early_exp_feature=[scale_amount*early_exp_feature(2:lpc_order+1);early_exp_feature(lpc_order+2)]
mean_mid_exp_feature=[scale_amount*mid_exp_feature(2:lpc_order+1);mid_exp_feature(lpc_order+2)]
mean_late_exp_feature=[scale_amount*late_exp_feature(2:lpc_order+1);late_exp_feature(lpc_order+2)]

% Now calculate the covariance matrices, but first initialize them
% with zero.
early_insp_covar=zeros(lpc_order+1,lpc_order+1);
mid_insp_covar=zeros(lpc_order+1,lpc_order+1);
late_insp_covar=zeros(lpc_order+1,lpc_order+1);
early_exp_covar=zeros(lpc_order+1,lpc_order+1);
mid_exp_covar=zeros(lpc_order+1,lpc_order+1);
late_exp_covar=zeros(lpc_order+1,lpc_order+1);

next_subject_features=2;
subject_end=lpc_order+2;

% The following loop calculates the covariance matrices.
for   outer_loop=1:all_subjects,
subject_start=next_subject_features;
temp_matrix=zeros(lpc_order+1,lpc_order+1);
early_insp_temp=zeros(lpc_order+1,lpc_order+1);
for   kk=1:10, % Each sub-phase consists of ten segments.
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
end   %%% Refers to "for   outer_loop=1:all_subjects"


% Find the inverse covariance matrices.
early_insp_covar=inv((1/all_subjects)*(early_insp_covar));
mid_insp_covar=inv((1/all_subjects)*(mid_insp_covar));
late_insp_covar=inv((1/all_subjects)*(late_insp_covar));
early_exp_covar=inv((1/all_subjects)*(early_exp_covar));
mid_exp_covar=inv((1/all_subjects)*(mid_exp_covar));
late_exp_covar=inv((1/all_subjects)*(late_exp_covar));

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

% Scale down the inverse covariance matrices so as to make them compatible
% with the fractional number representation used on Motorola DSP.
('THE INVERSE COVARIANCE MATRICES OF EACH RESPIRATION SUB-PHASE WERE FOUND AS FOLLOWS:')
early_insp_covar=(1/aa_max)*early_insp_covar;
mid_insp_covar=(1/bb_max)*mid_insp_covar;
late_insp_covar=(1/cc_max)*late_insp_covar;
early_exp_covar=(1/dd_max)*early_exp_covar;
mid_exp_covar=(1/ee_max)*mid_exp_covar;
late_exp_covar=(1/ff_max)*late_exp_covar;

% Output the calculated matrices row after row because these values are
% going to be stored in this order in the DSP's memory.
inverse_of_early_insp_covariance=early_insp_covar(1:(lpc_order+1)*(lpc_order+1))'
inverse_of_mid_insp_covariance=mid_insp_covar(1:(lpc_order+1)*(lpc_order+1))'
inverse_of_late_insp_covariance=late_insp_covar(1:(lpc_order+1)*(lpc_order+1))'
inverse_of_early_exp_covariance=early_exp_covar(1:(lpc_order+1)*(lpc_order+1))'
inverse_of_mid_exp_covariance=mid_exp_covar(1:(lpc_order+1)*(lpc_order+1))'
inverse_of_late_exp_covariance=late_exp_covar(1:(lpc_order+1)*(lpc_order+1))'


% If the following statement is true then only the LPC array regarding
% the selected resp. cycle is calculated.

elseif   user_choice==1   %%% Refers to if user_choice==1
	win_length=input('DETERMINE THE HAMMING WINDOW LENGTH:');   
   lpc_order=input('DETERMINE THE LPC MODELING ORDER:');
   scale_amount=input('DETERMINE THE SCALE AMOUNT TO BE APPLIED TO THE RESULTS:');
   [a,b,c,d,e,f,g,autocorr_coeffs]=mean_feature(1,lpc_order,win_length);
   segment_start=1;
   segment_end=lpc_order+1;
   no_error=0;
	LPC_array=zeros(60*(lpc_order+1),1);
   
   % The following loop is used to exclude the modeling error from the
   % LPC array.
   for   segment_number=1:60,
      LPC_array(segment_start:segment_end)=a(no_error+segment_start:no_error+segment_start+lpc_order);
      segment_start=segment_end+1;
      segment_end=segment_start+lpc_order;

   no_error=no_error+1;   
   
   end   %%% Refers to for   segment_number=1:60
   
LPC_with_error=zeros(60*(lpc_order+2),1);
scaled_start=1;
scaled_end=lpc_order+1;

for	frame_number=1:60,   
LPC_with_error(scaled_start:scaled_end)=scale_amount*a(scaled_start:scaled_end);
LPC_with_error(scaled_end+1)=a(scaled_end+1);
scaled_start=scaled_end+2;
scaled_end=scaled_start+lpc_order;
end


%----------------------------------------------------------------------
% The following is used to produce an output file containing LPC ceoffs
% with the modeling error appended to each vector. The generated file
% can be used in conjunction with test_mah.m file to test performance
% of the Mahalanobis distance based minimum distance classifier using
% the leave-one-out method.
%----------------------------------------------------------------------
%fid=fopen('c:\windows\desktop\LPC_values(with_error).asm','wt');
%fprintf(fid,'   dc    %16.14f\n',LPC_with_error);
%fclose(fid);   
%----------------------------------------------------------------------


%***********************************************************************
% The following is used to produce an output file containing the scaled
% autocorr. values corresponding to the selected respiratory cycle. The
% generated file, in conjuntion with the file LPC_values(no_error).asm,
% can be used to measure the performance of the k-NN based classifiers
% using the leave-one-out method.
%***********************************************************************
%autocorr_coeffs=0.5*autocorr_coeffs; %scaled autocorr values
%fid=fopen('c:\windows\desktop\autocorr_coeffs.asm','wt');
%fprintf(fid,'   dc    %16.14f\n',autocorr_coeffs);
%fclose(fid);
%***********************************************************************   


% The following is used to produce an output fie containing the LPC
% coeffs. that can be used to train the k-NN based classifiers.
LPC_values= LPC_array*scale_amount; %output the scaled LPC array
fid=fopen('c:\windows\desktop\LPC_values(no_error).asm','wt');
fprintf(fid,'   dc    %16.14f\n',LPC_values);
fclose(fid);

else	%%% Refers to if user_choice==1   
   
end	%%% Refers to if user_choice==1