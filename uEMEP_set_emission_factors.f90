!uEMEP_set_emission_factors.f90
    
    subroutine uEMEP_set_emission_factors
    
    use uEMEP_definitions
    
    implicit none
    
    write(unit_logfile,'(A)') ''
    write(unit_logfile,'(A)') '================================================================'
	write(unit_logfile,'(A)') 'Setting emission factors (uEMEP_set_emission_factors)'
	write(unit_logfile,'(A)') '================================================================'

    !Converts the emission units of the input data to a standard ug/s/subgrid
    emission_factor(nox_index,traffic_index,:)=(0.6)*(1.e-3)*(1.e+6)/(3600.*24.) ![veh*m/day]*(g/km/veh)*(km/m)*(ug/g)*(day/sec)=ug/sec
    emission_factor(nox_index,shipping_index,:)=(1.e+12)/(3600.*24.*365./12.) ![tonne/month]*(ug/kg)*(month/sec)=ug/sec

    emission_factor(no2_index,traffic_index,:)=0.15*emission_factor(nox_index,traffic_index,:)
    emission_factor(no2_index,shipping_index,:)=0.10*emission_factor(nox_index,shipping_index,:)

    emission_factor(pm25_index,traffic_index,:)=(0.03)*(1.e-3)*(1.e+6)/(3600.*24.) ![veh*m/day]*(g/km/veh)*(km/m)*(ug/g)*(day/sec)=ug/sec
    emission_factor(pm25_index,shipping_index,:)=(1.e+12)/(3600.*24.*365./12.) ![tonne/month]*(ug/kg)*(month/sec)=ug/sec
    emission_factor(pm25_index,heating_index,:)=(3.)*(1.e+9)/(3600.*24.*365.) ![dwellings]*(kg/dwelling/year)*(ug/kg)*(year/sec)=ug/sec

    emission_factor(nh3_index,agriculture_index,:)=(1.e+9)/(3600.*24.*365.)   ![kg/yr]*(ug/kg)*(yr/sec)=ug/sec
    
   
    end subroutine uEMEP_set_emission_factors

!uEMEP_convert_proxy_to_emissions
    
    subroutine uEMEP_convert_proxy_to_emissions
    
    use uEMEP_definitions
    
    implicit none
    
    integer i_source,i_subsource
    integer tt
    
    write(unit_logfile,'(A)') ''
    write(unit_logfile,'(A)') '================================================================'
	write(unit_logfile,'(A)') 'Converting proxy data to emissions (uEMEP_convert_proxy_to_emissions)'
	write(unit_logfile,'(A)') '================================================================'

    !Set all emissions to the same constant emission value with emissions in ug/sec for all sources
    do i_source=1,n_source_index
    if (calculate_source(i_source)) then
        do i_subsource=1,n_subsource(i_source)
            !proxy_emission_subgrid(:,:,i_source,i_subsource)=proxy_emission_subgrid(:,:,i_source,i_subsource)*emission_factor(compound_index,i_source,i_subsource)
            do tt=1,subgrid_dim(t_dim_index)

                emission_subgrid(:,:,tt,i_source,i_subsource)=proxy_emission_subgrid(:,:,i_source,i_subsource)*emission_factor(compound_index,i_source,i_subsource)
   
            enddo
        enddo
    endif
    enddo
    
    
    end subroutine uEMEP_convert_proxy_to_emissions
