subroutine PROBINIT (init,name,namlen,problo,probhi)

  use bl_error_module
  use probdata_module
  use eos_module
  use meth_params_module, only: small_temp
  use prob_params_module, only : center
  use network, only : nspec
  implicit none 

  integer :: init,namlen,untin,i,k
  integer :: name(namlen)

  double precision :: center_x, center_y, center_z
  double precision :: problo(1), probhi(1)

  type (eos_t) :: eos_state

  namelist /fortin/ &
       rho_0, r_0, p_0, rho_ambient, smooth_delta, &
       center_x, center_y, center_z

!
!     Build "probin" filename -- the name of file containing fortin namelist.
!     
  integer, parameter :: maxlen = 127
  character :: probin*(maxlen)

  if (namlen .gt. maxlen) call bl_error("probin file name too long")

  do i = 1, namlen
     probin(i:i) = char(name(i))
  end do
         
! set namelist defaults

  rho_0 = 1.d9
  r_0 = 6.5d8
  p_0 = 1.d10
  rho_ambient = 1.d0
  smooth_delta = 1.d-5

!     Read namelists in probin file
  untin = 9
  open(untin,file=probin(1:namlen),form='formatted',status='old')
  read(untin,fortin)
  close(unit=untin)

  ! in 1-d spherical, the lower domain boundary should be the origin
  center(1) = 0.0d0

  xmin = problo(1)
  if (xmin /= 0.d0) call bl_error("ERROR: xmin should be 0!")


  xmax = probhi(1)

  ! set the composition to be uniform
  allocate(X_0(nspec))
  
  X_0(:) = 0.0
  X_0(1) = 1.0

  ! get the ambient temperature and sphere temperature, T_0

  eos_state % rho = rho_0
  eos_state % p   = p_0
  eos_state % xn  = x_0
  eos_state % T   = small_temp ! Initial guess for the EOS

  call eos(eos_input_rp, eos_state)

  T_0 = eos_state % T
  
  eos_state % rho = rho_ambient
  
  call eos(eos_input_rp, eos_state)

  T_ambient = eos_state % T

end subroutine PROBINIT


! ::: -----------------------------------------------------------
! ::: This routine is called at problem setup time and is used
! ::: to initialize data on each grid.  
! ::: 
! ::: NOTE:  all arrays have one cell of ghost zones surrounding
! :::        the grid interior.  Values in these cells need not
! :::        be set here.
! ::: 
! ::: INPUTS/OUTPUTS:
! ::: 
! ::: level     => amr level of grid
! ::: time      => time at which to init data             
! ::: lo,hi     => index limits of grid interior (cell centered)
! ::: nstate    => number of state components.  You should know
! :::		   this already!
! ::: state     <=  Scalar array
! ::: delta     => cell size
! ::: xlo,xhi   => physical locations of lower left and upper
! :::              right hand corner of grid.  (does not include
! :::		   ghost region).
! ::: -----------------------------------------------------------
subroutine ca_initdata(level,time,lo,hi,nscal, &
                       state,state_l1,state_h1,delta,xlo,xhi)

  use probdata_module
  use eos_module
  use network, only : nspec
  use interpolate_module
  use meth_params_module, only : NVAR, URHO, UMX, UMY, UMZ, UTEMP, UEDEN, UEINT, UFS, small_temp
  use prob_params_module, only : center

  implicit none
  
  integer          :: level, nscal
  integer          :: lo(1), hi(1)
  integer          :: state_l1,state_h1
  double precision :: state(state_l1:state_h1,NVAR)
  double precision :: time, delta(1)
  double precision :: xlo(1), xhi(1)
  
  double precision :: xl,xx,dist,pres,eint,temp,avg_rho, rho_n
  double precision :: dx_sub
  integer          :: i,ii,n

  type (eos_t) :: eos_state

  integer, parameter :: nsub = 5

  dx_sub = delta(1)/dble(nsub)
  
  do i = lo(1), hi(1)
     xl = dble(i) * delta(1)
      
     avg_rho = 0.d0

     do ii = 0, nsub-1

        xx = xl + (dble(ii) + 0.5d0) * dx_sub
        
        dist = (xx-center(1))
        
        ! use a tanh profile to smooth the transition between rho_0                                    
        ! and rho_ambient                                                                              
        rho_n = rho_0 - (rho_0 - rho_ambient)* &
             0.5d0 * (1.d0 + tanh((dist - r_0)/smooth_delta))
                
        avg_rho = avg_rho + rho_n
        
     enddo

     state(i,URHO) = avg_rho/dble(nsub)

     eos_state % rho = state(i,URHO)
     eos_state % p   = p_0
     eos_state % T   = small_temp ! Initial guess for the EOS
     eos_state % xn  = X_0

     call eos(eos_input_rp, eos_state)

     temp = eos_state % T
     eint = eos_state % e
     
     state(i,UTEMP) = temp
     state(i,UMX) = 0.d0
     state(i,UEDEN) = state(i,URHO) * eint
     state(i,UEINT) = state(i,URHO) * eint
     state(i,UFS:UFS+nspec-1) = state(i,URHO) * X_0(1:nspec)

  enddo
    
end subroutine ca_initdata

