module cnt_class
    implicit none
    private
    
    public  :: cnt, init_cnt, calculateBands
    
    type cnt
      integer, public :: n_ch,m_ch !chiral vector parameters
      integer, public :: i_sub !subband index used in exciton energy calculation
    
      !Geometrical properties
      real*8, dimension(2) :: a1,a2,b1,b2,ch_vec,t_vec,aCC_vec
      real*8 :: len_ch,radius
      integer :: Nu
      real*8, dimension(:,:), allocatable, public :: posA,posB,posAA,posBB,posAB,posBA
      real*8, dimension(:,:), allocatable, public :: posA3, posB3
      real*8, dimension(:,:,:), allocatable, public :: pos2d, pos3d

      !Environment properties
      real*8, public :: kappa, Ckappa
    
      !Reciprocal lattice properties
      real*8, public :: dk
      real*8, dimension(2) :: K1, K2
      
      !CNT band structure properties
      integer, dimension(:), allocatable :: min_sub
      integer, public :: ikc_max, ikc_min, ik_max, ik_min, iKcm_max, iKcm_min, ik_high, ik_low, ikr_high, ikr_low, iq_max, iq_min
      
      !CNT self energy and tight binding coefficients
      real*8, dimension(:,:,:), allocatable, public :: Ek  !Tight-binding energy
      real*8, dimension(:,:,:), allocatable:: Sk  !Self-energy 
      complex*16, dimension(:,:,:), allocatable:: Cc,Cv !Tight-binding wavefunction coefficients
      
      !Exciton wavefunction and energies
      real*8, dimension(:,:), allocatable, public :: Ex_A1, Ex0_A2, Ex1_A2 !the first index is subband, the second index is iKcm
      complex*16, dimension(:,:,:), allocatable, public :: Psi_A1, Psi0_A2, Psi1_A2 !the first index is ikr, the scond index is the subband, the third index is iKcm

      !Target exciton wavefunction and energies
      real*8, dimension(:,:), allocatable, public :: Ex_t !the first index is subband, the second index is iKcm
      complex*16, dimension(:,:,:), allocatable, public :: Psi_t !the first index is ikr, the scond index is the subband, the third index is iKcm      

      !number of exciton bands below free-electron free-hole energy level
      integer, public :: nX
			
    end type cnt
          
contains
      
      !**************************************************************************************************************************
      ! initialize CNT by calculating its geometrical properties
      !**************************************************************************************************************************
      
      function init_cnt(n_ch, m_ch, nkg, nX, kappa, Ckappa) result(currcnt)
        use mathFunctionsMOD, only: gcd
        use physicalConstants, only: a_l, pi

        integer, intent(in) :: n_ch, m_ch
        integer, intent(in) :: nkg
        integer, intent(in) :: nX
        real*8, intent(in) :: kappa, Ckappa
        type(cnt) :: currcnt

        integer :: dR = 1
        integer :: t1,t2
        real*8 :: cosTh, sinTh
        real*8, dimension(2,2) :: Rot
        integer :: i,j,k
        
        currcnt%n_ch = n_ch
        currcnt%m_ch = m_ch
        currcnt%nX = nX
        currcnt%kappa = kappa
        currcnt%Ckappa = Ckappa
        
        ! unit vectors and reciprocal lattice vectors.
        currcnt%a1=(/dsqrt(3.d0)/2.d0*a_l, 1.d0/2.d0*a_l/)
        currcnt%a2=(/dsqrt(3.d0)/2.d0*a_l, -1.d0/2.d0*a_l/)
        currcnt%b1=(/1.d0/dsqrt(3.d0)*2.d0*pi/a_l, +1.d0*2.d0*pi/a_l/)
        currcnt%b2=(/1.d0/dsqrt(3.d0)*2.d0*pi/a_l, -1.d0*2.d0*pi/a_l/)
        currcnt%aCC_vec=1.d0/3.d0*(currcnt%a1+currcnt%a2)
        
        ! calculate chirality and translational vectors of CNT unit cell.
        currcnt%ch_vec=dble(n_ch)*currcnt%a1+dble(m_ch)*currcnt%a2
        currcnt%len_ch=a_l*dsqrt(dble(n_ch)**2+dble(m_ch)**2+dble(n_ch)*dble(m_ch))
        currcnt%radius=currcnt%len_ch/2.d0/pi
  
        call gcd(dR,2*n_ch+m_ch,2*m_ch+n_ch)
  
        t1=(2*m_ch+n_ch)/dR
        t2=-(2*n_ch+m_ch)/dR
  
        currcnt%t_vec=dble(t1)*currcnt%a1+dble(t2)*currcnt%a2
  
        currcnt%Nu=2*(n_ch**2+m_ch**2+n_ch*m_ch)/dR
 
 
        ! rotate basis vectors so that ch_vec is along x-axis.
        cosTh=currcnt%ch_vec(1)/norm2(currcnt%ch_vec)
        sinTh=currcnt%ch_vec(2)/norm2(currcnt%ch_vec)
        Rot=reshape((/ cosTh, -sinTh , sinTh, cosTh /), (/2,2/))
        currcnt%ch_vec=matmul(Rot,currcnt%ch_vec)
        currcnt%t_vec=matmul(Rot,currcnt%t_vec)
        currcnt%a1=matmul(Rot,currcnt%a1)
        currcnt%a2=matmul(Rot,currcnt%a2)
        currcnt%b1=matmul(Rot,currcnt%b1)
        currcnt%b2=matmul(Rot,currcnt%b2)
        currcnt%aCC_vec=matmul(Rot,currcnt%aCC_vec)
  
        ! calculate reciprocal lattice of CNT.
        currcnt%dk=norm2(currcnt%b1)/(dble(nkg)-1.d0)
        currcnt%K1=(-t2*currcnt%b1+t1*currcnt%b2)/(dble(currcnt%Nu))
        currcnt%K2=(dble(m_ch)*currcnt%b1-dble(n_ch)*currcnt%b2)/dble(currcnt%Nu)
        currcnt%K2=currcnt%K2/norm2(currcnt%K2)
  
        ! calculate coordinates of atoms in the unwarped CNT unit cell.
        allocate(currcnt%posA(currcnt%Nu,2))
        allocate(currcnt%posB(currcnt%Nu,2))
    
        k=0
        do i=0,t1+n_ch
          do j=t2,m_ch
            if ((dble(t2)/dble(t1)*dble(i) .le. dble(j)) .and. (dble(m_ch)/dble(n_ch)*dble(i) .ge. dble(j)) .and. (dble(t2)/dble(t1)*dble(i-n_ch) .gt. dble(j-m_ch)) .and. (dble(m_ch)/dble(n_ch)*dble(i-t1) .lt. dble(j-t2))) then
              k=k+1
              currcnt%posA(k,1)=dble(i)*currcnt%a1(1)+dble(j)*currcnt%a2(1)
              currcnt%posA(k,2)=dble(i)*currcnt%a1(2)+dble(j)*currcnt%a2(2)
              currcnt%posB(k,1)=currcnt%posA(k,1)+currcnt%aCC_vec(1)
              currcnt%posB(k,2)=currcnt%posA(k,2)+currcnt%aCC_vec(2)
        
              if (currcnt%posA(k,1) .gt. currcnt%ch_vec(1)) currcnt%posA(k,1)=currcnt%posA(k,1)-currcnt%ch_vec(1)
              if (currcnt%posA(k,1) .lt. 0) currcnt%posA(k,1)=currcnt%posA(k,1)+currcnt%ch_vec(1)
              if (currcnt%posA(k,2) .gt. currcnt%t_vec(2)) currcnt%posA(k,2)=currcnt%posA(k,2)-currcnt%t_vec(2)
              if (currcnt%posA(k,2) .lt. 0) currcnt%posA(k,2)=currcnt%posA(k,2)+currcnt%t_vec(2)
          
              if (currcnt%posB(k,1) .gt. currcnt%ch_vec(1)) currcnt%posB(k,1)=currcnt%posB(k,1)-currcnt%ch_vec(1)
              if (currcnt%posB(k,1) .lt. 0) currcnt%posB(k,1)=currcnt%posB(k,1)+currcnt%ch_vec(1)
              if (currcnt%posB(k,2) .gt. currcnt%t_vec(2)) currcnt%posB(k,2)=currcnt%posB(k,2)-currcnt%t_vec(2)
              if (currcnt%posB(k,2) .lt. 0) currcnt%posB(k,2)=currcnt%posB(k,2)+currcnt%t_vec(2)
              
            endif
          enddo
        enddo

        allocate(currcnt%pos2d(2,currcnt%Nu,2))
        currcnt%pos2d(1,:,:) = currcnt%posA(:,:)
        currcnt%pos2d(2,:,:) = currcnt%posB(:,:)
    
        if (k .ne. currcnt%Nu) then
          write(*,*) "*** Error in calculating atom positions ***"
          call exit()
        endif
  
        ! calculate distances between atoms in a warped CNT unit cell.
        allocate(currcnt%posAA(currcnt%Nu,2))
        allocate(currcnt%posAB(currcnt%Nu,2))
        allocate(currcnt%posBA(currcnt%Nu,2))
        allocate(currcnt%posBB(currcnt%Nu,2))
  
        do i=1,currcnt%Nu
          currcnt%posAA(i,:)=currcnt%posA(i,:)-currcnt%posA(1,:)
          currcnt%posAB(i,:)=currcnt%posA(i,:)-currcnt%posB(1,:)
          currcnt%posBA(i,:)=currcnt%posB(i,:)-currcnt%posA(1,:)
          currcnt%posBB(i,:)=currcnt%posB(i,:)-currcnt%posB(1,:)
          if (currcnt%posAA(i,1) .gt. currcnt%ch_vec(1)/2.d0) currcnt%posAA(i,1)=currcnt%posAA(i,1)-currcnt%ch_vec(1)
          if (currcnt%posAB(i,1) .gt. currcnt%ch_vec(1)/2.d0) currcnt%posAB(i,1)=currcnt%posAB(i,1)-currcnt%ch_vec(1)
          if (currcnt%posBA(i,1) .gt. currcnt%ch_vec(1)/2.d0) currcnt%posBA(i,1)=currcnt%posBA(i,1)-currcnt%ch_vec(1)
          if (currcnt%posBB(i,1) .gt. currcnt%ch_vec(1)/2.d0) currcnt%posBB(i,1)=currcnt%posBB(i,1)-currcnt%ch_vec(1)
        end do
        
        ! calculate coordinates of atoms in 3D unit cell
        allocate(currcnt%posA3(currcnt%Nu,3))
        allocate(currcnt%posB3(currcnt%Nu,3))
        
        do i=1,currcnt%Nu
          currcnt%posA3(i,1) = currcnt%radius*sin(2*pi*currcnt%posA(i,1)/currcnt%len_ch)
          currcnt%posA3(i,2) = currcnt%posA(i,2)
          currcnt%posA3(i,3) = -currcnt%radius*cos(2*pi*currcnt%posA(i,1)/currcnt%len_ch)
        end do
        
        do i=1,currcnt%Nu
          currcnt%posB3(i,1) = currcnt%radius*sin(2*pi*currcnt%posB(i,1)/currcnt%len_ch)
          currcnt%posB3(i,2) = currcnt%posB(i,2)
          currcnt%posB3(i,3) = -currcnt%radius*cos(2*pi*currcnt%posB(i,1)/currcnt%len_ch)
        end do

        allocate(currcnt%pos3d(2,currcnt%Nu,3))
        currcnt%pos3d(1,:,:) = currcnt%posA3(:,:)
        currcnt%pos3d(2,:,:) = currcnt%posB3(:,:)
        
      end function init_cnt
    
    
      !**************************************************************************************************************************
      ! calculate band structure of the CNT
      !**************************************************************************************************************************
      
      subroutine calculateBands(currcnt, i_sub, E_th, Kcm_max)
        use physicalConstants
        type(cnt), intent(inout) :: currcnt
        integer, intent(in) :: i_sub
        real*8, intent(in) :: E_th, Kcm_max
        
        integer :: nkc, imin_sub
        integer :: i,j,mu,ik,tmpi
        integer, dimension(:), allocatable :: min_loc
        real*8 :: tmpr
        real*8, dimension(2) :: k,E1_tmp,E2_tmp
        real*8, dimension(:), allocatable :: k_vec,min_energy
        real*8, dimension(:,:,:), allocatable :: E_k
        complex*16, dimension(:,:,:), allocatable :: Cc_k,Cv_k
        complex*16, dimension(2) :: Cc_tmp,Cv_tmp
  
        ! set the value of i_sub
        currcnt%i_sub = i_sub
        
        ! calculate CNT energy dispersion.
        currcnt%ikc_max=floor(pi/norm2(currcnt%t_vec)/currcnt%dk)
        currcnt%ikc_min=-currcnt%ikc_max
        nkc=2*currcnt%ikc_max+1
        
        allocate(k_vec(currcnt%ikc_min:currcnt%ikc_max))
        allocate(E_k(1-currcnt%Nu/2:currcnt%Nu/2,currcnt%ikc_min:currcnt%ikc_max,2))
        allocate(Cc_k(1-currcnt%Nu/2:currcnt%Nu/2,currcnt%ikc_min:currcnt%ikc_max,2))
        allocate(Cv_k(1-currcnt%Nu/2:currcnt%Nu/2,currcnt%ikc_min:currcnt%ikc_max,2))
        allocate(min_loc(0:currcnt%Nu/2))
  
        do ik=currcnt%ikc_min,currcnt%ikc_max
          k_vec(ik)=dble(ik)*currcnt%dk
        end do
        
        do mu=1-currcnt%Nu/2,currcnt%Nu/2
          do ik=currcnt%ikc_min,currcnt%ikc_max
            k = dble(mu) * currcnt%K1 + dble(ik) * currcnt%dk * currcnt%K2
            call grapheneEnergy(currcnt, E_k(mu,ik,:), Cc_k(mu,ik,:), Cv_k(mu,ik,:), k)
          enddo
        enddo
        
        ! find the subbands with a minimum energy.
        min_loc=minloc(E_k(0:currcnt%Nu/2,:,1),2)
        imin_sub=count((min_loc .lt. nkc) .and. (min_loc .gt. 1))
        allocate(currcnt%min_sub(imin_sub))
        allocate(min_energy(imin_sub))
  
        ! store the value of mu for subbands with minimums in the variable min_sub
        i=1
        do mu=0,currcnt%Nu/2
          if ((min_loc(mu) .gt. 1) .and. (min_loc(mu) .lt. nkc)) then
            currcnt%min_sub(i)=mu
            min_energy(i)=minval(E_k(mu,:,1))
            i=i+1
          end if
        end do
  
        ! sort the subbands
        do i=imin_sub,2,-1
          do j=i-1,1,-1
            if (min_energy(i) .lt. min_energy(j)) then
              tmpr=min_energy(i)
              tmpi=currcnt%min_sub(i)
              min_energy(i)=min_energy(j)
              currcnt%min_sub(i)=currcnt%min_sub(j)
              min_energy(j)=tmpr
              currcnt%min_sub(j)=tmpi
            end if    
          end do
        end do
        ! find the max k-index that energy is below threshold energy (E_th).
        ik=0
        E1_tmp=(/ min_energy(currcnt%i_sub),0.d0 /)
        E2_tmp=(/ min_energy(currcnt%i_sub),0.d0 /)
        do while ((min(E1_tmp(1),E2_tmp(1))-min_energy(currcnt%i_sub)) .le. E_th )
          k=dble(currcnt%min_sub(currcnt%i_sub))*currcnt%K1+dble(ik)*currcnt%dk*currcnt%K2
          call grapheneEnergy(currcnt,E1_tmp,Cc_tmp,Cv_tmp,k)
          k=dble(currcnt%min_sub(currcnt%i_sub))*currcnt%K1-dble(ik)*currcnt%dk*currcnt%K2
          call grapheneEnergy(currcnt,E2_tmp(:),Cc_tmp,Cv_tmp,k)
          ik=ik+1
        end do
  
        ! set the index boundaries for some arrays and kernels.
        currcnt%ik_max=ik                              !the higher limit of k-vector that is below E_th
        currcnt%ik_min=-ik                             !the lower limit of k-vector that is below E_th
        currcnt%iKcm_max=floor(Kcm_max/currcnt%dk)        !the higher limit of center of mass wave vector that we calculate
        currcnt%iKcm_min = - currcnt%iKcm_max             !the lower limit of center of mass wave vector that we calculate
        currcnt%ikr_high=currcnt%iKcm_max-currcnt%ik_min     !the maximum index that the relative wavenumber in the entire simulation.
        currcnt%ikr_low=-currcnt%ikr_high                 !the minimum index that the relative wavenumber in the entire simulation.
        currcnt%ik_high=currcnt%ikr_high+currcnt%iKcm_max    !the maximum index that the wavenumber in the entire simulation.
        currcnt%ik_low=-currcnt%ik_high                   !the minimum index that the wavenumber in the entire simulation.
        currcnt%iq_max=2*currcnt%ikr_high                 !the higher limit of the index in v_FT and esp_q
        currcnt%iq_min=-currcnt%iq_max                    !the lower limit of the index in v_FT and esp_q
        
        ! calculate the tight-binding energies and coefficients.
        allocate(currcnt%Ek(2,currcnt%ik_low:currcnt%ik_high,2))
        allocate(currcnt%Cc(2,currcnt%ik_low:currcnt%ik_high,2))
        allocate(currcnt%Cv(2,currcnt%ik_low:currcnt%ik_high,2))
  
        do ik=currcnt%ik_low,currcnt%ik_high
          mu=currcnt%min_sub(i_sub) !first band
          k=dble(mu)*currcnt%K1+dble(ik)*currcnt%dk*currcnt%K2
          call grapheneEnergy(currcnt,currcnt%Ek(1,ik,:),currcnt%Cc(1,ik,:),currcnt%Cv(1,ik,:),k)

          mu=-currcnt%min_sub(i_sub) !second band
          k=dble(mu)*currcnt%K1+dble(ik)*currcnt%dk*currcnt%K2
          call grapheneEnergy(currcnt,currcnt%Ek(2,ik,:),currcnt%Cc(2,ik,:),currcnt%Cv(2,ik,:),k)
        enddo
      
      end subroutine calculateBands
    
      !**************************************************************************************************************************
      ! private subroutine to calculate Bloch functions and energy in graphene
      !**************************************************************************************************************************
      
      subroutine grapheneEnergy(currCNT,E,Cc,Cv,k)
        use physicalConstants, only: i1, t0
        type(cnt), intent(in) :: currCNT
        complex*16 :: f_k
        real*8, dimension(2), intent(in) :: k
        real*8, dimension(2), intent(out) :: E
        complex*16, dimension(2), intent(out) :: Cv
        complex*16, dimension(2), intent(out) :: Cc
  
        f_k=exp(i1*dcmplx(dot_product(k,(currCNT%a1+currCNT%a2)/3.d0)))+exp(i1*dcmplx(dot_product(k,(currCNT%a1-2.d0*currCNT%a2)/3.d0)))+exp(i1*dcmplx(dot_product(k,(currCNT%a2-2.d0*currCNT%a1)/3.d0)))
  
        E(1)=+t0*abs(f_k)
        E(2)=-t0*abs(f_k)
  
        Cc(1)=dcmplx(+1.d0/sqrt(2.d0))
        Cc(2)=dcmplx(+1.d0/sqrt(2.d0)/abs(f_k))*conjg(f_k)
        Cv(1)=dcmplx(+1.d0/sqrt(2.d0))
        Cv(2)=dcmplx(-1.d0/sqrt(2.d0)/abs(f_k))*conjg(f_k)
      end subroutine grapheneEnergy
end module cnt_class
