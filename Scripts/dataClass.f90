module dataClass
    use cntClass
    implicit none
    
    private
    
    public  :: saveCNTProperties, loadExcitonWavefunction
    
    contains
      !**************************************************************************************************************************
      ! save the properties of carbon nanotubes that are calculated in cnt_class
      !**************************************************************************************************************************
      subroutine saveCNTProperties(currCNT)
        use ifport
        use inputParameters
        type(cnt), intent(in) :: currCNT
        character*100 :: dirname
        integer(4) :: istat
        logical(4) :: result
        integer :: i, j
        
        !change the directory to that of the CNT
        write(dirname,"('CNT_',I2.2,'_',I2.2,'_',I4.4,'_',I4.4,'_',F3.1,'_',I1.1)") currcnt.n_ch, currcnt.m_ch, nkg, nr, E_th, currcnt.i_sub
        result=makedirqq(dirname)
        if (result) print *,'Directory creation successful!!'
    
        istat=chdir(dirname)
        if (istat .ne. 0) then
            print *, 'Directory did not changed!!!'
            pause
            stop
        end if
        
        ! save the position of A-type and B-type carbon atoms
        open(unit=100, file='posA.dat',status='unknown')
        open(unit=101, file='posB.dat',status='unknown')
        do i=1,size(currcnt.posA,1)
          write(100,14) currcnt.posA(i,1), currcnt.posA(i,2)
          write(101,14) currcnt.posB(i,1), currcnt.posB(i,2)
        end do
        close(100)
        close(101)
        
        open(unit=100, file="CondBand_Sub.dat", status="unknown")
        open(unit=101, file="ValeBand_Sub.dat", status="unknown")
        
        do i=currcnt.ik_low,currcnt.ik_high
          write(100,10, advance='no') dble(i)*currcnt.dk
          write(101,10, advance='no') dble(i)*currcnt.dk
        end do
        write(100,10)
        write(101,10)
        
        do i=currcnt.ik_low,currcnt.ik_high
          write(100,10, advance='no') currcnt.Ek(1,i,1)
          write(101,10, advance='no') currcnt.Ek(1,i,2)
        end do
        write(100,10)
        write(101,10)
        
        do i=currcnt.ik_low,currcnt.ik_high
          write(100,10, advance='no') currcnt.Ek(2,i,1)
          write(101,10, advance='no') currcnt.Ek(2,i,2)
        end do
        
        close(100)
        close(101)
        
        !change the directory back
        istat=chdir('..')
        if (istat .ne. 0) then
            print *, 'Directory did not changed!!!'
            pause
            stop
        end if
        
        10 FORMAT (E16.8)
        14 FORMAT (E16.8,E16.8) 
      end subroutine saveCNTProperties
      
      !**************************************************************************************************************************
      ! load the exciton wavefunction and energies from the ExcitonEnergy calculation
      !**************************************************************************************************************************
      subroutine loadExcitonWavefunction(currCNT)
        use ifport
        use inputParameters
        type(cnt), intent(inout) :: currCNT
        character*100 :: dirname
        integer(4) :: istat
        logical(4) :: result
        integer :: iX, iKcm, ikr
        
        call loadMiscData(currcnt)
        
        !change the directory to that of the CNT
        write(dirname,"('CNT_',I2.2,'_',I2.2,'_',I4.4,'_',I4.4,'_',F3.1,'_',I1.1)") currcnt.n_ch, currcnt.m_ch, nkg, nr, E_th/eV, currcnt.i_sub
        istat=chdir(dirname)
        if (istat .ne. 0) then
            print *, 'Directory did not changed!!!'
            pause
            stop
        end if
        
        open(unit=100,file='Ex_A1.dat',status="old")
        open(unit=101,file='Ex0_A2.dat',status="old")
        open(unit=102,file='Ex1_A2.dat',status="old")
        open(unit=103,file='Psi_A1.dat',status="old")
        open(unit=104,file='Psi0_A2.dat',status="old")
        open(unit=105,file='Psi1_A2.dat',status="old")
        
        allocate(currcnt.Ex_A1(1:currcnt.nX,currcnt.iKcm_min:currcnt.iKcm_max))
        allocate(currcnt.Ex0_A2(1:currcnt.nX,currcnt.iKcm_min:currcnt.iKcm_max))
        allocate(currcnt.Ex1_A2(1:currcnt.nX,currcnt.iKcm_min:currcnt.iKcm_max))
        allocate(currcnt.Psi_A1(currcnt.ikr_low:currcnt.ikr_high,1:currcnt.nX,currcnt.iKcm_min:currcnt.iKcm_max))
        allocate(currcnt.Psi0_A2(currcnt.ikr_low:currcnt.ikr_high,1:currcnt.nX,currcnt.iKcm_min:currcnt.iKcm_max))
        allocate(currcnt.Psi1_A2(currcnt.ikr_low:currcnt.ikr_high,1:currcnt.nX,currcnt.iKcm_min:currcnt.iKcm_max))
        
        do iKcm=currcnt.iKcm_min,currcnt.iKcm_max
          do iX=1,currcnt.nX
            read(100,10, advance='no') currcnt.Ex_A1(iX,iKcm)
            read(101,10, advance='no') currcnt.Ex0_A2(iX,iKcm)
            read(102,10, advance='no') currcnt.Ex1_A2(iX,iKcm)
            do ikr=currcnt.ikr_low,currcnt.ikr_high
              read(103,11, advance='no') currcnt.Psi_A1(ikr,iX,iKcm)
              read(104,11, advance='no') currcnt.Psi0_A2(ikr,iX,iKcm)
              read(105,11, advance='no') currcnt.Psi1_A2(ikr,iX,iKcm)
            enddo
          enddo
          
          read(100,10)
          read(101,10)
          read(102,10)
          read(103,10)
          read(104,10)
          read(105,10)
        enddo
        
        
        close(100)
        close(101)
        close(102)
        close(103)
        close(104)
        close(105)
    
        10 FORMAT (E16.8)  
        11 FORMAT (E16.8,E16.8) 
        
        !change the directory back
        istat=chdir('..')
        if (istat .ne. 0) then
            print *, 'Directory did not changed!!!'
            pause
            stop
        end if
        
      end subroutine loadExcitonWavefunction
      
      !**************************************************************************************************************************
      ! load the data from miscellaneous.dat file from ExcitonEnergy calculation
      !**************************************************************************************************************************
      subroutine loadMiscData(currCNT)
        use ifport
        use inputParameters
        type(cnt), intent(inout) :: currCNT
        character*100 :: dirname
        integer(4) :: istat
        logical(4) :: result
        integer :: min_sub, ik_max, iKcm_max, ikr_high, ik_high, iq_max, nX
        real*8 :: dk
        
        !change the directory to that of the CNT
        write(dirname,"('CNT_',I2.2,'_',I2.2,'_',I4.4,'_',I4.4,'_',F3.1,'_',I1.1)") currcnt.n_ch, currcnt.m_ch, nkg, nr, E_th/eV, currcnt.i_sub
        istat=chdir(dirname)
        if (istat .ne. 0) then
            print *, 'Directory did not changed!!!'
            pause
            stop
        end if
        
        open(unit=100,file='miscellaneous.dat',status="old")
        read(100,10) min_sub
        read(100,10) ik_max
        read(100,10) iKcm_max
        read(100,10) ikr_high
        read(100,10) ik_high
        read(100,10) iq_max
        read(100,10) nX
        read(100,11) dk
        
        close(100)
  
        if (min_sub .ne. currcnt.min_sub(currcnt.i_sub)) then
          print *, min_sub
          print *, currcnt.min_sub(currcnt.i_sub)
          print *, "Error in matching min_sub variables!"
          pause
          stop
        end if
        
        if (ik_max .ne. currcnt.ik_max) then
          print *, "Error in matching ik_max variables!"
          pause
          stop
        end if
        
        if (iKcm_max .ne. currcnt.iKcm_max) then
          print *, "Error in matching iKcm_max variables!"
          pause
          stop
        end if
        
        if (ikr_high .ne. currcnt.ikr_high) then
          print *, "Error in matching ikr_high variables!"
          pause
          stop
        end if
        
        if (ik_high .ne. currcnt.ik_high) then
          print *, "Error in matching ik_high variables!"
          pause
          stop
        end if
        
        if (iq_max .ne. currcnt.iq_max) then
          print *, "Error in matching iq_max variables!"
          pause
          stop
        end if
        
        ! you don't need to check dk since there are round off errors in real numbers when writing and reading from files
        currcnt.nX = nX
    
        10 FORMAT (I4.4) 
        11 FORMAT (E16.8)
        
        !change the directory back
        istat=chdir('..')
        if (istat .ne. 0) then
            print *, 'Directory did not changed!!!'
            pause
            stop
        end if
        
      end subroutine loadMiscData
    
    
end module dataClass