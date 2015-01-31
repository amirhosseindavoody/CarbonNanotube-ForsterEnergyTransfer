!*******************************************************************************
! This program calculates the excitonic band structure of single wall carbon nanotubes through simple tight-binding method.
! Amirhossein Davoody
! Last modified: 3/17/2014
!*******************************************************************************

program cntForsterEnergyTransfer
  use cntClass
  use inputParameters
  use dataClass
	use prepareForster_module
  use perpendicularForster_module
	use parallelForster_module
	use arbitraryAngleForster_module
	
  implicit none
  
  type (cnt) :: cnt1, cnt2
	
  cnt1 = cnt( n_ch1, m_ch1, nkg)
  cnt2 = cnt (n_ch2, m_ch2, nkg)
  
  call cnt1.printProperties()
  call cnt2.printProperties()
  
  call cnt1.calculateBands(i_sub1, E_th, Kcm_max)
  call cnt2.calculateBands(i_sub2, E_th, Kcm_max)
  
  !call saveCNTProperties(cnt1)
  !call saveCNTProperties(cnt2)
	
	!pause
	!stop
  
  call loadExcitonWavefunction(cnt1)
  call loadExcitonWavefunction(cnt2)
	
	!pause
	!stop
  
  call findCrossings(cnt1,cnt2)
	call findSameEnergy(cnt1,cnt2)
  call saveTransitionPoints(cnt1,cnt2)

	call saveDOS(cnt1,cnt2)
	
	!pause
	!stop

	dTheta = thetaMax/dble(nTheta)
	dc2c = (c2cMax-c2cMin)/dble(nc2c)
	
	allocate(transitionRate(2,nTheta+1,nc2c+1))
	
	do ic2c = 1, nc2c+1
	
		c2cDistance = c2cMin+dble(ic2c-1)*dc2c
		
		call calculateParallelForsterRate(cnt1,cnt2)
	
		print *, 'iTheta=', 0, ', nTheta=', nTheta, 'iC2C=', ic2c-1, ', nC2C=', nc2c
	
		do iTheta = 1, nTheta

			theta = dble(iTheta)*dTheta
			print *, 'iTheta=', iTheta, ', nTheta=', nTheta, 'iC2C=', ic2c-1, ', nC2C=', nc2c		
			call calculateArbitraryForsterRate(cnt1,cnt2)
		end do
	end do
	
	call saveTransitionRates()
	
	print *, ''
  print *, 'Press Enter to continue ...'
  pause
  
end program cntForsterEnergyTransfer

