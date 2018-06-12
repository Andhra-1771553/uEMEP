!uEMEP_read_time_profiles.f90
    
    subroutine uEMEP_read_time_profiles
    
    use uEMEP_definitions
    
    implicit none
    
    integer i,j,k
    character(256) temp_str
    integer unit_in
    integer exists
    integer week_day_temp,hour_temp
    double precision date_num_temp

    integer n_col
    parameter (n_col=5)
    character(256) header_str(n_col)
    integer source_index_in(n_col-1)
    integer region_id
    integer n_hours_in_week,n_months_in_year
    integer, allocatable :: time_month_of_year_input(:),time_hour_of_week_input(:)
    real, allocatable :: val_month_of_year_input(:,:),val_hour_of_week_input(:,:)
    integer date_array(6)
    integer i_source,t,hour_of_week_index
    
    !Functions
    integer day_of_week
    !double precision date_to_number
    
    !emission_time_profile_subgrid=1.
    
    !Only read data if flag is correct
    if (local_subgrid_method_flag.ne.2) return
    
	write(unit_logfile,'(A)') ''
	write(unit_logfile,'(A)') '================================================================'
	write(unit_logfile,'(A)') 'Reading time profiles (uEMEP_read_time_profiles)'
	write(unit_logfile,'(A)') '================================================================'

    pathfilename_timeprofile=trim(pathname_timeprofile)//trim(filename_timeprofile)

    !Test existence of the filename. If does not exist then use default
    inquire(file=trim(pathfilename_timeprofile),exist=exists)
    if (.not.exists) then
        write(*,'(A,A)') ' ERROR: Time profile data file does not exist: ', trim(pathfilename_timeprofile)
        stop
    endif

    
    !Open the file for reading
    unit_in=20
    open(unit_in,file=pathfilename_timeprofile,access='sequential',status='old',readonly)  
    write(unit_logfile,'(a)') ' Opening time profile file: '//trim(pathfilename_timeprofile)
    
    !Read source header string
    read(unit_in,*) header_str
    !write(unit_logfile,*) header_str
    
    !Read source index, correpsonding to uEMEP source indexes (change to SNAP or NFR later)
    read(unit_in,*) temp_str,source_index_in
    write(unit_logfile,*) trim(temp_str),source_index_in

    !Read region
    read(unit_in,*) temp_str,region_id
    write(unit_logfile,'(a,i)') trim(temp_str),region_id
     
    !Read Hour_of_week
    read(unit_in,*) temp_str,n_hours_in_week
    write(unit_logfile,'(a,i)') trim(temp_str),n_hours_in_week

    
    !write(*,*) num_week_traffic,days_in_week,hours_in_day,n_roadlinks
    if (.not.allocated(time_hour_of_week_input)) allocate (time_hour_of_week_input(n_hours_in_week))
    if (.not.allocated(val_hour_of_week_input)) allocate (val_hour_of_week_input(n_hours_in_week,n_col-1))
    
    do i=1,n_hours_in_week
        read(unit_in,*) time_hour_of_week_input(i),val_hour_of_week_input(i,1:n_col-1)    
        !write(*,*) time_hour_of_week_input(i),val_hour_of_week_input(i,1:n_col-1)  
    enddo
    
    !Read Hour_of_week
    read(unit_in,*) temp_str,n_months_in_year
    write(unit_logfile,'(a,i)') trim(temp_str),n_months_in_year

    
    !write(*,*) num_week_traffic,days_in_week,hours_in_day,n_roadlinks
    if (.not.allocated(time_month_of_year_input)) allocate (time_month_of_year_input(n_months_in_year))
    if (.not.allocated(val_month_of_year_input)) allocate (val_month_of_year_input(n_months_in_year,n_col-1))
    
    do i=1,n_months_in_year
        read(unit_in,*) time_month_of_year_input(i),val_month_of_year_input(i,1:n_col-1)    
        !write(*,*) time_month_of_year_input(i),val_month_of_year_input(i,1:n_col-1)  
    enddo    
    
    close(unit_in,status='keep')
    !close(unit_in)
    
    !Normalise the data to be used with average emmissions
    do i_source=1,n_col-1
    val_hour_of_week_input(:,i_source)=val_hour_of_week_input(:,i_source)/sum(val_hour_of_week_input(:,i_source))*n_hours_in_week
    val_month_of_year_input(:,i_source)=val_month_of_year_input(:,i_source)/sum(val_month_of_year_input(:,i_source))*n_months_in_year
    enddo
    
    !Get time information for the current calculation
    
    do t=1,dim_length_nc(time_dim_nc_index)
        !EMEP date is days since 1900
        !write(*,*) val_dim_nc(t,time_dim_nc_index)
        !Round up the hour
        date_num_temp=dble(ceiling(val_dim_nc(t,time_dim_nc_index)*24.))/24.
        !write(*,*) real(ceiling(val_dim_nc(t,time_dim_nc_index)*24.)),date_num_temp
        
        call number_to_date(date_num_temp,date_array,ref_year_EMEP)
        if (t.eq.1) write(unit_logfile,'(a,6i6)') 'Date array start = ',date_array
        if (t.eq.dim_length_nc(time_dim_nc_index)) write(unit_logfile,'(a,6i6)') 'Date array end = ',date_array
        week_day_temp= day_of_week(date_array)
        !write(unit_logfile,*) 'Day of week = ',week_day_temp
        
        hour_of_week_index=(week_day_temp-1)*24+date_array(4)+1+int(emission_timeprofile_hour_shift)
        if (hour_of_week_index.gt.n_hours_in_week) hour_of_week_index=hour_of_week_index-n_hours_in_week
        if (hour_of_week_index.lt.1) hour_of_week_index=hour_of_week_index+n_hours_in_week
        emission_time_profile_subgrid(:,:,t,:,:)=1.
        do i_source=1,n_col-1
            emission_time_profile_subgrid(:,:,t,source_index_in(i_source),:)=val_hour_of_week_input(hour_of_week_index,i_source)*val_month_of_year_input(date_array(2),i_source)
            !write(*,*) hour_of_week_index,val_hour_of_week_input(hour_of_week_index,i_source),val_month_of_year_input(date_array(2),i_source)
            !write(*,*) emission_time_profile_subgrid(1,1,t,source_index_in(i_source),1)
        enddo
        
        if (annual_calculations) then
            emission_time_profile_subgrid(:,:,t,:,:)=1.
        endif
           
    enddo
    
    deallocate (time_hour_of_week_input)
    deallocate (val_hour_of_week_input)
    deallocate (time_month_of_year_input)
    deallocate (val_month_of_year_input)
    
   
    end subroutine uEMEP_read_time_profiles
