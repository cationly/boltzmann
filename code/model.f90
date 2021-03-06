module model
  implicit none
  
  private calcaverdens, calcavervel, equil, applybc
  public timestep, init

contains

  subroutine timestep(Lx, Ly, Nvel, dens, tau)
    integer,intent(in) :: Lx, Ly, Nvel
    real(8),intent(in) :: tau
    real(8),intent(inout) :: dens(Lx, Ly, Nvel)

    real(8) :: eqdens(Lx, Ly, Nvel), deltaP

    deltaP = 0.0001d0

    dens = applybc(Lx, Ly, Nvel, dens)

    dens(:, :, 2) = dens(:, :, 2) + deltaP
    dens(:, :, 5) = dens(:, :, 5) - deltaP

    eqdens = equil(Lx, Ly, Nvel, dens)
    dens = (1 - 1 / tau) * dens + eqdens / tau
  end subroutine
  
  function init(Lx, Ly, Nvel) result(eqdens)
    integer,intent(in) :: Lx, Ly, Nvel

    integer :: k
    real(8) :: averdens = 1d0, eqdens(Lx, Ly, Nvel)

    eqdens(:, :, 1) = 4 / 9d0 * averdens

    do k = 2, Nvel
      if (modulo(k,2)==0) then
        eqdens(:, :, k) = averdens / 9d0
      else if (modulo(k,2)==1) then
        eqdens(:, :, k) = averdens / 36d0
      end if
    end do
  end function

  function equil(Lx, Ly, Nvel, dens) result(eqdens)
    integer,intent(in) :: Lx, Ly, Nvel
    real(8),intent(in) :: dens(Lx, Ly, Nvel)

    integer :: k, velx(Nvel), vely(Nvel)
    real(8) :: avervel(Lx, Ly, 2), averdens(Lx, Ly), eqdens(Lx, Ly, Nvel)
    real(8) :: sqvel(Lx, Ly), normvel(Lx, Ly)

    velx = [0,1,1,0,-1,-1,-1,0,1]
    vely = [0,0,1,1,1,0,-1,-1,-1]
    avervel = calcavervel(Lx, Ly, Nvel, dens) 
    averdens = calcaverdens(Lx, Ly, Nvel, dens)   

    sqvel = avervel(:, :, 1)**2 + avervel(:, :, 2)**2
    eqdens(:, :, 1) = 4 / 9d0 * averdens * (1 - 1.5d0 * sqvel)

    do k = 2, Nvel
      normvel = avervel(:, :, 1) * velx(k) + avervel(:, :, 2) * vely(k)
      if (modulo(k,2)==0) then
        eqdens(:, :, k) = averdens / 9d0 * &
              (1 + 3 * normvel + 4.5d0 * normvel**2 - 1.5d0 * sqvel)
      else if (modulo(k,2)==1) then
        eqdens(:, :, k) = averdens / 36d0 * &
              (1 + 3 * normvel + 4.5d0 * normvel**2 - 1.5d0 * sqvel)
      end if
    end do
  end function

  function calcaverdens(Lx, Ly, Nvel, dens) result(averdens)
    integer,intent(in) :: Lx, Ly, Nvel
    real(8),intent(in) :: dens(Lx, Ly, Nvel)

    integer :: i, j
    real(8) :: averdens(Lx, Ly)

    do i = 1, Lx
      do j = 1, Ly
        averdens(i, j) = sum(dens(i, j, :)) / (Nvel * 1d0)
      end do
    end do
  end function

  function calcavervel(Lx, Ly, Nvel, dens) result(avervel)
    integer,intent(in) :: Lx, Ly, Nvel
    real(8),intent(in) :: dens(Lx, Ly, Nvel)

    integer :: i, j, velx(Nvel), vely(Nvel)
    real(8) :: averdens(Lx, Ly), avervel(Lx, Ly, 2)

    velx = [0,1,1,0,-1,-1,-1,0,1]
    vely = [0,0,1,1,1,0,-1,-1,-1]
    do i = 1, Lx
      do j = 1, Ly
        avervel(i, j, 1) = sum(velx * dens(i, j, :))
        avervel(i, j, 2) = sum(vely * dens(i, j, :))
      end do
    end do
    
    averdens = calcaverdens(Lx, Ly, Nvel, dens)
    avervel(:, :, 1) = avervel(:, :, 1) / averdens
    avervel(:, :, 2) = avervel(:, :, 2) / averdens
  end function

  function applybc(Lx, Ly, Nvel, dens) result(newdens)
    integer,intent(in) :: Lx, Ly, Nvel
    real(8),intent(in) :: dens(Lx, Ly, Nvel)

    integer :: i
    real(8) :: newdens(Lx, Ly, Nvel)

    newdens = dens

    do i = 1, Lx
      newdens(i, 1, 4) = dens(i, 1, 8)
      newdens(i, 1, 5) = dens(modulo(i + 1, Lx), 1, 9)
      newdens(i, 1, 3) = dens(modulo(i - 1, Lx), 1, 7)
      newdens(i, Ly, 8) = dens(1, Lx, 4)
      newdens(i, Ly, 9) = dens(modulo(i - 1, Lx), Lx, 5)
      newdens(i, Ly, 7) = dens(modulo(i + 1, Lx), Lx, 3)
    end do
    newdens(1, :, :) = dens(Lx, :, :)
  end function
end module
