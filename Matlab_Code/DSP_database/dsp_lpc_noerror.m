
function	dsp_lpc_noerror

% This function is used to exclude the modeling error from the previously
% determined LPC coefficients. These coeffs are supposed to be generated
% using the DSP itself (not using Matlab), where scaled flow & lung samples
% are stored directly in the memory of the DSP and the calculated LPC coeffs
% and modeling error of each segment are read from the memory of the DSP
% using the dubug mode available with the DSP. Each of the calculated feature
% vectors contains the modeling error, which is not needed to train the k-NN
% based classifiers. The calculated feature vectors should be stored in the
% order determined in the vector 's' as MAT files called healthy_lpc.mat &
% pathological_lpc.mat.


  while (1),
  class_name=input('Enter 1 for Healthy, or 2 for Pathological LPC coeffs. (no error)');
      if class_name>2|class_name<1
         ('Wrong number, please change your selection.')
      else
         break;
      end	%%% Refers to class_name>..
	end	%%% Refers to while(1)..
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if	class_name==1
   
   load healthy_lpc.mat;	
   
   total_sub_features=[alper1;ba_ke1;burtecin1;en_de2;er_ac3;erhan1...
     	;fu_ca3;gokhan_ertas3;gokhan2;hisham2;hus1;ip_se2;is_ce3...
     	;me_do3;me_gu3;nez2;og_ka4;om_oz3;sameer1;ugur4;ya_ya4];
   
   subject_number=21;
      
   else
   
 
   load pathological_lpc.mat;
   
   total_sub_features=[ad_sa4;ali_du2;ar_kul1;ay_ak4;ca_sa3;...
         ;do_bi4;fa_sa1;ga_ka5;gu_il3;ha_ay3;ha_de4;ha_oz4;...
         ;ha_sa2;ha_yi5;is_co2;lu_uz2;me_al3;mu_ay4;os_di3;...
         ;ru_ba3;saf_oz2];
   
   subject_number=21;
end	%%% Refers to if class_name==...


  lpc_order=6;
  next_sub_start=1;
  next_sub_end=next_sub_start+(60*(lpc_order+2))-1;
  start_seg=1;
  end_seg=start_seg+lpc_order;

  for	all_subjects=1:subject_number	% Get the LPCs for each subject (with error).
  subject_lpc(1:60*(lpc_order+2))=total_sub_features(next_sub_start:next_sub_end);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     skip_error_strt=1;
     skip_error_end=skip_error_strt+lpc_order;

     
  	for	each_subject=1:60	% Exclude the modeling error for each subject.
     	lpc_noerror(start_seg:end_seg)=subject_lpc(skip_error_strt:skip_error_end);
     	start_seg=end_seg+1;
      end_seg=start_seg+lpc_order;
      skip_error_strt=skip_error_end+2;
      skip_error_end=skip_error_strt+lpc_order;
  	end	%%% Refers for each_subject=..
  % lpc_noerror now contains the LPCs of all subjects (without the error term).
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  next_sub_start=next_sub_end+1;
  next_sub_end=next_sub_start+(60*(lpc_order+2))-1;
end	%%% Refers to for all_subjects=..

noerror_start=1;
noerror_end=noerror_start+(60*(lpc_order+1))-1;

if	class_name==1

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%for file_number start...
for	file_number=1:subject_number	% Determine the name of person.

%%%%%%%%%switch start
   switch(file_number)
   case	1
      fid=fopen('c:\windows\desktop\alper1.asm','wt');
   case	2
      fid=fopen('c:\windows\desktop\ba_ke1.asm','wt');
   case	3
      fid=fopen('c:\windows\desktop\burtecin1.asm','wt');
      
   case	4
      fid=fopen('c:\windows\desktop\en_de2.asm','wt');

   case	5
      fid=fopen('c:\windows\desktop\er_ac3.asm','wt');
   case	6
      fid=fopen('c:\windows\desktop\erhan1.asm','wt');
   case	7
      fid=fopen('c:\windows\desktop\fu_ca3.asm','wt');
   case	8
      fid=fopen('c:\windows\desktop\gokhan_ertas3.asm','wt');
   case	9
      fid=fopen('c:\windows\desktop\gokhan2.asm','wt');
   case	10
      fid=fopen('c:\windows\desktop\hisham2.asm','wt');
   case	11
      fid=fopen('c:\windows\desktop\hus1.asm','wt');
   case	12
      fid=fopen('c:\windows\desktop\ip_se2.asm','wt');
   case	13
      fid=fopen('c:\windows\desktop\is_ce3.asm','wt');
   case	14
      fid=fopen('c:\windows\desktop\me_do3.asm','wt');
   case	15
      fid=fopen('c:\windows\desktop\me_gu3.asm','wt');
   case	16
      fid=fopen('c:\windows\desktop\nez2.asm','wt');
   case	17
      fid=fopen('c:\windows\desktop\og_ka4.asm','wt');
   case	18
      fid=fopen('c:\windows\desktop\om_oz3.asm','wt');
   case	19
      fid=fopen('c:\windows\desktop\sameer1.asm','wt');
   case	20
      fid=fopen('c:\windows\desktop\ugur4.asm','wt');
   case	21
      fid=fopen('c:\windows\desktop\ya_ya4.asm','wt');
   end	%%% Refers to switch
           
         
%%%%%%%%%switch end
      fprintf(fid,'   dc    %16.14f\n',lpc_noerror(noerror_start:noerror_end));
      fclose(fid); 
      noerror_start=noerror_end+1;
      noerror_end=noerror_start+(60*(lpc_order+1))-1;
   end	%%% Refers to for file_number=1...
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%for file_number end...   
   
else	% This branch is taken for pathological case.
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%for file_number start...

for	file_number=1:subject_number	% Repeat the above for pathological case.

%%%%%%%%%switch start
   switch(file_number)
   case	1
      fid=fopen('c:\windows\desktop\ad_sa4.asm','wt');
   case	2
      fid=fopen('c:\windows\desktop\ali_du2.asm','wt');
   case	3
      fid=fopen('c:\windows\desktop\ar_kul1.asm','wt');
      
   case	4
      fid=fopen('c:\windows\desktop\ay_ak4.asm','wt');

   case	5
      fid=fopen('c:\windows\desktop\ca_sa3.asm','wt');
   case	6
      fid=fopen('c:\windows\desktop\do_bi4.asm','wt');
   case	7
      fid=fopen('c:\windows\desktop\fa_sa1.asm','wt');
   case	8
      fid=fopen('c:\windows\desktop\ga_ka5.asm','wt');
   case	9
      fid=fopen('c:\windows\desktop\gu_il3.asm','wt');
   case	10
      fid=fopen('c:\windows\desktop\ha_ay3.asm','wt');
   case	11
      fid=fopen('c:\windows\desktop\ha_de4.asm','wt');
   case	12
      fid=fopen('c:\windows\desktop\ha_oz4.asm','wt');
   case	13
      fid=fopen('c:\windows\desktop\ha_sa2.asm','wt');
   case	14
      fid=fopen('c:\windows\desktop\ha_yi5.asm','wt');
   case	15
      fid=fopen('c:\windows\desktop\is_co2.asm','wt');
   case	16
      fid=fopen('c:\windows\desktop\lu_uz2.asm','wt');
   case	17
      fid=fopen('c:\windows\desktop\me_al3.asm','wt');
   case	18
      fid=fopen('c:\windows\desktop\mu_ay4.asm','wt');
   case	19
      fid=fopen('c:\windows\desktop\os_di3.asm','wt');
   case	20
      fid=fopen('c:\windows\desktop\ru_ba3.asm','wt');
   case	21
      fid=fopen('c:\windows\desktop\saf_oz2.asm','wt');
   end	%%% Refers to switch
   
%%%%%%%%%switch end
 fprintf(fid,'   dc    %16.14f\n',lpc_noerror(noerror_start:noerror_end));
 fclose(fid); 
 noerror_start=noerror_end+1;
 noerror_end=noerror_start+(60*(lpc_order+1))-1;
end	%%% Refers to for file_number=1...
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%for file_number end... 
 
end	%%% Refers to if class_name==


